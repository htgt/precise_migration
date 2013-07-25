package HTGT::Utils::UpdateWellDataQc;

use Moose::Role;
use namespace::autoclean;
use HTGT::Constants qw( %RANKED_QC_RESULTS );
use List::MoreUtils qw( any );
use Try::Tiny;

with 'HTGT::Utils::UploadQCResults';
requires '_build_valid_plate_types';

has valid_plate_types => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

has valid_plates => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        add_valid_plate => 'set',
        plate_is_valid  => 'exists',
    }
);

has qc_results => (
    is         => 'ro',
    isa        => 'HashRef',
    traits     => ['Hash'],
    default    => sub { {} },
    handles    => {
        no_qc_results       => 'is_empty',
        add_well_qc_results => 'set',
    },
);

has override => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub _current_well_qc_result {
    my ( $self, $well, $well_data_type ) = @_;

    my $well_data = $well->well_data->find( { data_type => $well_data_type } );
    return $well_data if $well_data;
    return;
}

sub _create_well_data {
    my ( $self, $well, $well_data_type, $qc_result ) = @_;

    my $new_well_data = $well->well_data->create(
        {   
            data_type  => $well_data_type,
            data_value => $qc_result,
            edit_user  => $self->user,
        }
    );

    if ($new_well_data) {
        $self->add_log( 'Created ' . $well_data_type . ' for ' . $well->well_name . ': ' . $qc_result );
    }
    else {
        $self->add_error( 'Error creating ' . $well_data_type . ' for ' . $well->well_name );
    }
}

sub _update_well_data {
    my ( $self, $well_data, $new_qc_result ) = @_;

    try {
        my $old_result = $well_data->data_value;
        $well_data->update( { data_value => $new_qc_result, edit_user  => $self->user } );
    
        $self->add_log( 'Updating ' . $well_data->data_type . ' for ' 
                        . $well_data->well->well_name .  ' from ' .  $old_result
                        . " to $new_qc_result" );
    }
    catch {
        $self->add_error( 'Error updating ' . $well_data->data_type . ' for ' 
                          . $well_data->well->well_name );
    };
}

sub _get_well {
    my ( $self, $well_name ) = @_;

    $well_name =~ /^(.*)_(\w\d\d)$/;
    my $well_number = $2;
    my $plate_name = $1;
    my $well = $self->schema->resultset('Well')->find( 
        { 
            well_name    => $well_name,
            'plate.name' =>  $plate_name,
        }, { join => 'plate' }
    );

    unless ($well) {
        $well = $self->schema->resultset('Well')->find( 
            { 
                well_name    => $well_number,
                'plate.name' =>  $plate_name,
            }, { join => 'plate' }
        );
    }

    unless ($well) {
        $self->add_error("well: $well_name does not exist");
        return;
    }
    
    unless ( $self->_is_well_valid($well) ) {
        $self->add_error("well: $well_name does not belong to plate type: " 
            . join(' ', @{ $self->valid_plate_types }) );
        return;
    }

    return $well;
}

sub _is_well_valid {
    my ( $self, $well ) = @_;

    my $plate = $well->plate;
    return 1 if $self->plate_is_valid( $plate->plate_id );

    if ( any { $_ eq $plate->type  } @{ $self->valid_plate_types } ) {
        $self->add_valid_plate( $plate->plate_id => 1 );
        return 1;
    }
    return;
}

sub _update_ranked_qc_result {
    my ( $self, $well_data, $new_result ) = @_;
    my $old_result = $well_data->data_value;

    if ( lc($old_result) eq lc($new_result) ) {
        $self->add_log( $well_data->well->well_name 
                        . ' already has the same ' . $well_data->data_type 
                        .  ' (' . $old_result . ') - NOT updating');
        return;
    }
    elsif ( $RANKED_QC_RESULTS{lc($old_result)} < $RANKED_QC_RESULTS{lc($new_result)} and !$self->override ) {
        $self->add_log( $well_data->well->well_name 
                        . ' already has a better ' . $well_data->data_type 
                        .  ' (' . $old_result . ') - NOT updating to ' . $new_result );
        return;
    }

    $self->_update_well_data( $well_data, $new_result );
    return 1;
}

1;

__END__
