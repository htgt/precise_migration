package HTGT::Model::IDCCMart;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'HTGT::BioMart::QueryFactory',
                     args  => { martservice => 'http://www.knockoutmouse.org/biomart/martservice' } );

1;

__END__
