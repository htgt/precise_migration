package HTGT::Utils::Plate::LoadPlateData;

use Moose;
use namespace::autoclean;

has errors => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => ['Hash'],
    handles => {
        clear_errors => 'clear',
        has_errors   => 'count'
    }
);

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has parser => (
    is       => 'ro',
    isa      => 'HTGT::Utils::Plate::PlateDataParser',
    required => 1,
);

has update_log => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => { clear_log => 'clear' }
);

sub add_error {
    my ( $self, $plate_name, $error_msg ) = @_;

    push @{ $self->errors->{$plate_name} }, $error_msg;
}

sub add_log {
    my ( $self, $plate_name, $log_message ) = @_;

    push @{ $self->update_log->{$plate_name} }, $log_message;
}

sub load_data {
    my ($self) = @_;
    my %seen;

    while ( my $plate_update_data = $self->parser->get_plate_data ) {
        my $plate = delete $plate_update_data->{'plate'}
            or confess "no plate";
        foreach my $data_type ( sort keys %{$plate_update_data} ) {
            $self->_check_plate_data( $plate, $plate_update_data, $data_type )
                or next;
            $self->_create_plate_data( $plate, $plate_update_data,
                $data_type );
        }
    }
}

=head2 _check_plate_data

Check plate data type does not already exist, if not create the data type
if it does exist check data value is the same,if not raise an error

=cut

sub _check_plate_data {
    my ( $self, $plate, $plate_update_data, $data_type ) = @_;

    my $current_plate_data
        = $plate->plate_data_rs->find( { 'data_type' => $data_type } );

    if ($current_plate_data) {
        my $current_data_value = $current_plate_data->data_value;
        my $new_data_value     = $plate_update_data->{$data_type};
        if ( $current_data_value ne $new_data_value ) {
            $self->add_error( $plate->name,
                      "$data_type mismatch,"
                    . $new_data_value
                    . " / $current_data_value (new/old)" );
            return;
        }
        else {
            $self->add_log( $plate->name,
                "data already present $data_type = "
                    . $plate_update_data->{$data_type} );
            return;
        }
    }

    return 1;
}

=head2 _create_plate_data

Inserts archive data into plate_data table

=cut

sub _create_plate_data {
    my ( $self, $plate, $plate_update_data, $data_type ) = @_;

    my $plate_data = $plate->plate_data_rs->create(
        {   'data_type'  => $data_type,
            'data_value' => $plate_update_data->{$data_type},
            'edit_user'  => $self->user,
            'edit_date'  => \'current_timestamp'
        }
    );

    if ($plate_data) {
        $self->add_log( $plate->name,
            "inserted $data_type = " . $plate_update_data->{$data_type} );
    }
    else {
        $self->add_error( $plate->name,
            "failed to insert $data_type = "
                . $plate_update_data->{$data_type} );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
