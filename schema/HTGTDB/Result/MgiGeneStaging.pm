use utf8;
package HTGTDB::Result::MgiGeneStaging;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiGeneStaging

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_GENE_STAGING>

=cut

__PACKAGE__->table("MGI_GENE_STAGING");

=head1 ACCESSORS

=head2 mgi_gene_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_mgi_gene'
  size: [10,0]

=head2 mirbase_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 representative_genome_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 marker_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 unists_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 roopenian_sts_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_chr

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_qtl_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 ensembl_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 representative_genome_build

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 vega_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 representative_genome_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 representative_genome_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ensembl_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 unists_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ncbi_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 marker_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 entrez_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 vega_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 vega_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 roopenian_sts_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_qtl_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 reconcile_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 unists_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_mgi_gene",
    size => [10, 0],
  },
  "mirbase_gene_start",
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
  "marker_name",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "unists_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "roopenian_sts_gene_start",
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
  "vega_gene_chromosome",
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
  "vega_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_qtl_gene_end",
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
  "ensembl_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "ensembl_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "representative_genome_build",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "vega_gene_end",
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
  "ncbi_gene_start",
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
  "representative_genome_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ensembl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "unists_gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ncbi_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ncbi_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "marker_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "entrez_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "vega_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "vega_gene_start",
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
  "mgi_qtl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "reconcile_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "unists_gene_chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kF7dgAIkxXhxQv2PUZBzsg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
