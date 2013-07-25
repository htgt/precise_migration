package HTGT::View::CsvTT;

use strict;
use warnings;
use base 'HTGT::View::BaseTT';

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.csvtt',
  INCLUDE_PATH => [ 
    HTGT->path_to( 'root', 'lib' ), #standard TT lib location
    HTGT->path_to( 'root', 'src' ), #standard TT template location?
    HTGT->path_to( 'root'  ), # we seem to be putting our template heirarchy above src....
  ], 
);

=head1 NAME

HTGT::View::CsvTT - CsvTT View for HTGT

=head1 DESCRIPTION

CSV View for HTGT - no wrapping in 'html' and 'wrapper' tags, just CSV...

=head1 AUTHOR

Darren Oakley

=head1 SEE ALSO

L<HTGT>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
