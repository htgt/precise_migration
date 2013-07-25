use utf8;
package HTGTDB::Result::WellData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::WellData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL_DATA>

=cut

__PACKAGE__->table("WELL_DATA");

=head1 ACCESSORS

=head2 data_value

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 well_data_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_well_data'
  size: [10,0]

=head2 data_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=cut

__PACKAGE__->add_columns(
  "data_value",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "well_data_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_well_data",
    size => [10, 0],
  },
  "data_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_data_id>

=back

=cut

__PACKAGE__->set_primary_key("well_data_id");

=head1 RELATIONS

=head2 well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "HTGTDB::Result::Well",
  { well_id => "well_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G2++0WyEkIE5gGoaqEIy0A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
