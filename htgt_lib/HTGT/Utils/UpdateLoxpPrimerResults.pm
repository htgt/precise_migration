package HTGT::Utils::UpdateLoxpPrimerResults;

use Moose;
use namespace::autoclean;
use Const::Fast;
with 'MooseX::Log::Log4perl';

my $PRIMER_NAME_REGEX    = qr/^(PNFLR|LF|LR)[1-3]$/;
const my $PRIMER_RESULT_PREFIX => 'SRLOXP-';

const my %VALID_RESULTS => (
    pass     => '',
    fail     => '',
    not_used => '',
);

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
);

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has epd_well_primer => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has primer_name => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_primer_name {
    my $self = shift;

    my $primer_name = ( split /-/, $self->epd_well_primer )[1];
    die("Primer name not specified") unless $primer_name;

    unless ( $primer_name =~ /$PRIMER_NAME_REGEX/ ) {
        die( "Invalid primer name: " . $primer_name );
    }
    return $primer_name;
}

has epd_well => (
    is         => 'ro',
    isa        => 'HTGTDB::Well',
    required   => 1,
    lazy_build => 1,
);

sub _build_epd_well {
    my $self = shift;

    my $well_name = ( split /-/, $self->epd_well_primer )[0];

    my $well = $self->schema->resultset('Well')->find( { well_name => $well_name } );
    die( 'Well does not exist: ' . $well_name ) unless $well;

    my $plate = $well->plate;
    unless ( $plate->type eq 'EPD' ) {
        die(      "Well ($well_name) does not belong to a EPD plate "
                . $plate->name . ' : '
                . $plate->type );
    }

    return $well;
}

has result => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => \&_check_result,
);

has well_data => (
    is         => 'ro',
    isa        => 'Maybe[HTGTDB::WellData]',
    lazy_build => 1,
);

sub _build_well_data {
    my $self = shift;

    my $primer_result_name = $PRIMER_RESULT_PREFIX . $self->primer_name;
    my $well_data = $self->epd_well->well_data->find( { 'data_type' => $primer_result_name } );
    return unless $well_data;

    return $well_data;
}

has current_result => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_current_result {
    my $self = shift;

    return 'not_used' unless $self->well_data;

    my $result = $self->well_data->data_value;
    $self->_check_result($result);

    return $result;
}

has update_log => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_update',
    writer    => 'add_log',

);

sub BUILD {
    my $self = shift;

    #check for existance of this primer for this design
    my $design_instance = $self->epd_well->design_instance;
    next unless $design_instance;
    my $design = $design_instance->design;

    my $primer_feature
        = $design->features->find( { 'feature_type.description' => $self->primer_name },
        { join => 'feature_type' } );

    unless ($primer_feature) {
        die(      '('
                . $self->epd_well->well_name
                . ') Could not find relevant primer '
                . $self->primer_name
                . ' for the design '
                . $design->design_id );
        return;
    }
}

sub update {
    my $self = shift;
    return 1 if $self->result eq $self->current_result;

    if ( $self->current_result eq 'not_used' ) {
        $self->_create_new_primer_result;
    }
    elsif ( $self->result eq 'not_used' ) {
        $self->_delete_primer_result;
    }
    else {
        $self->_modify_primer_result;
    }
    return 1;
}

sub _create_new_primer_result {
    my $self = shift;

    my $new_well_data = $self->epd_well->well_data->create(
        {   data_type  => $PRIMER_RESULT_PREFIX . $self->primer_name,
            data_value => $self->result,
            edit_user  => $self->user,
        }
    );

    if ($new_well_data) {
        $self->add_log( '('
                . $self->epd_well->well_name
                . ') Created primer result for '
                . $self->primer_name . ' to '
                . $self->result );
    }
    else {
        die(      '('
                . $self->epd_well->well_name
                . ') Unable to create primer result for '
                . $self->primer_name . ' to '
                . $self->result );
    }
}

sub _delete_primer_result {
    my $self = shift;

    my $delete = $self->well_data->delete;

    if ($delete) {
        $self->add_log( '('
                . $self->epd_well->well_name
                . ') Set primer result to not used for '
                . $self->primer_name );
    }
    else {
        die(      '('
                . $self->epd_well->well_name
                . ') Unable to set primer result to not used '
                . $self->primer_name );
    }
}

sub _modify_primer_result {
    my $self = shift;

    my $changed_well_data = $self->well_data->update(
        {   data_value => $self->result,
            edit_user  => $self->user,
        }
    );

    if ($changed_well_data) {
        $self->add_log( '('
                . $self->epd_well->well_name
                . ') Updated primer result for '
                . $self->primer_name . ' to '
                . $self->result
                . ' from '
                . $self->current_result );
    }
    else {
        die(      '('
                . $self->epd_well->well_name
                . ') Unable to update primer result for '
                . $self->primer_name . ' to '
                . $self->result );
    }
}

sub _check_result {
    my ( $self, $result ) = @_;

    unless ( exists $VALID_RESULTS{$result} ) {
        die(      '('
                . $self->epd_well->well_name
                . ') Result for '
                . $self->primer_name
                . ' is invalid: '
                . $result );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
