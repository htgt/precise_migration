use utf8;
package HTGTDB::Result::WellSummaryT;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::WellSummaryT

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL_SUMMARY_T>

=cut

__PACKAGE__->table("WELL_SUMMARY_T");

=head1 ACCESSORS

=head2 build_gene_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 gene_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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
  size: 126

=head2 design_design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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
  size: 126

=head2 pcs_design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 pc_qctest_result_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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
  size: 126

=head2 pgdgr_design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 pg_qctest_result_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

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
  size: 126

=head2 ep_design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 es_cell_line

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 colonies_picked

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

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

=head2 epd_design_instance_id

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

=head2 project_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "build_gene_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "gene_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
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
    size => 126,
  },
  "design_design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
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
    size => 126,
  },
  "pcs_design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "pc_qctest_result_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
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
    size => 126,
  },
  "pgdgr_design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "pg_qctest_result_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
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
    size => 126,
  },
  "ep_design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "colonies_picked",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
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
  "epd_design_instance_id",
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
  "project_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xaBc38mIsU1Tdr16Fg//sg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
