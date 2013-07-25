use utf8;
package HTGTDB::Result::WellDesignInstanceJump;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::WellDesignInstanceJump

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL_DESIGN_INSTANCE_JUMP>

=cut

__PACKAGE__->table("WELL_DESIGN_INSTANCE_JUMP");

=head1 ACCESSORS

=head2 well_design_instance_jump_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 previous_design_instance_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 previous_parent_well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_timestamp

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 edit_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=cut

__PACKAGE__->add_columns(
  "well_design_instance_jump_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "previous_design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "previous_parent_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_timestamp",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "edit_comment",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_design_instance_jump_id>

=back

=cut

__PACKAGE__->set_primary_key("well_design_instance_jump_id");

=head1 RELATIONS

=head2 previous_design_instance

Type: belongs_to

Related object: L<HTGTDB::Result::DesignInstance>

=cut

__PACKAGE__->belongs_to(
  "previous_design_instance",
  "HTGTDB::Result::DesignInstance",
  { design_instance_id => "previous_design_instance_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 previous_parent_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "previous_parent_well",
  "HTGTDB::Result::Well",
  { well_id => "previous_parent_well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "HTGTDB::Result::Well",
  { well_id => "well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bjB/4XKsBauEk5eUj6wbTw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
