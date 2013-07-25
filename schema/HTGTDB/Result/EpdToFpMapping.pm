use utf8;
package HTGTDB::Result::EpdToFpMapping;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::EpdToFpMapping

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<EPD_TO_FP_MAPPINGS>

=cut

__PACKAGE__->table("EPD_TO_FP_MAPPINGS");

=head1 ACCESSORS

=head2 fp_well_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 fp_plate_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 fp_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 parent_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 parent_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=cut

__PACKAGE__->add_columns(
  "fp_well_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "fp_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "fp_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "parent_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "parent_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8qSBjAJKBKjOfMrmZL/1gw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
