package HTGT::Utils::UploadQCResults::Simple;

use Moose;
use namespace::autoclean;
use HTGT::Constants qw( %QC_RESULT_TYPES %RANKED_QC_RESULTS );
use CSV::Reader;
use Try::Tiny;

with 'HTGT::Utils::UpdateWellDataQc';

has skip_header => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has qc_result_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => \&_qc_result_type_check,
);

sub _qc_result_type_check {
    my ( $self, $qc_result_type ) = @_;

    unless ( exists $QC_RESULT_TYPES{ $qc_result_type } ) {
        die( "Unrecognised qc result type: " . $self->qc_result_type );
    }
}

has well_data_type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_well_data_type {
    my $self = shift;
    my $well_data_type;

    if ( $well_data_type = $QC_RESULT_TYPES{ $self->qc_result_type }{well_data_type} ) {
        return $well_data_type;
    }
    else {
        die( "QC well data type for " . $self->qc_result_type . " has not been set" );
    }

}

sub _build_valid_plate_types {
    my $self = shift;

    if ( my $valid_plate_types = $QC_RESULT_TYPES{ $self->qc_result_type }{valid_plate_types} ) {
        $self->log->debug( "Adding valid plate type: ". join('-', @{ $valid_plate_types } ) );
        return $valid_plate_types
    }
    else {
        die( "Valid plate types for: " . $self->qc_result_type . " has not been set" );
    }
}

sub _build_csv_reader {
    my $self = shift;

    my $csv_reader = CSV::Reader->new( 
        input       => $self->cleaned_input,
        skip_header => $self->skip_header, 
    );

    die( "Unable to construct CSV::Reader object" ) unless $csv_reader;
    return $csv_reader;
}

sub parse_csv {
    my $self = shift;

    try {
        while ( my $line_data = $self->csv_reader->read ) {
            $self->_parse_line( $line_data );
        }
    }
    catch{
        $self->add_error("Parse error, line " . $self->line_number . " of input: $_" );
    };
}

sub _parse_line {
    my ( $self, $line_data ) = @_;

    $self->inc_line_number;
    my ( $well_name, $qc_result ) = @{ $line_data };

    return unless $well_name;
    if ($qc_result) {
        $qc_result =~ s/\s+$//;
        unless ( exists $RANKED_QC_RESULTS{lc($qc_result)} ) {
            $self->add_error("Invalid QC result ($qc_result) for $well_name");
        }
        $self->add_well_qc_results( $well_name => { $self->well_data_type => $qc_result } );
    }
    else {
        $self->add_error("No qc result given for $well_name");
    }
}

sub update_qc_results {
    my ( $self ) = @_;

    return if $self->no_qc_results;
    return if $self->has_errors;

    foreach my $well_name ( keys %{ $self->qc_results } ) {
        my $well = $self->_get_well($well_name);
        next unless $well; 

        my $qc_result = $self->qc_results->{$well_name}{$self->well_data_type};
        if ( my $well_data = $self->_current_well_qc_result( $well, $self->well_data_type ) ) {
            $self->_update_ranked_qc_result( $well_data, $qc_result );
        }
        else {
            $self->_create_well_data( $well, $self->well_data_type, $qc_result );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
