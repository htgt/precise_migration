package HTGT::Utils::Plate::PlateDataParser;

use Moose;
use namespace::autoclean;
with 'MooseX::Log::Log4perl';

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has errors => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    traits  => [ 'Hash' ],
    handles => {
        clear_errors => 'clear',
        has_errors   => 'count'
    }
);

has line_num => (
    is      => 'ro',
    isa     => 'Num',
    traits  => [ 'Counter' ],
    default => 0,
    handles => {
        inc_line_num   => 'inc',
        reset_line_num => 'reset'
    }
);

has plate_data => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => {
        add_plate_data => 'push',
        get_plate_data => 'shift',
        clear_data => 'clear'
    }
);

has _seen_plates => (
    isa     => 'HashRef',
    traits  => [ 'Hash'],
    default => sub { {} },
    handles => {
        _mark_plate_seen => 'set',
        is_plate_seen   => 'exists',
        clear_seen      => 'clear'
    }
);

sub mark_plate_seen {
    my ( $self, $plate ) = @_;

    $self->_mark_plate_seen( $plate, 1 );
}

sub add_error {
    my ( $self, $error_msg ) = @_;

    push @{ $self->errors->{ $self->line_num } }, $error_msg;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
