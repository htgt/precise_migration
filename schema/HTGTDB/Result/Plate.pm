use utf8;
package HTGTDB::Result::Plate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Plate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PLATE>

=cut

__PACKAGE__->table("PLATE");

=head1 ACCESSORS

=head2 plate_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_plate'
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 created_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 created_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 edited_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edited_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 is_locked

  data_type: 'char'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate",
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "edited_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edited_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "is_locked",
  { data_type => "char", is_nullable => 1, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</plate_id>

=back

=cut

__PACKAGE__->set_primary_key("plate_id");

=head1 RELATIONS

=head2 plate_blobs

Type: has_many

Related object: L<HTGTDB::Result::PlateBlob>

=cut

__PACKAGE__->has_many(
  "plate_blobs",
  "HTGTDB::Result::PlateBlob",
  { "foreign.plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_comments

Type: has_many

Related object: L<HTGTDB::Result::PlateComment>

=cut

__PACKAGE__->has_many(
  "plate_comments",
  "HTGTDB::Result::PlateComment",
  { "foreign.plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_datas

Type: has_many

Related object: L<HTGTDB::Result::PlateData>

=cut

__PACKAGE__->has_many(
  "plate_datas",
  "HTGTDB::Result::PlateData",
  { "foreign.plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_plate_child_plates

Type: has_many

Related object: L<HTGTDB::Result::PlatePlate>

=cut

__PACKAGE__->has_many(
  "plate_plate_child_plates",
  "HTGTDB::Result::PlatePlate",
  { "foreign.child_plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate_plate_parent_plates

Type: has_many

Related object: L<HTGTDB::Result::PlatePlate>

=cut

__PACKAGE__->has_many(
  "plate_plate_parent_plates",
  "HTGTDB::Result::PlatePlate",
  { "foreign.parent_plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_runs

Type: has_many

Related object: L<HTGTDB::Result::QcRun>

=cut

__PACKAGE__->has_many(
  "qc_runs",
  "HTGTDB::Result::QcRun",
  { "foreign.template_plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 wells

Type: has_many

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->has_many(
  "wells",
  "HTGTDB::Result::Well",
  { "foreign.plate_id" => "self.plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XNxssJk0T4gZ65JD9p6GIQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
