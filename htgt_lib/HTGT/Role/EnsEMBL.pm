package HTGT::Role::EnsEMBL;

use Moose::Role;
use namespace::autoclean;
use Bio::EnsEMBL::Registry;

our $SPECIES = 'mouse';

{
    my $initialized;    

    sub _ensembl_init {
        unless ( $initialized ) {
            Bio::EnsEMBL::Registry->load_registry_from_db(
                -host => $ENV{HTGT_ENSEMBL_HOST} || 'ens-livemirror.internal.sanger.ac.uk',
                -user => $ENV{HTGT_ENSEMBL_USER} || 'ensro'
            )
        }
        $initialized = 1;
    }
}

sub registry {
    shift->_ensembl_init;
    return 'Bio::EnsEMBL::Registry';
}

sub db_adaptor {
    shift->registry->get_DBAdaptor( $SPECIES, 'core' );
}

sub gene_adaptor {
    shift->registry->get_adaptor( $SPECIES, 'core', 'gene' );
}

sub slice_adaptor {
    shift->registry->get_adaptor( $SPECIES, 'core', 'slice' );
}

sub exon_adaptor {
    shift->registry->get_adaptor( $SPECIES, 'core', 'exon');
}

sub transcript_adaptor {
    shift->registry->get_adaptor( $SPECIES, 'core', 'transcript' );
}

sub constrained_element_adaptor {
    shift->registry->get_adaptor( 'Multi', 'compara', 'ConstrainedElement' );
}

sub repeat_feature_adaptor {
    shift->registry->get_adaptor( $SPECIES, 'core', 'repeatfeature' );
}

1;

__END__
