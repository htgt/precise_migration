package HTGTDB::Result::EPDDump;

use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class/;

__PACKAGE__->load_components('Core');
__PACKAGE__->table('epd_dump');
__PACKAGE__->add_relationship(
    'well' => 'HTGTDB::Well',
    { 'foreign.well_name' => 'self.epd' },
    { 'accessor'          => 'single' },
);
#__PACKAGE__->add_columns(
#    qw/
#      project_id
#      eucomm
#      komp
#      mgp
#      norcomm
#      mgi
#      design
#      design_id
#      design_instance_id
#      design_type
#      pcs_plate
#      pcs_well
#      pc_clone
#      pcs_qc_result
#      pcs_qc_result_id
#      pcs_distribute
#      pcs_comments
#      pgs_plate
#      pgs_well
#      pgs_well_id
#      cassette
#      backbone
#      pg_clone
#      pgs_qc_result
#      pgs_qc_result_id
#      pgs_distribute
#      pgs_comments
#      epd
#      es_cell_line
#      cell_line_passage
#      epd_distribute
#      targeted_trap
#      epd_comments
#      fp
#      marker_symbol
#      ensembl_gene_id
#      vega_gene_id
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "eucomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "komp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "mgp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "norcomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "mgi",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "design_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_type",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "pcs_plate",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_well",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pc_clone",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "pcs_qc_result",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_qc_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pcs_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_comments",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "pgs_plate",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgs_well",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pgs_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "pg_clone",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "pgs_qc_result",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgs_qc_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pgs_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgs_comments",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "epd",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "cell_line_passage",
  { data_type => "varchar2", is_nullable => 1, size => 99 },
  "epd_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_comments",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "fp",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "vega_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
);
# End of dbicdump add_columns data

1;

__END__

=pod

=head1 NAME

HTGTDB::Result::EPDDump

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SQL COMMAND TO CREATE THE VIEW

  CREATE OR REPLACE FORCE VIEW "EUCOMM_VECTOR"."EPD_DUMP" ("PROJECT_ID", "EUCOMM", "KOMP", "MGP", "NORCOMM", "MGI", "DESIGN", "DESIGN_ID", "DESIGN_INSTANCE_ID", "DESIGN_TYPE", "PCS_PLATE", "PCS_WELL", "PC_CLONE", "PCS_QC_RESULT", "PCS_QC_RESULT_ID", "PCS_DISTRIBUTE", "PCS_COMMENTS", "PGS_PLATE", "PGS_WELL", "PGS_WELL_ID", "CASSETTE", "BACKBONE", "PG_CLONE", "PGS_QC_RESULT", "PGS_QC_RESULT_ID", "PGS_DISTRIBUTE", "PGS_COMMENTS", "EPD", "ES_CELL_LINE", "CELL_LINE_PASSAGE", "EPD_DISTRIBUTE", "TARGETED_TRAP", "EPD_COMMENTS", "FP", "MARKER_SYMBOL", "ENSEMBL_GENE_ID", "VEGA_GENE_ID") AS 
  SELECT DISTINCT
      p.project_id,
      p.is_eucomm eucomm,
      p.is_komp_csd komp,
      p.is_mgp mgp,
      p.is_norcomm norcomm,
      g.mgi_accession_id mgi,
      p.design_plate_name || p.design_well_name design,
      p.design_id,
      p.design_instance_id,
      design.design_type,
      ws.pcs_plate_name pcs_plate,
      ws.pcs_well_name pcs_well,
      pc_clone.data_value pc_clone,
      ws.pc_pass_level pcs_qc_result,
      ws.pc_qctest_result_id pcs_qc_result_id,
      ws.pcs_distribute pcs_distribute,
      pcs_com.data_value pcs_comments,
      ws.pgdgr_plate_name pgs_plate,
      ws.pgdgr_well_name pgs_well,
      ws.pgdgr_well_id pgs_well_id,
      p.cassette,
      p.backbone,
      pg_clone.data_value pg_clone,
      ws.pg_pass_level pgs_qc_result,
      ws.pg_qctest_result_id pgs_qc_result_id,
      ws.pgdgr_distribute pgs_distribute,
      pgs_com.data_value pgs_comments,
      ws.epd_well_name epd,
      regexp_replace(ws.es_cell_line, '^(\S+).*', '\1') es_cell_line,
      substr( regexp_substr(ws.es_cell_line,'[p|P]\\d+'), 2, length( regexp_substr(ws.es_cell_line,'[p|P]\\d+') ) ) cell_line_passage,
      ws.epd_distribute,
      ws.targeted_trap,
      epd_com.data_value epd_comments,
      fp.well_name fp,
      g.marker_symbol,
      g.ensembl_gene_id,
      g.vega_gene_id
    from 
      well_summary_by_di ws
      join project p on p.project_id = ws.project_id
      join mgi_gene g on g.mgi_gene_id = p.mgi_gene_id
      join well fp on fp.parent_well_id = ws.epd_well_id and ( fp.well_name not like 'REPD%' and fp.well_name not like 'RHEPD%' )
      left join well_data pc_clone on pc_clone.well_id = ws.pcs_well_id and pc_clone.data_type = 'clone_name'
      left join well_data pg_clone on pg_clone.well_id = ws.pgdgr_well_id and pg_clone.data_type = 'clone_name'
      left join well_data pcs_com on pcs_com.well_id = ws.pcs_well_id and pcs_com.data_type = 'COMMENTS'
      left join well_data pgs_com on pgs_com.well_id = ws.pgdgr_well_id and pgs_com.data_type = 'COMMENTS'
      left join well_data epd_com on epd_com.well_id = ws.epd_well_id and epd_com.data_type = 'COMMENTS'
      left join design on design.design_id = p.design_id
    where
      p.is_publicly_reported = 1
    order by fp.well_name
;

=head1 AUTHOR(S)

Nelo Onyiah L<io1@sanger.ac.uk>

=cut
