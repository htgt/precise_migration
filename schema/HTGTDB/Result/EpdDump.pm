use utf8;
package HTGTDB::Result::EpdDump;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::EpdDump

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<EPD_DUMP>

=cut

__PACKAGE__->table("EPD_DUMP");

=head1 ACCESSORS

=head2 project_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 eucomm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 komp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 mgp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 norcomm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 mgi

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 design

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=head2 design_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 pcs_plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_well

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 pc_clone

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 pcs_qc_result

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_qc_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 pcs_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pcs_comments

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 pgs_plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgs_well

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 pgs_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 backbone

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 pg_clone

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 pgs_qc_result

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgs_qc_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 pgs_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 pgs_comments

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 epd

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 es_cell_line

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 cell_line_passage

  data_type: 'varchar2'
  is_nullable: 1
  size: 99

=head2 epd_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 targeted_trap

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 epd_comments

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 fp

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 vega_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=cut

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r3rffA6YJ4XtBqvP2gCaeg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
