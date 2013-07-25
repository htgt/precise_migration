use utf8;
package HTGTDB::Result::ProjectStaging;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ProjectStaging

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT_STAGING>

=cut

__PACKAGE__->table("PROJECT_STAGING");

=head1 ACCESSORS

=head2 project_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_gene_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 is_publicly_reported

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 computational_gene_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 is_komp_csd

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_komp_regeneron

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_eucomm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_norcomm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_mgp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 status_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

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

=head2 intermediate_vector_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 targeting_vector_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 tmp_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 consensus_method

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 arq_ids

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 mig_gene_ids

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 multiple_mig_gene_ids

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 backbone

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 design_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 design_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 intvec_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 intvec_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 targvec_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 targvec_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 project_status_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 total_colonies

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 colonies_picked

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 epd_distribute

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 bac

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 intvec_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 50

=head2 targvec_pass_level

  data_type: 'varchar2'
  is_nullable: 1
  size: 50

=head2 targvec_distribute

  data_type: 'varchar2'
  is_nullable: 1
  size: 50

=head2 epd_recovered

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_latest_for_gene

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "is_publicly_reported",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "computational_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "is_komp_csd",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_komp_regeneron",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_norcomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_mgp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "status_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
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
  "intermediate_vector_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "targeting_vector_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "tmp_status",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "consensus_method",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "arq_ids",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "mig_gene_ids",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "multiple_mig_gene_ids",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "design_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targvec_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targvec_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "project_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "total_colonies",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "colonies_picked",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_distribute",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "intvec_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "targvec_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "targvec_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "epd_recovered",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_latest_for_gene",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ka2LBivVvaXYN0C5vrXhdg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
