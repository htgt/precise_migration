package HTGT::Utils::Recovery::Report::Gateway;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'gwr';    
}

sub _build_table_id {
    'genes_in_gateway_recovery'
}

sub _build_name {
    'Genes in Gateway Recovery' 
}

sub _build_columns {
    [ qw( marker_symbol
          mgi_accession_id
          sponsor
          gwr_wells
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
            { in_gwr => 'gwr_well' }
        ]
    };
}

sub auxiliary_data {
    my ( $self, $gene_status ) = @_;

    return (
        gwr_wells => join( q{, }, $gene_status->gwr_wells )
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
