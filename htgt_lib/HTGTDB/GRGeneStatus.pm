package HTGTDB::GRGeneStatus;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRGeneStatus.pm $
# $LastChangedRevision: 1977 $
# $LastChangedDate: 2010-06-23 16:57:52 +0100 (Wed, 23 Jun 2010) $
# $LastChangedBy: rm7 $

use base 'DBIx::Class';

use DateTime;

__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table('gr_gene_status');

#__PACKAGE__->add_columns( 'gr_gene_status_id', 'mgi_gene_id', 'state', 'note', 'updated' => { data_type => 'datetime' } );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gr_gene_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "state",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "updated",
  { data_type => "datetime", is_nullable => 0 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'gr_gene_status_id' );

__PACKAGE__->add_unique_constraint( [ 'mgi_gene_id' ] );

__PACKAGE__->belongs_to( status => 'HTGTDB::GRValidState', 'state' );

__PACKAGE__->belongs_to( mgi_gene => 'HTGTDB::MGIGene', 'mgi_gene_id' );

__PACKAGE__->has_many( in_acr => 'HTGTDB::GRAltClone', 'gr_gene_status_id' );

__PACKAGE__->has_many( in_gwr => 'HTGTDB::GRGateway', 'gr_gene_status_id' );

__PACKAGE__->has_many( in_rdr => 'HTGTDB::GRRedesign', 'gr_gene_status_id' );

__PACKAGE__->has_many( acr_candidate_chosen => 'HTGTDB::GRCAltCloneChosen', 'gr_gene_status_id' );

__PACKAGE__->has_many( acr_candidate_alternates => 'HTGTDB::GRCAltCloneAlternate', 'gr_gene_status_id' );

__PACKAGE__->has_many( gwr_candidates => 'HTGTDB::GRCGateway', 'gr_gene_status_id' );

__PACKAGE__->has_many( rdr_candidates => 'HTGTDB::GRCRedesign', 'gr_gene_status_id' );

__PACKAGE__->has_many( reseq_candidates => 'HTGTDB::GRCReseq', 'gr_gene_status_id' );

sub gwr_candidate_pcs_well {
    my $self = shift;

    my $gwr_candidate = $self->gwr_candidates->first
        or return;

    return $gwr_candidate->pcs_well;
}

sub rdr_candidate_design_wells {
    my $self = shift;

    sort { $a->plate->name <=> $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->design_well, $self->rdr_candidates;
}

sub acr_candidate_alternate_wells {
    my $self = shift;

    sort { $a->plate->name cmp $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->alternate_well, $self->acr_candidate_alternates;
}

sub acr_candidate_chosen_wells {
    my $self = shift;
    
    sort { $a->plate->name cmp $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->chosen_well, $self->acr_candidate_chosen;

}

sub acr_wells {
    my $self = shift;

    sort { $a->plate->name cmp $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->acr_well, $self->in_acr;
}

sub gwr_wells {
    my $self = shift;

    sort { $a->plate->name cmp $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->gwr_well, $self->in_gwr;
}

sub rdr_wells {
    my $self = shift;

    sort { $a->plate->name <=> $b->plate->name || $a->well_name cmp $b->well_name }
        map $_->rdr_well, $self->in_rdr;
}

1;

__END__
