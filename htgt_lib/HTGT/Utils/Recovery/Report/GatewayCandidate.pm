package HTGT::Utils::Recovery::Report::GatewayCandidate;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'gwr-c';    
}

sub _build_table_id {
    'candidates_for_gateway_recovery'
}

sub _build_name {
    'Candidates for Gateway Recovery' 
}

sub _build_columns {
    [
        qw( marker_symbol
            mgi_accession_id
            sponsor
            pcs_well
            valid_primers
            comment
            redesign_recovery
            resynthesis_recovery
            gateway_recovery
            alternate_clone_recovery            
      )
    ]
}    

sub _build_search_params {
    return {
        prefetch => [
            'mgi_gene',
            { gwr_candidates => 'pcs_well' }
        ]
    };
}

sub auxiliary_data {
    my ( $self, $gene_status ) = @_;

    my $gwr_candidate = $gene_status->gwr_candidates->first
        or return;

    return (
        pcs_well             => $gwr_candidate->pcs_well,
        valid_primers        => $gwr_candidate->valid_primers,
    );
}
        
__PACKAGE__->meta->make_immutable;

1;

__END__
