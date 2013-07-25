use utf8;
package HTGTDB::Result::NewWellSummaryByDi;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::NewWellSummaryByDi

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<NEW_WELL_SUMMARY_BY_DI>

=cut

__PACKAGE__->table("NEW_WELL_SUMMARY_BY_DI");

=head1 ACCESSORS

=head2 project_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 build_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 0

=head2 gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 0

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 design_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 design_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 bac

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 pcs_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 pc_qctest_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 pc_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgdgr_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgdgr_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 pgdgr_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 pg_qctest_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 pg_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 backbone

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgdgr_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ep_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ep_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 ep_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 es_cell_line

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 colonies_picked

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 total_colonies

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 epd_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 epd_qctest_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 epd_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 targeted_trap

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 allele_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 160

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "build_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 0 },
  "gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 0 },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "design_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pcs_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pc_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pc_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pgdgr_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pg_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pg_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "ep_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "colonies_picked",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "total_colonies",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "epd_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "epd_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "allele_name",
  { data_type => "varchar2", is_nullable => 1, size => 160 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+FIxVIEA4+xugcX9Dzo5Yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
