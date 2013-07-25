package HTGT::Utils::Recovery::Report::GatewayCandidate::KOMP;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Recovery::Report::GatewayCandidate';
with    'HTGT::Utils::Recovery::Report::FilterSponsor::KOMP';

__PACKAGE__->meta->make_immutable;

1;

__END__
