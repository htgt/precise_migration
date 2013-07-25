package HTGT::Utils::UploadQCResults::PIQ;

use Moose;
use namespace::autoclean;
use HTGT::Constants qw( %QC_RESULT_TYPES %RANKED_QC_RESULTS );
use CSV::Reader;
use Try::Tiny;
use Const::Fast;
use Scalar::Util qw(looks_like_number);

with 'HTGT::Utils::UpdateWellDataQc';

has piq_child_wells => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        clear_piq_child_well   => 'clear',
        number_piq_child_wells => 'count',
        add_piq_child_well     => 'push',
        get_piq_child_well     => 'pop',
    }
);

const my @PIQ_GROUPED_RESULTS => qw(
    loa
    loxp
    lacz
    chr1
    chr8a
    chr8b
    chr11a
    chr11b
    chry
    lrpcr
);

const my %GROUPED_QC_FIELDS => (
    cn         => { required => 1, validation_method => '_validate_numeric_value' },
    min_cn     => { required => 1, validation_method => '_validate_numeric_value' },
    max_cn     => { required => 1, validation_method => '_validate_numeric_value' },
    confidence => { required => 0, validation_method => '_validate_confidence_value' },
    pass       => { required => 1, validation_method => '_validate_result_value' },
);

const my %PIQ_OVERALL_RESULTS => (
    chromosome_fail => { required => 0, validation_method => '_validate_chromosome_fail' },
    targeting_pass  => { required => 0, validation_method => '_validate_result_value' },
);

sub _build_valid_plate_types {
    my $self = shift;

    return [ 'PIQ' ];
}

sub _build_csv_reader {
    my $self = shift;

    my $csv_reader = CSV::Reader->new( 
        input      => $self->cleaned_input,
        use_header => 1,
    ) or die( "Unable to construct CSV::Reader object" );

    return $csv_reader;
}

sub parse_csv {
    my $self = shift;

    try {
        while ( my $line_data = $self->csv_reader->read ) {
            # copy to new hash with lowercase keys
            my %data = map{ lc($_) => $line_data->{$_} } keys %{ $line_data }; 
            $self->_parse_line( \%data );
        }
    }
    catch{
        $self->add_error("Parse error, line " . $self->line_number . " of input: $_" );
    };

}

sub _parse_line {
    my ( $self, $data ) = @_;
    $self->inc_line_number;
    my %well_qc_results;

    my $well_name = $data->{epd_clone_name}; 
    unless ( $well_name ) {
        $self->add_error("No epd_clone_name specified for line: " . $self->line_number );
        return;
    }

    for my $qc_group_type ( @PIQ_GROUPED_RESULTS ) {
        # if there is no pass value for a qc unit ignore all its fields
        my $pass_field = $qc_group_type . '_pass';
        my $pass_value = $self->_get_qc_result( $pass_field, $data );
        next unless defined($pass_value); 

        # na value is a special case, ignore all other fields in result
        if ( $pass_value =~ /^na$/i ) {
            $self->_parse_field( $data, $GROUPED_QC_FIELDS{'pass'}, $pass_field, \%well_qc_results );
            next;
        }

        for my $field_type ( keys %GROUPED_QC_FIELDS ) {
            my $field = $qc_group_type . '_' . $field_type;
            $self->_parse_field( $data, $GROUPED_QC_FIELDS{$field_type}, $field, \%well_qc_results );
        }
    }

    for my $field_name ( keys %PIQ_OVERALL_RESULTS ) {
        $self->_parse_field( $data, $PIQ_OVERALL_RESULTS{$field_name}, $field_name, \%well_qc_results );
    }

    $self->add_well_qc_results( $well_name => \%well_qc_results ) if %well_qc_results;
}

sub _parse_field {
    my ( $self, $data, $field_spec, $field_name, $well_qc_results ) = @_;

    my $qc_result = $self->_get_qc_result( $field_name, $data );
    if ( defined($qc_result) ) {
        my $validation_method = $field_spec->{validation_method};

        if ( $self->$validation_method( $qc_result ) ) {
            $well_qc_results->{$field_name} = $qc_result;
        }
        else {
            $self->add_error("Invalid $field_name ($qc_result) for: " . $data->{epd_clone_name} );
        }
    }
    elsif ( $field_spec->{required} && !$self->override ) {
        $self->add_error("No $field_name qc result given for well: " . $data->{epd_clone_name} );
    }
}

sub _validate_result_value {
    my ( $self, $result ) = @_;

    return exists $RANKED_QC_RESULTS{lc($result)} ? 1 : 0;
}

sub _validate_numeric_value {
    my ( $self, $result ) = @_;

    return looks_like_number( $result ) ? 1 : 0;
}

sub _validate_chromosome_fail {
    my ( $self, $result ) = @_;

    if ( $self->_validate_numeric_value( $result ) ) {
        return 1 if $result >= 0 && $result <= 4;
    }
    elsif ( lc($result) eq 'y' ) {
        return 1;
    }

    return;
}

sub _validate_confidence_value {
    my ( $self, $result ) = @_;

    $result =~ s/(<|>)\s*//;
    return unless $self->_validate_numeric_value($result);
    return $result <= 1 ? 1 : 0;
}

sub update_qc_results {
    my ( $self ) = @_;

    return if $self->no_qc_results;
    return if $self->has_errors;

    foreach my $well_name ( keys %{ $self->qc_results } ) {
        my $well = $self->_get_piq_well( $well_name );
        next unless $well; 

        $self->_update_qc_result( $well, $self->qc_results->{$well_name} );
    }
}

sub _update_qc_result {
    my ( $self, $well, $qc_results ) = @_;

    if ( my $targeting_pass_value = $self->_get_qc_result( 'targeting_pass', $qc_results ) ) {
        return if !$self->_update_current_targeting_pass_level( $well, $targeting_pass_value );
    }

    my $chromosome_fail_result = $self->_get_qc_result( 'chromosome_fail', $qc_results );
    if ( defined($chromosome_fail_result) ) {
        if ( my $well_data = $self->_current_well_qc_result( $well, 'chromosome_fail' ) ) {
            $self->_update_well_data( $well_data, $chromosome_fail_result )
        }
        else {
            $self->_create_well_data( $well, 'chromosome_fail', $chromosome_fail_result );
        }
    }

    for my $qc_group_type ( @PIQ_GROUPED_RESULTS ) {
       next unless $qc_results->{$qc_group_type . '_pass'}; 

       $self->_process_qc_result_unit( $well, $qc_results, $qc_group_type );
    }
    return 1;
}

sub _update_current_targeting_pass_level {
    my ( $self, $well, $new_targeting_pass_value ) = @_;

    my $current_targeting_pass;
    unless ( $current_targeting_pass = $self->_current_well_qc_result( $well, 'targeting_pass' ) ) {
        # no current targeting_pass, carry on updating all other values
        $self->_create_well_data( $well, 'targeting_pass', $new_targeting_pass_value );
        return 1;
    }

    if ( $RANKED_QC_RESULTS{ lc( $current_targeting_pass->data_value ) }
        < $RANKED_QC_RESULTS{ lc($new_targeting_pass_value) } && !$self->override )
    {
        $self->add_log( 'Not updating ' . $well->well_name . ' currently stored result targeting pass'
                . $current_targeting_pass->data_value . ' is better than the new result '
                . $new_targeting_pass_value );
        return;
    }
    else {
        $self->_update_well_data( $current_targeting_pass, $new_targeting_pass_value );
    }
    return 1;
}

sub _process_qc_result_unit {
    my ( $self, $well, $qc_results, $qc_group_type ) = @_;

    my $overall_pass_field = $qc_group_type . '_pass';
    my $overall_pass_result = $self->_get_qc_result( $overall_pass_field, $qc_results );
    if ( my $well_data = $self->_current_well_qc_result( $well, $overall_pass_field ) ) {
        return unless $self->_update_ranked_qc_result( $well_data, $overall_pass_result );
    }
    else {
        $self->_create_well_data( $well, $overall_pass_field, $overall_pass_result );
    }

    for my $field_type ( grep{ $_ ne 'pass' } keys %GROUPED_QC_FIELDS ) {
        my $field = $qc_group_type . '_' . $field_type;
        next unless defined $qc_results->{$field};

        if ( my $well_data = $self->_current_well_qc_result( $well, $field ) ) {
            $self->_update_well_data( $well_data, $qc_results->{$field} );
        }
        else {
            $self->_create_well_data( $well, $field, $qc_results->{$field} );
        }
    }
    return 1;
}

sub _get_qc_result {
    my ( $self, $field, $data ) = @_;

    if ( exists $data->{$field} &&  defined($data->{$field}) && length($data->{$field})  ){
        return $data->{$field};
    }
    return undef;
}

sub _get_piq_well {
    my ( $self, $well_name ) = @_;

    $self->clear_piq_child_well;
    my ( $well_number, $plate_name );
    if ( $well_name =~ /^(.*)_(\w\d\d)$/ ) {
        $well_number = $2;
        $plate_name = $1;
    }
    else {
        $self->add_error("Invalid EPD well name $well_name");
        return;
    }

    my $epd_well = $self->schema->resultset('Well')->find(
        {
            well_name    => $well_name,
            'plate.name' => $plate_name,
            'plate.type' => 'EPD',
        }, 
        {
            join => 'plate'
        }
    );

    unless ( $epd_well ) {
        $self->add_error("Unable to find EPD well $well_name");
        return;
    }

    $self->_find_piq_child_well( $epd_well );
    if ( $self->number_piq_child_wells == 1 ) {
        return $self->get_piq_child_well;
    }
    elsif ( $self->number_piq_child_wells > 1 ) {
        my $piq_well_names = join(',', map{ $_->well_name } @{ $self->piq_child_wells } );
        $self->add_error("Multiple PIQ child wells found for $well_name: $piq_well_names");
        return;
    }
    else {
        $self->add_error("Found no PIQ child wells linked to epd well $well_name");
        return;
    }
}

sub _find_piq_child_well {
    my ( $self, $well ) = @_;

    my @child_wells = $well->child_wells;
    for my $child_well ( @child_wells ) {
        if ( $child_well->plate->type eq 'PIQ' ) {
            $self->add_piq_child_well( $child_well );
        }
        else {
            $self->_find_piq_child_well( $child_well );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
