package HTGTDB::GeneInfo;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gene_info');
__PACKAGE__->sequence('S_GENE_INFO');

#__PACKAGE__->add_columns(
#    qw/
#      gene_info_id
#      gene_id
#      sp
#      tm
#      ensembl_id
#      otter_id
#      mgi_symbol
#      mgi_symbol_source
#      otter_id_source
#      ensembl_id_source
#      otter_match_method
#      arq_sources
#      batch
#      for_eucomm_mouse
#      for_eumodic
#      eucomm_comment
#      for_recovery
#      recovery_comment
#      igtc_hits
#      ob_hits
#      tigm_hits
#      tigm_sanger_hits
#      homozygous_lethal
#      cnr_status
#      ics_status
#      mrc_status
#      sng_status
#      gsf_status
#      status_edit_user
#      status_edit_date
#      es_cell_count
#      pc_summary_status
#      pg_summary_status
#      epd_summary_counts
#      final_vector_distributed_count
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
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
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('gene_info_id');
__PACKAGE__->belongs_to( gene => 'HTGTDB::GnmGene', "gene_id" );

return 1;

