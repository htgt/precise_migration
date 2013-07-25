package HTGT::Utils::Recovery::Report::ResequencingCandidate;

use Moose;
use namespace::autoclean;

with qw( HTGT::Utils::Recovery::Report );

sub _build_handled_state {
    'reseq-c';    
}

sub _build_table_id {
    'candidates_for_resequencing_recovery'
}

sub _build_name {
    'Candidates for Resequencing Recovery' 
}

sub _build_columns {
    [
        qw( marker_symbol
            mgi_accession_id
            sponsor
            design_well
            targvec_well            
            valid_primers
            cassette
            backbone
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
            'reseq_candidates',
        ]
    };
}

=method _build_iterator

Override the default iterator to construct an iterator that recurses
into the has_many B<GRCReseq> relationship to return one row per
resequencing candidate well.

=cut

sub _build_iterator {
    my $self = shift;

    my $rs = $self->{schema}->resultset( 'GRGeneStatus' )->search(
        $self->search_filter,
        $self->search_params
    );
    
    my ( @common_data, @reseq_candidates );
    
    return Iterator->new(
        sub {
            unless ( @reseq_candidates ) {
                my $gene_status = $rs->next or Iterator->is_done;
                @common_data = $self->common_data( $gene_status );
                @reseq_candidates = $gene_status->reseq_candidates;                
            }

            return {
                @common_data,
                $self->_reseq_candidate_data( shift @reseq_candidates )
            };
        }
    );
}

sub _reseq_candidate_data {
    my ( $self, $reseq_c ) = @_;

    my $well_detail = $self->schema->resultset( 'WellDetail' )->find(
        {
            well_id => $reseq_c->targvec_well_id
        }
    );

    return (
        targvec_well   => $well_detail->stringify,
        design_well    => $well_detail->design_well,
        cassette       => $well_detail->cassette,
        backbone       => $well_detail->backbone,
        valid_primers  => $reseq_c->valid_primers
    );        
}

__PACKAGE__->meta->make_immutable;

1;

__END__
