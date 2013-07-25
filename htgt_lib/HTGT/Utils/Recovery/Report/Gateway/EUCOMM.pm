package HTGT::Utils::Recovery::Report::Gateway::EUCOMM;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::Gateway';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::EUCOMM';

__PACKAGE__->meta->make_immutable;

1;

__END__
