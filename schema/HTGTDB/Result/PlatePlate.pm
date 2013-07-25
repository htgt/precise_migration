use utf8;
package HTGTDB::Result::PlatePlate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::PlatePlate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PLATE_PLATE>

=cut

__PACKAGE__->table("PLATE_PLATE");

=head1 ACCESSORS

=head2 parent_plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 child_plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "parent_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "child_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 RELATIONS

=head2 child_plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "child_plate",
  "HTGTDB::Result::Plate",
  { plate_id => "child_plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 parent_plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "parent_plate",
  "HTGTDB::Result::Plate",
  { plate_id => "parent_plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:26
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XrxGdX0DgOB1gxtdy1G5zQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
