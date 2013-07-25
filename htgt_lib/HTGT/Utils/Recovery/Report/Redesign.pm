package HTGT::Utils::Recovery::Report::Redesign;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'rdr';    
}

sub _build_table_id {
    'genes_in_redesign_recovery'
}

sub _build_name {
    'Genes in Redesign/Resynthesis Recovery' 
}

sub _build_columns {
    [ qw( marker_symbol
          mgi_accession_id
          sponsor
          rdr_wells
          comment
          redesign_recovery
          resynthesis_recovery
          gateway_recovery
          alternate_clone_recovery          
    ) ]
}    

sub _build_search_params {
    return {
        prefetch => [
            'mgi_gene',
            { in_rdr => 'rdr_well' }
        ]
    };
}

sub auxiliary_data {
    my ( $class, $gene_status ) = @_;

    return (
        rdr_wells => join( q{, }, $gene_status->rdr_wells )
    );             
}

__PACKAGE__->meta->make_immutable;

1;

__END__
