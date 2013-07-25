package HTGTDB::MGIGene;

use strict;
use warnings;
use Const::Fast;
use HTGT::Constants qw( %SPONSOR_COLUMN_FOR );

=head1 AUTHOR

Vivek Iyer
Darren Oakley

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mgi_gene');

__PACKAGE__->sequence('S_MGI_GENE');

#__PACKAGE__->add_columns(
#    qw/
#      mgi_gene_id
#      mgi_accession_id
#      marker_type
#      marker_symbol
#      marker_name
#      representative_genome_id
#      representative_genome_chr
#      representative_genome_start
#      representative_genome_end
#      representative_genome_strand
#      representative_genome_build
#      entrez_gene_id
#      ncbi_gene_chromosome
#      ncbi_gene_start
#      ncbi_gene_end
#      ncbi_gene_strand
#      ensembl_gene_id
#      ensembl_gene_chromosome
#      ensembl_gene_start
#      ensembl_gene_end
#      ensembl_gene_strand
#      vega_gene_id
#      vega_gene_chromosome
#      vega_gene_start
#      vega_gene_end
#      vega_gene_strand
#      unists_gene_start
#      unists_gene_end
#      mgi_qtl_gene_start
#      mgi_qtl_gene_end
#      mirbase_gene_id
#      mirbase_gene_start
#      mirbase_gene_end
#      roopenian_sts_gene_start
#      roopenian_sts_gene_end
#      mgi_gt_count
#      sp
#      tm
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 }, # not nullable because of might_have relationship
  "marker_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_name",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "representative_genome_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "representative_genome_chr",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "representative_genome_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "representative_genome_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "representative_genome_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "representative_genome_build",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "entrez_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ncbi_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ncbi_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ncbi_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ncbi_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "unists_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "unists_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "unists_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_qtl_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_qtl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_qtl_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mirbase_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mirbase_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mirbase_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "roopenian_sts_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "roopenian_sts_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ensembl_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ensembl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "sp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "tm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "vega_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "vega_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "vega_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vega_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vega_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "mgi_gt_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('mgi_gene_id');
__PACKAGE__->add_unique_constraint( mgi_accession_id => [qw/mgi_accession_id/] );

__PACKAGE__->has_many( projects         => 'HTGTDB::Project',   'mgi_gene_id' );
__PACKAGE__->has_many( mgi_sanger_genes => 'HTGTDB::MGISanger', 'mgi_gene_id' );
__PACKAGE__->has_many( gene_user_links  => 'HTGTDB::GeneUser', 'mgi_gene_id' );
__PACKAGE__->has_many( gene_comments    => 'HTGTDB::GeneComment', 'mgi_gene_id' );

__PACKAGE__->many_to_many( 'ext_users' => 'gene_user_links', 'ext_user' );

__PACKAGE__->might_have( cached_regeneron_status => 'HTGTDB::CachedRegeneronStatus', { 'foreign.mgi_accession_id' => 'self.mgi_accession_id' } );

__PACKAGE__->might_have( gene_recovery => 'HTGTDB::GRGeneStatus', 'mgi_gene_id' );

__PACKAGE__->has_many( gene_recovery_history => 'HTGTDB::GRGeneStatusHistory', 'mgi_gene_id' );

const my %VALID_PIPELINE => map { $_ => 1 } qw( EUCOMM KOMP EUCOMM-Tools );

sub reset_status_to_redesign_requested {
    my $self = shift;
    my $pipeline = shift;
    my $edit_user = shift;
    
    my $targeting_projects = $self->_find_applicable_targeting_projects($pipeline);
    my $existing_redesign_requested_project;
    
    foreach my $project (@$targeting_projects){
        if(
           $project->status->code eq 'RR'
           or $project->status->code eq 'DR'
           or $project->status->code eq 'AR'
           or $project->status->code eq 'DC'
           or $project->status->code eq 'DNP'
        ){
            $existing_redesign_requested_project = $project;
            next;
        }
        $project->terminate ($edit_user);
        $project->update ({ is_latest_for_gene => 0 });
    }
    
    if(!$existing_redesign_requested_project){
        my $redesign_project = $self->_make_redesign_project ($pipeline, $edit_user);
        $redesign_project->update({is_latest_for_gene => 1});
    }
}

sub _make_redesign_project {
    my $self = shift;
    my $pipeline = shift;
    my $edit_user = shift;
    my $schema = $self->result_source->schema;
    
    unless ( $pipeline and exists $VALID_PIPELINE{$pipeline} ) {
        die "Pipeline must be either " . join(', ', keys %VALID_PIPELINE) ;
    }
    
    my $project_status_rs = $schema->resultset('HTGTDB::ProjectStatus');
    my $redesign_status = $project_status_rs->find ({ code => 'RR'});
    die 'cant find redesign status' unless $redesign_status;

    my $project_params = {
        mgi_gene_id          => $self->mgi_gene_id,
        project_status_id    => $redesign_status->project_status_id,
        is_publicly_reported => 1,
        edit_user            => $edit_user,
        edit_date            => \'sysdate',
        status_change_date   => \'sysdate'
    };
    $project_params->{ $SPONSOR_COLUMN_FOR{$pipeline} } = 1;
        
    my $new_project = $schema->resultset('HTGTDB::Project')->create( $project_params );
}

sub _find_applicable_targeting_projects {
    my $self = shift;
    my $pipeline = shift;
    
    unless ( $pipeline and exists $VALID_PIPELINE{$pipeline} ) {
        die "Pipeline must be either " . join(', ', keys %VALID_PIPELINE) ;
    }
    
    die "this gene has no projects" unless ($self->projects->count > 0);
    
    my $applicable_projects;
    my $pipeline_column = $SPONSOR_COLUMN_FOR{$pipeline};
    foreach my $project ($self->projects){
        if ( $project->$pipeline_column ) {
            next if $pipeline eq 'EUCOMM' && $project->is_trap;
            push @{$applicable_projects}, $project;
        }
    }
    
    return $applicable_projects;
}

1;

__END__

