package HTGT::Utils::Recovery::Report::NoPCSQC;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'no-pcs-qc'
}

sub _build_name {
    'Genes with no PCS QC'
}

__PACKAGE__->meta->make_immutable;

1;

__END__
