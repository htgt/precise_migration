use utf8;
package HTGTDB::Result::ToadPlanTable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ToadPlanTable

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<TOAD_PLAN_TABLE>

=cut

__PACKAGE__->table("TOAD_PLAN_TABLE");

=head1 ACCESSORS

=head2 statement_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 32

=head2 timestamp

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 remarks

  data_type: 'varchar2'
  is_nullable: 1
  size: 80

=head2 operation

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 options

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 object_node

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 object_owner

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 object_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 object_instance

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 object_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 search_columns

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 cost

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 parent_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 position

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 cardinality

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 optimizer

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 bytes

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 other_tag

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 partition_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 partition_start

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 partition_stop

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 distribution

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 other

  data_type: 'long'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "statement_id",
  { data_type => "varchar2", is_nullable => 1, size => 32 },
  "timestamp",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "remarks",
  { data_type => "varchar2", is_nullable => 1, size => 80 },
  "operation",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "options",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "object_node",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "object_owner",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "object_name",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "object_instance",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "object_type",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "search_columns",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "cost",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "parent_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "position",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "cardinality",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "optimizer",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "bytes",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "other_tag",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "partition_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "partition_start",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "partition_stop",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "distribution",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "other",
  { data_type => "long", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iTIf3LYINbrKhnqlHa2YIA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
