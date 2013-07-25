package HTGT::View::NakedTT;

use strict;
use warnings;
use base 'HTGT::View::TT';

=head1 NAME

HTGT::View::NakedTT - NakedTT View for HTGT

=head1 DESCRIPTION

TT View for HTGT - just no wrapping in 'html' and 'wrapper' tags...

=head1 AUTHOR

Darren Oakley
Dan Klose

=head1 SEE ALSO

L<HTGT>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt',
  INCLUDE_PATH => [ 
    HTGT->path_to( 'root', 'lib' ), #standard TT lib location
    HTGT->path_to( 'root', 'src' ), #standard TT template location?
    HTGT->path_to( 'root'  ), # we seem to be putting our template heirarchy above src....
  ], 
  PRE_PROCESS  => undef,
  WRAPPER      => undef,
);

1;
