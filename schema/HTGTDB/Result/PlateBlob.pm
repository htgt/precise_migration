use utf8;
package HTGTDB::Result::PlateBlob;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::PlateBlob

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PLATE_BLOB>

=cut

__PACKAGE__->table("PLATE_BLOB");

=head1 ACCESSORS

=head2 plate_blob_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_plate_blob'
  size: [10,0]

=head2 plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 binary_data

  data_type: 'blob'
  is_nullable: 1

=head2 binary_data_type

  data_type: 'varchar2'
  is_nullable: 0
  size: 1000

=head2 image_thumbnail

  data_type: 'blob'
  is_nullable: 1

=head2 file_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 1000

=head2 file_size

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 is_public

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 edit_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=cut

__PACKAGE__->add_columns(
  "plate_blob_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_blob",
    size => [10, 0],
  },
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "binary_data",
  { data_type => "blob", is_nullable => 1 },
  "binary_data_type",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "image_thumbnail",
  { data_type => "blob", is_nullable => 1 },
  "file_name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "file_size",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "is_public",
  { data_type => "char", is_nullable => 1, size => 1 },
  "edit_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</plate_blob_id>

=back

=cut

__PACKAGE__->set_primary_key("plate_blob_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<plate_blob_uk1>

=over 4

=item * L</plate_blob_id>

=item * L</file_name>

=back

=cut

__PACKAGE__->add_unique_constraint("plate_blob_uk1", ["plate_blob_id", "file_name"]);

=head1 RELATIONS

=head2 plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "HTGTDB::Result::Plate",
  { plate_id => "plate_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PEsA/7PbDW1ZhH75/Z0Xiw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
