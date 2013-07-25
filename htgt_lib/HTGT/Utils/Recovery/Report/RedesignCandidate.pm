package HTGT::Utils::Recovery::Report::RedesignCandidate;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'rdr-c';
}

sub _build_table_id {
    'candidates_for_redesign_resynthesis';
}

sub _build_name {
    'Candidates for Redesign/Resynthesis Recovery';
}

sub _build_columns {
    [ qw( marker_symbol
          mgi_accession_id
          sponsor
          design_wells
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
            { rdr_candidates => 'design_well' }
        ]
    };
}

sub auxiliary_data {
    my ( $self, $gene_status ) = @_;

    return (
        design_wells => join( q{, }, $gene_status->rdr_candidate_design_wells )
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
