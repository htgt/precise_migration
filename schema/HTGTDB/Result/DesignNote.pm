use utf8;
package HTGTDB::Result::DesignNote;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignNote

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_NOTE>

=cut

__PACKAGE__->table("DESIGN_NOTE");

=head1 ACCESSORS

=head2 design_note_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_100_1_design_note'
  size: [10,0]

=head2 design_note_type_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 note

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 created

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "design_note_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_100_1_design_note",
    size => [10, 0],
  },
  "design_note_type_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "created",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_note_id>

=back

=cut

__PACKAGE__->set_primary_key("design_note_id");

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

=head2 design_note_type

Type: belongs_to

Related object: L<HTGTDB::Result::DesignNoteTypeDict>

=cut

__PACKAGE__->belongs_to(
  "design_note_type",
  "HTGTDB::Result::DesignNoteTypeDict",
  { design_note_type_id => "design_note_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LRkjMSJ6ReAmlxc9ShdZmA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
