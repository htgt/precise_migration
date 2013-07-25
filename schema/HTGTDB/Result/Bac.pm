use utf8;
package HTGTDB::Result::Bac;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Bac

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<BAC>

=cut

__PACKAGE__->table("BAC");

=head1 ACCESSORS

=head2 bac_clone_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_93_1_bac'
  size: [10,0]

=head2 remote_clone_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=head2 clone_lib_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 chr_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 bac_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 bac_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 bac_midpoint

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 build_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "bac_clone_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_93_1_bac",
    size => [10, 0],
  },
  "remote_clone_id",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "clone_lib_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_midpoint",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "build_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</bac_clone_id>

=back

=cut

__PACKAGE__->set_primary_key("bac_clone_id");

=head1 RELATIONS

=head2 build

Type: belongs_to

Related object: L<HTGTDB::Result::BuildInfo>

=cut

__PACKAGE__->belongs_to(
  "build",
  "HTGTDB::Result::BuildInfo",
  { build_id => "build_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 chr

Type: belongs_to

Related object: L<HTGTDB::Result::ChromosomeDict>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "HTGTDB::Result::ChromosomeDict",
  { chr_id => "chr_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 clone_lib

Type: belongs_to

Related object: L<HTGTDB::Result::CloneLibDict>

=cut

__PACKAGE__->belongs_to(
  "clone_lib",
  "HTGTDB::Result::CloneLibDict",
  { clone_lib_id => "clone_lib_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_bacs

Type: has_many

Related object: L<HTGTDB::Result::DesignBac>

=cut

__PACKAGE__->has_many(
  "design_bacs",
  "HTGTDB::Result::DesignBac",
  { "foreign.bac_clone_id" => "self.bac_clone_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_instance_bacs

Type: has_many

Related object: L<HTGTDB::Result::DesignInstanceBac>

=cut

__PACKAGE__->has_many(
  "design_instance_bacs",
  "HTGTDB::Result::DesignInstanceBac",
  { "foreign.bac_clone_id" => "self.bac_clone_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tvLvSuxp5sRp6c8a7qUFDA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
