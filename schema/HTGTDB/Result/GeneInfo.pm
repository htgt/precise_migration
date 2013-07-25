use utf8;
package HTGTDB::Result::GeneInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GeneInfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GENE_INFO>

=cut

__PACKAGE__->table("GENE_INFO");

=head1 ACCESSORS

=head2 gene_info_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 gene_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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

=head2 ensembl_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 otter_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mgi_symbol_source

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 otter_id_source

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ensembl_id_source

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 otter_match_method

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 arq_sources

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 batch

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 for_eucomm_mouse

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 for_recovery

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 recovery_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 400

=head2 igtc_hits

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 ob_hits

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 for_eumodic

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 eucomm_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 400

=head2 homozygous_lethal

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 status_edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 status_edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 ics_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 mrc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 sng_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 gsf_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 cnr_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 tigm_hits

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 es_cell_count

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 tigm_sanger_hits

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 pc_summary_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 pg_summary_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 epd_summary_counts

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 ship_date_csd

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 ship_date_hzm

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 final_vector_distributed_count

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "gene_info_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
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
  "ensembl_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "otter_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mgi_symbol_source",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "otter_id_source",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ensembl_id_source",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "otter_match_method",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "arq_sources",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "batch",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "for_eucomm_mouse",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "for_recovery",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "recovery_comment",
  { data_type => "varchar2", is_nullable => 1, size => 400 },
  "igtc_hits",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ob_hits",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "for_eumodic",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "eucomm_comment",
  { data_type => "varchar2", is_nullable => 1, size => 400 },
  "homozygous_lethal",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "status_edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "status_edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "ics_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "mrc_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "sng_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "gsf_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cnr_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "tigm_hits",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "es_cell_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "tigm_sanger_hits",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pc_summary_status",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "pg_summary_status",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "epd_summary_counts",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "ship_date_csd",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "ship_date_hzm",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "final_vector_distributed_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_info_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_info_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hhocouI0sznq5WhCH0ljMg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
