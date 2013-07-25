package HTGT::Utils::SouthernBlot::NullFragmentSizeFilter;

use Moose::Role;
use namespace::autoclean;

sub check_fragment_size {
    my ( $self, $fragment_size ) = @_;

    return 1;    
}

1;

__END__
