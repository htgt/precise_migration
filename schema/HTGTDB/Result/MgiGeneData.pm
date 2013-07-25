use utf8;
package HTGTDB::Result::MgiGeneData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiGeneData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_GENE_DATA>

=cut

__PACKAGE__->table("MGI_GENE_DATA");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 marker_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 representative_genome_id

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

=head2 representative_genome_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 representative_genome_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 representative_genome_build

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 entrez_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ncbi_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ncbi_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ncbi_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 unists_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 unists_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 unists_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_qtl_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_qtl_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_qtl_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mirbase_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mirbase_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 mirbase_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 roopenian_sts_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 roopenian_sts_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
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
);

=head1 PRIMARY KEY

=over 4

=item * L</mgi_accession_id>

=back

=cut

__PACKAGE__->set_primary_key("mgi_accession_id");

=head1 RELATIONS

=head2 mgi_ensembl_gene_maps

Type: has_many

Related object: L<HTGTDB::Result::MgiEnsemblGeneMap>

=cut

__PACKAGE__->has_many(
  "mgi_ensembl_gene_maps",
  "HTGTDB::Result::MgiEnsemblGeneMap",
  { "foreign.mgi_accession_id" => "self.mgi_accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mgi_vega_gene_maps

Type: has_many

Related object: L<HTGTDB::Result::MgiVegaGeneMap>

=cut

__PACKAGE__->has_many(
  "mgi_vega_gene_maps",
  "HTGTDB::Result::MgiVegaGeneMap",
  { "foreign.mgi_accession_id" => "self.mgi_accession_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 ensembl_genes

Type: many_to_many

Composing rels: L</mgi_ensembl_gene_maps> -> ensembl_gene

=cut

__PACKAGE__->many_to_many("ensembl_genes", "mgi_ensembl_gene_maps", "ensembl_gene");

=head2 vega_genes

Type: many_to_many

Composing rels: L</mgi_vega_gene_maps> -> vega_gene

=cut

__PACKAGE__->many_to_many("vega_genes", "mgi_vega_gene_maps", "vega_gene");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yNSWr843seweMxlvU/d3ew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
