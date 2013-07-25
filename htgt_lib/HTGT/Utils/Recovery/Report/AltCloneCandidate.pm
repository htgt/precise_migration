package HTGT::Utils::Recovery::Report::AltCloneCandidate;

use Moose;
use namespace::autoclean;

with 'HTGT::Utils::Recovery::Report';

use Iterator;
use HTGT::Utils::Recovery::GeneData;

sub _build_handled_state { 'acr-c' }

sub _build_name { 'Candidates for Alternate Clone Recovery (with alternates)' }

sub _build_columns {
    [
        qw( marker_symbol
            mgi_accession_id
            sp
            tm
            mgi_gt_count
            sponsor
            epd_distribute_count
            chosen_clones
            design_well
            alt_clone_well
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
into the has_many B<GRCAltCloneAlternate> relationship to return one
row per alternate clone.

=cut

sub _build_iterator {
    my $self = shift;

    my $rs = $self->{schema}->resultset( 'GRGeneStatus' )->search(
        $self->search_filter,
        $self->search_params
    );
    
    my ( @base_data, @alt_clones );
    
    return Iterator->new(
        sub {
            unless ( @alt_clones ) {
                my $gene_status = $rs->next or Iterator->is_done;
                @base_data = $self->_base_data( $gene_status );                
                @alt_clones = $gene_status->acr_candidate_alternate_wells;                
            }

            return {
                @base_data,
                $self->_alt_clone_data( shift @alt_clones )
            };
        }
    );
}

sub _base_data {
    my ( $self, $gene_status ) = @_;

    my $gene_data = HTGT::Utils::Recovery::GeneData->new( schema => $self->schema, mgi_gene_id => $gene_status->mgi_gene_id );
    
    return (
        $self->common_data( $gene_status ),
        chosen_clones        => $self->_chosen_str( $gene_status ),
        sp                   => $gene_status->mgi_gene->sp ? 'yes' : 'no',
        tm                   => $gene_status->mgi_gene->tm ? 'yes' : 'no',
        mgi_gt_count         => $gene_status->mgi_gene->mgi_gt_count,
        regeneron_status     => $self->regeneron_status( $gene_status->mgi_gene ),
        epd_distribute_count => $gene_data->epd_distribute_count,
        grd_plates           => $self->grd_plates( $gene_status->mgi_gene_id ),
    );
}

sub _chosen_str {
    my ( $self, $gene_status ) = @_;

    my @chosen = map sprintf( '%s(%s)', $_->chosen_well, $_->child_plates ), $gene_status->acr_candidate_chosen;

    return join( q{, }, @chosen );    
}

sub _alt_clone_data {
    my ( $self, $alt_clone_well ) = @_;
    
    return unless defined $alt_clone_well;

    my $well_detail = $self->schema->resultset( 'WellDetail' )->find(
        {
            well_id => $alt_clone_well->well_id
        }
    );

    return (
        alt_clone_well => $well_detail,
        design_well    => $well_detail->design_well,
        cassette       => $well_detail->cassette,
        backbone       => $well_detail->backbone,
        pg_pass_level  => $well_detail->pass_level,        
    );        
}

__PACKAGE__->meta->make_immutable;

1;

__END__
