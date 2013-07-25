package HTGT::Utils::Recovery::Report::Gateway::KOMP;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::Gateway';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::KOMP';

__PACKAGE__->meta->make_immutable;

1;

__END__
