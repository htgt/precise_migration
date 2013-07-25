use utf8;
package HTGTDB::Result::Project;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Project

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT>

=cut

__PACKAGE__->table("PROJECT");

=head1 ACCESSORS

=head2 project_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_project'
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

=head2 design_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_foreign_key: 1
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
  default_value: 0
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

=head2 is_trap

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_eutracc

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 targeted_trap

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 vector_only

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 esc_only

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_eucomm_tools

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_switch

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_eucomm_tools_cre

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 status_change_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 is_tpp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_mgp_bespoke

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 phenotype_url

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 distribution_centre_url

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_project",
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
    is_foreign_key => 1,
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
    default_value => 0,
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
  "is_trap",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eutracc",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "targeted_trap",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vector_only",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "esc_only",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm_tools",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_switch",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_eucomm_tools_cre",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "status_change_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "is_tpp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_mgp_bespoke",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "phenotype_url",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "distribution_centre_url",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_id>

=back

=cut

__PACKAGE__->set_primary_key("project_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<project_uk>

=over 4

=item * L</design_instance_id>

=item * L</cassette>

=item * L</backbone>

=item * L</is_norcomm>

=item * L</is_komp_regeneron>

=item * L</design_id>

=item * L</is_trap>

=item * L</is_eutracc>

=item * L</vector_only>

=item * L</mgi_gene_id>

=item * L</esc_only>

=item * L</is_komp_csd>

=item * L</is_eucomm>

=item * L</is_mgp>

=item * L</is_eucomm_tools>

=item * L</is_switch>

=item * L</is_eucomm_tools_cre>

=item * L</is_tpp>

=item * L</is_mgp_bespoke>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "project_uk",
  [
    "design_instance_id",
    "cassette",
    "backbone",
    "is_norcomm",
    "is_komp_regeneron",
    "design_id",
    "is_trap",
    "is_eutracc",
    "vector_only",
    "mgi_gene_id",
    "esc_only",
    "is_komp_csd",
    "is_eucomm",
    "is_mgp",
    "is_eucomm_tools",
    "is_switch",
    "is_eucomm_tools_cre",
    "is_tpp",
    "is_mgp_bespoke",
  ],
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 new_well_summaries

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summaries",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 primer_band_size

Type: might_have

Related object: L<HTGTDB::Result::PrimerBandSize>

=cut

__PACKAGE__->might_have(
  "primer_band_size",
  "HTGTDB::Result::PrimerBandSize",
  { "foreign.project_id" => "self.project_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DE61i3epEBN2jU9GKUX9hg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
