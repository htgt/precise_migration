package HTGT::Utils::SouthernBlot::FragmentSizeFilter;

use Moose::Role;
use namespace::autoclean;

requires 'max_fragment_size';

sub check_fragment_size {
    my ( $self, $fragment_size ) = @_;

    $fragment_size <= $self->max_fragment_size;
}

1;

__END__
