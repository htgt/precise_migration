use utf8;
package HTGTDB::Result::NewWellSummary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::NewWellSummary

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<NEW_WELL_SUMMARY>

=cut

__PACKAGE__->table("NEW_WELL_SUMMARY");

=head1 ACCESSORS

=head2 mgi_gene_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 project_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 design_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 design_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 design_well_id

  data_type: 'numeric'
  is_foreign_key: 1
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
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 pcs_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

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

=head2 pgdgr_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 pgdgr_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 pgdgr_well_id

  data_type: 'numeric'
  is_foreign_key: 1
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

=head2 pgdgr_clone_name

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

=head2 dna_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 dna_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 dna_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 dna_well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 dna_qctest_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 dna_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 dna_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 dna_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ep_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ep_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 ep_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 ep_well_id

  data_type: 'numeric'
  is_foreign_key: 1
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

=head2 epd_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 epd_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 epd_well_id

  data_type: 'numeric'
  is_foreign_key: 1
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

=head2 fp_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 fp_plate_created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 fp_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 fp_well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 epd_five_arm_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_three_arm_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_loxp_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 primary_key_for_dbix_class

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "project_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "design_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "design_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
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
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pcs_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
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
  "pgdgr_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "pgdgr_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pgdgr_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
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
  "pgdgr_clone_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "dna_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "dna_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "dna_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "ep_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "ep_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
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
  "epd_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "epd_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "epd_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
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
  "fp_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "fp_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "fp_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "fp_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_five_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_three_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_loxp_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "primary_key_for_dbix_class",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 RELATIONS

=head2 design_instance

Type: belongs_to

Related object: L<HTGTDB::Result::DesignInstance>

=cut

__PACKAGE__->belongs_to(
  "design_instance",
  "HTGTDB::Result::DesignInstance",
  { design_instance_id => "design_instance_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "design_well",
  "HTGTDB::Result::Well",
  { well_id => "design_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 dna_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "dna_well",
  "HTGTDB::Result::Well",
  { well_id => "dna_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 ep_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "ep_well",
  "HTGTDB::Result::Well",
  { well_id => "ep_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 epd_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "epd_well",
  "HTGTDB::Result::Well",
  { well_id => "epd_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 fp_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "fp_well",
  "HTGTDB::Result::Well",
  { well_id => "fp_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 mgi_gene

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneIdMap>

=cut

__PACKAGE__->belongs_to(
  "mgi_gene",
  "HTGTDB::Result::MgiGeneIdMap",
  { mgi_gene_id => "mgi_gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 pc_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "pc_well",
  "HTGTDB::Result::Well",
  { well_id => "pcs_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 pgdgr_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "pgdgr_well",
  "HTGTDB::Result::Well",
  { well_id => "pgdgr_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 project

Type: belongs_to

Related object: L<HTGTDB::Result::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "HTGTDB::Result::Project",
  { project_id => "project_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pl1EUi1CHDGzHAe/QMDIJA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
