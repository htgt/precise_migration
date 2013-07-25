use utf8;
package HTGTDB::Result::PlateData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::PlateData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PLATE_DATA>

=cut

__PACKAGE__->table("PLATE_DATA");

=head1 ACCESSORS

=head2 plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 data_value

  data_type: 'varchar2'
  is_nullable: 0
  size: 1000

=head2 data_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 plate_data_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_plate_data'
  size: [10,0]

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "data_value",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "data_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "plate_data_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_data",
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</plate_data_id>

=back

=cut

__PACKAGE__->set_primary_key("plate_data_id");

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/RISDi7DspFj42k+w3VtKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
