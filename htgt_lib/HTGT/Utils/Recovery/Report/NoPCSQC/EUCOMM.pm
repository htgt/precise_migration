package HTGT::Utils::Recovery::Report::NoPCSQC::EUCOMM;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::NoPCSQC';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::EUCOMM';

__PACKAGE__->meta->make_immutable;

1;

__END__
