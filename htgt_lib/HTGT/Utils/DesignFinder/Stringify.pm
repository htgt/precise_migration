package HTGT::Utils::DesignFinder::Stringify;

use MooseX::Role::WithOverloading;

requires 'stringify';

use overload
    q{""}    => 'stringify',
    fallback => 1;

1;

__END__
