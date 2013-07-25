use utf8;
package HTGTDB::Result::Target;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Target

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<TARGET>

=cut

__PACKAGE__->table("TARGET");

=head1 ACCESSORS

=head2 target_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_111_1_target'
  size: [10,0]

=head2 gene_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 locus_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 chr_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_start

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_end

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_midpoint

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 strand

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 phase

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 end_phase

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 exon_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=cut

__PACKAGE__->add_columns(
  "target_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_111_1_target",
    size => [10, 0],
  },
  "gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "locus_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_start",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_end",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_midpoint",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "strand",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "phase",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "end_phase",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "exon_id",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
);

=head1 PRIMARY KEY

=over 4

=item * L</target_id>

=back

=cut

__PACKAGE__->set_primary_key("target_id");

=head1 RELATIONS

=head2 chr

Type: belongs_to

Related object: L<HTGTDB::Result::ChromosomeDict>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "HTGTDB::Result::ChromosomeDict",
  { chr_id => "chr_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 gene

Type: belongs_to

Related object: L<HTGTDB::Result::EucommGene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "HTGTDB::Result::EucommGene",
  { gene_id => "gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fyj1RwCb/2sCbyiZPhNn7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
