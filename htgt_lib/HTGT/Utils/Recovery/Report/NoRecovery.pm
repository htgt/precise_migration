package HTGT::Utils::Recovery::Report::NoRecovery;

use Moose;
use namespace::autoclean;

with 'HTGT::Utils::Recovery::Report';

sub _build_handled_state { 'none' }

sub _build_name { 'Genes Requiring no Recovery' }

__PACKAGE__->meta->make_immutable;

1;

__END__
