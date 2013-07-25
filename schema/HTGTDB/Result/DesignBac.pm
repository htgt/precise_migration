use utf8;
package HTGTDB::Result::DesignBac;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignBac

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_BAC>

=cut

__PACKAGE__->table("DESIGN_BAC");

=head1 ACCESSORS

=head2 bac_clone_id

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

=head2 midpoint_diff

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 allocate_to_instance

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "bac_clone_id",
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
  "midpoint_diff",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "allocate_to_instance",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 RELATIONS

=head2 bac_clone

Type: belongs_to

Related object: L<HTGTDB::Result::Bac>

=cut

__PACKAGE__->belongs_to(
  "bac_clone",
  "HTGTDB::Result::Bac",
  { bac_clone_id => "bac_clone_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VA2JKEyf07/AB/lB4uXa7A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
