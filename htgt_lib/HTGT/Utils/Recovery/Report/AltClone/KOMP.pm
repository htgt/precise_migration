package HTGT::Utils::Recovery::Report::AltClone::KOMP;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::AltClone';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::KOMP';

__PACKAGE__->meta->make_immutable;

1;

__END__
