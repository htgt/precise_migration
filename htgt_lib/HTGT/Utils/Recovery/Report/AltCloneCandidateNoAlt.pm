package HTGT::Utils::Recovery::Report::AltCloneCandidateNoAlt;

use Moose;
use namespace::autoclean;

with 'HTGT::Utils::Recovery::Report';

use Iterator;
use HTGT::Utils::Recovery::GeneData;

sub _build_handled_state { 'acr-c-no-alt' }

sub _build_name { 'Candidates for Alternate Clone Recovery (no alternates)' }

sub _build_columns {
    [
        qw( marker_symbol
            mgi_accession_id
            sp
            tm
            mgi_gt_count
            sponsor
            epd_distribute_count
            design_well
            chosen_clone_well
            chosen_clone_name
            chosen_child_plates
            grd_plates
            cassette
            backbone
            pg_pass_level
            regeneron_status
            comment
            redesign_recovery
            resynthesis_recovery
            gateway_recovery
            alternate_clone_recovery            
      )
    ]
}

=method _build_iterator

Override the default iterator to construct an iterator that recurses
into the has_many B<GRCAltCloneChosen> relationship to return one
row per chosen clone.

=cut

sub _build_iterator {
    my $self = shift;

    my $rs = $self->{schema}->resultset( 'GRGeneStatus' )->search(
        $self->search_filter,
        $self->search_params
    );
    
    my ( @base_data, @chosen_clones );
    
    return Iterator->new(
        sub {
            unless ( @chosen_clones ) {
                my $gene_status = $rs->next or Iterator->is_done;
                @base_data = $self->_base_data( $gene_status );                
                @chosen_clones = $gene_status->acr_candidate_chosen;
            }

            return {
                @base_data,
                $self->_chosen_clone_data( shift @chosen_clones )
            };
        }
    );
}

sub _base_data {
    my ( $self, $gene_status ) = @_;

    my $gene_data = HTGT::Utils::Recovery::GeneData->new( schema => $self->schema, mgi_gene_id => $gene_status->mgi_gene_id );
    
    return (
        $self->common_data( $gene_status ),
        sp                   => $gene_status->mgi_gene->sp ? 'yes' : 'no',
        tm                   => $gene_status->mgi_gene->tm ? 'yes' : 'no',
        mgi_gt_count         => $gene_status->mgi_gene->mgi_gt_count,
        regeneron_status     => $self->regeneron_status( $gene_status->mgi_gene ),
        epd_distribute_count => $gene_data->epd_distribute_count,
        grd_plates           => $self->grd_plates( $gene_status->mgi_gene_id ),
    );
}

sub _chosen_clone_data {
    my ( $self, $chosen_clone ) = @_;
    
    return unless defined $chosen_clone;
    
    my $well_detail = $self->schema->resultset( 'WellDetail' )->find(
        {
            well_id => $chosen_clone->chosen_well_id
        }
    );

    return (
        chosen_clone_name   => $chosen_clone->chosen_clone_name,
        chosen_child_plates => $chosen_clone->child_plates,
        chosen_clone_well   => $well_detail->stringify,
        design_well         => $well_detail->design_well,
        cassette            => $well_detail->cassette,
        backbone            => $well_detail->backbone,
        pg_pass_level       => $well_detail->pass_level,
    );        
}

__PACKAGE__->meta->make_immutable;

1;

__END__
