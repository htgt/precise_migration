package HTGT::Utils::Recovery::Report::GatewayCandidate::EUCOMM;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::GatewayCandidate';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::EUCOMM';

__PACKAGE__->meta->make_immutable;

1;

__END__
