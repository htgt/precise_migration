package HTGT::Utils::Recovery::Report::NoPCSQC::KOMP;

use strict;
use warnings FATAL => 'all';

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::NoPCSQC';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::KOMP';

__PACKAGE__->meta->make_immutable;

1;

__END__
