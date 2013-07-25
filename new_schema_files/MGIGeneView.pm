package HTGTDB::MGIGeneView;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::MGIGeneView

=cut

__PACKAGE__->table("mgi_gene_view");

=head1 ACCESSORS

=head2 mgi_gene_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

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
  size: 100

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

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ensembl_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ensembl_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 sp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 tm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 vega_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 vega_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 vega_gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

#__PACKAGE__->add_columns(
#  "mgi_gene_id",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_accession_id",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "marker_type",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "marker_symbol",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "marker_name",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_chr",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "representative_genome_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "representative_genome_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "representative_genome_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "representative_genome_build",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "entrez_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ncbi_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ncbi_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ncbi_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ncbi_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "unists_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "unists_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "unists_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_qtl_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mgi_qtl_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_qtl_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mirbase_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "mirbase_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mirbase_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "roopenian_sts_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "roopenian_sts_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ensembl_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ensembl_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "ensembl_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ensembl_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ensembl_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "sp",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "tm",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "vega_gene_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "vega_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "vega_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "vega_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "vega_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
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
  { data_type => "varchar2", is_nullable => 1, size => 100 },
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


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5uuZuozuAWDPONBdAPTOmw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
