use utf8;
package HTGTDB::Result::DesignInstance;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignInstance

=head1 DESCRIPTION

An instance of a design. Construction of a design can be attempted multiple times in different plate/well positions and or using a different BAC.

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_INSTANCE>

=cut

__PACKAGE__->table("DESIGN_INSTANCE");

=head1 ACCESSORS

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

unique id for a design

=head2 plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

id for the plate this instance is on

=head2 well

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

well location for this design instance

=head2 source

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

who is constructing this design_instance

=head2 design_instance_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_design_instance'
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "plate",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "well",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "source",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "design_instance_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_instance",
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_instance_id>

=back

=cut

__PACKAGE__->set_primary_key("design_instance_id");

=head1 RELATIONS

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_instance_bacs

Type: has_many

Related object: L<HTGTDB::Result::DesignInstanceBac>

=cut

__PACKAGE__->has_many(
  "design_instance_bacs",
  "HTGTDB::Result::DesignInstanceBac",
  { "foreign.design_instance_id" => "self.design_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_instance_features

Type: has_many

Related object: L<HTGTDB::Result::DesignInstanceFeature>

=cut

__PACKAGE__->has_many(
  "design_instance_features",
  "HTGTDB::Result::DesignInstanceFeature",
  { "foreign.design_instance_id" => "self.design_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summaries

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summaries",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.design_instance_id" => "self.design_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 projects

Type: has_many

Related object: L<HTGTDB::Result::Project>

=cut

__PACKAGE__->has_many(
  "projects",
  "HTGTDB::Result::Project",
  { "foreign.design_instance_id" => "self.design_instance_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_design_instance_jumps

Type: has_many

Related object: L<HTGTDB::Result::WellDesignInstanceJump>

=cut

__PACKAGE__->has_many(
  "well_design_instance_jumps",
  "HTGTDB::Result::WellDesignInstanceJump",
  {
    "foreign.previous_design_instance_id" => "self.design_instance_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8RZB1ci9IjQKC9eLGR7nug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
