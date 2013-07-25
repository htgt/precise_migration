use utf8;
package HTGTDB::Result::Hit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Hit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<HIT>

=cut

__PACKAGE__->table("HIT");

=head1 ACCESSORS

=head2 hit_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_110_1_hit'
  size: [10,0]

=head2 blast_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 query_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 query_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 hit_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 hit_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 query_strand

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 hit_strand

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 query_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 hit_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 percent_identity

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 evalue

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "hit_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_110_1_hit",
    size => [10, 0],
  },
  "blast_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "hit_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "hit_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_strand",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "hit_strand",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "query_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "hit_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "percent_identity",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "evalue",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</hit_id>

=back

=cut

__PACKAGE__->set_primary_key("hit_id");

=head1 RELATIONS

=head2 blast

Type: belongs_to

Related object: L<HTGTDB::Result::FeatureBlast>

=cut

__PACKAGE__->belongs_to(
  "blast",
  "HTGTDB::Result::FeatureBlast",
  { blast_id => "blast_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HIYFfy9MO6zdAa8R0G+NJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
