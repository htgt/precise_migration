package HTGT::Utils::Recovery::Report::RedesignCandidate::EUCOMM;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::RedesignCandidate';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::EUCOMM';

__PACKAGE__->meta->make_immutable;

1;

__END__
