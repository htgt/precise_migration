use utf8;
package HTGTDB::Result::Source;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Source

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<SOURCE>

=cut

__PACKAGE__->table("SOURCE");

=head1 ACCESSORS

=head2 source_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_source'
  size: [10,0]

=head2 update_method_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 update_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 location_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 function_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "source_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_source",
    size => [10, 0],
  },
  "update_method_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "update_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "location_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "function_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</source_id>

=back

=cut

__PACKAGE__->set_primary_key("source_id");

=head1 RELATIONS

=head2 function

Type: belongs_to

Related object: L<HTGTDB::Result::DataFunction>

=cut

__PACKAGE__->belongs_to(
  "function",
  "HTGTDB::Result::DataFunction",
  { function_id => "function_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 location

Type: belongs_to

Related object: L<HTGTDB::Result::Location>

=cut

__PACKAGE__->belongs_to(
  "location",
  "HTGTDB::Result::Location",
  { location_id => "location_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 sequence_tags

Type: has_many

Related object: L<HTGTDB::Result::SequenceTag>

=cut

__PACKAGE__->has_many(
  "sequence_tags",
  "HTGTDB::Result::SequenceTag",
  { "foreign.source_id" => "self.source_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 update_method

Type: belongs_to

Related object: L<HTGTDB::Result::UpdateMethod>

=cut

__PACKAGE__->belongs_to(
  "update_method",
  "HTGTDB::Result::UpdateMethod",
  { update_method_id => "update_method_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 update_rel

Type: belongs_to

Related object: L<HTGTDB::Result::UpdateFrequency>

=cut

__PACKAGE__->belongs_to(
  "update_rel",
  "HTGTDB::Result::UpdateFrequency",
  { update_id => "update_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:J4WHOlqpEug4PX+9wKdp0A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
