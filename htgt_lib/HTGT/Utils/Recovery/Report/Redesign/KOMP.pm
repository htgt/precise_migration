package HTGT::Utils::Recovery::Report::Redesign::KOMP;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::Redesign';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::KOMP';

__PACKAGE__->meta->make_immutable;

1;

__END__
