package HTGT::Utils::Recovery::Report::AltClone;

use Moose;
use namespace::autoclean;
use HTGT::Utils::Recovery::GeneData;
use List::MoreUtils qw( firstval );

with 'HTGT::Utils::Recovery::Report';

sub _build_handled_state { 'acr' }

sub _build_name { 'Genes in Alternate Clone Recovery' }

sub _build_columns {
    return [
        qw( marker_symbol
            mgi_accession_id
            sponsor
            design_type
            validated_by_annotation
            acr_well
            acr_pass_level
            dna_status
            dna_well
            epd_distribute_count
            ep_plates
            regeneron_status
            eucomm_ep_candidate
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
            { in_acr => 'acr_well' }
        ]
    }
}

=pod
    
=method _build_iterator

Override the default iterator to construct an iterator that recurses
into the has_many B<GRAltClone> relationship to return one
row per alternate clone recovery well.

=cut

sub _build_iterator {    
    my $self = shift;

    my $rs = $self->schema->resultset( 'GRGeneStatus' )->search(
        $self->search_filter,
        $self->search_params
    );
    
    my ( @base_data, @acr_wells, $gene_data );
    
    return Iterator->new(
        sub {
            unless ( @acr_wells ) {
                my $gene_status = $rs->next or Iterator->is_done;
                $gene_data = HTGT::Utils::Recovery::GeneData->new( schema => $self->schema, mgi_gene_id => $gene_status->mgi_gene->mgi_gene_id );         
                @base_data = $self->_base_data( $gene_data, $gene_status );
                @acr_wells = $gene_status->acr_wells;
            }

            my %data = ( @base_data, $self->_alt_clone_well_data( $gene_data, shift @acr_wells ) );

            $data{eucomm_ep_candidate} = ( $data{design_type} eq 'KO'
                                               and $data{sponsor} eq 'KOMP'
                                                   and $data{dna_status}
                                                       and $data{dna_status} eq 'pass'
                                                           and $data{epd_distribute_count} == 0
                                                               and $data{regeneron_status}
                                                                   and ( $data{regeneron_status} eq 'ES cell colonies screened / QC positives'
                                                                             or $data{regeneron_status} eq 'Germline Transmission Achieved'
                                                                                 or $data{regeneron_status} eq 'ES Cell Clone Microinjected' ) );
            return \%data;
        }
    );
}

sub _base_data {
    my ( $self, $gene_data, $gene_status ) = @_;

    return (
        $self->common_data( $gene_status ),
        regeneron_status     => $self->regeneron_status( $gene_status->mgi_gene ),
        epd_distribute_count => $gene_data->epd_distribute_count,
        ep_plates            => join( q{,}, @{ $self->_ep_plates( $gene_status->mgi_gene ) } ),
    );
}

sub _alt_clone_well_data {
    my ( $self, $gene_data, $acr_well ) = @_;
    
    return unless defined $acr_well;

    my $well_detail = $self->schema->resultset( 'WellDetail' )->find(
        {
            well_id => $acr_well->well_id
        }
    );

    my $dna_status = $gene_data->get_acr_well_dna_status( $acr_well->well_id );
    my $dna_well;
    if ( $dna_status and $dna_status eq 'pass' ) {
        $dna_well = firstval { $_->dna_status and $_->dna_status eq 'pass' } $well_detail->descendants;        
    }
    
    return (
        acr_well                => $well_detail,
        acr_pass_level          => $gene_data->get_acr_well_pass_level( $acr_well->well_id ),
        dna_status              => $dna_status,
        dna_well                => $dna_well,
        design_type             => $acr_well->design_instance->design->design_type || 'KO',
        validated_by_annotation => $acr_well->design_instance->design->validated_by_annotation,
    );        
}

sub _ep_plates {
    my ( $self, $mgi_gene ) = @_;

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            $dbh->selectcol_arrayref( <<'EOT', undef, $mgi_gene->mgi_gene_id );
select distinct plate.name
from plate
join well on well.plate_id = plate.plate_id
join project on project.design_instance_id = well.design_instance_id
where plate.type = 'EP'
and project.mgi_gene_id = ?
order by plate.name
EOT
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
