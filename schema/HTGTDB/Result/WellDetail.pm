use utf8;
package HTGTDB::Result::WellDetail;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::WellDetail

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL_DETAIL>

=cut

__PACKAGE__->table("WELL_DETAIL");

=head1 ACCESSORS

=head2 well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 parent_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 plate_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 plate_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 backbone

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 qctest_result_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 colonies_picked

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 total_colonies

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 dna_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 targeted_trap

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 allele_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 clone_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 well_es_cell_line

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 well_sponsor

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 five_arm_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 three_arm_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 loxp_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 bacs

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 plate_es_cell_line

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 plate_sponsor

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=cut

__PACKAGE__->add_columns(
  "well_id",
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
  "well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "parent_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "plate_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "plate_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "distribute",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "qctest_result_id",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "colonies_picked",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "total_colonies",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "dna_status",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "allele_name",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "clone_name",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_sponsor",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "five_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "three_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "loxp_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "bacs",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "plate_es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "plate_sponsor",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NVmAtp7JcHMMMq9lRKC8RA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
