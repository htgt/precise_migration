use utf8;
package HTGTDB::Result::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Annotation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ANNOTATION>

=cut

__PACKAGE__->table("ANNOTATION");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_annotation'
  size: [10,0]

=head2 gb_gene_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 seq_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 result_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 class

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 chr

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 gene

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 strand

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 known

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 ensembl

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 refseq

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 swissprot

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 sptrembl

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 gene_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 gene_end

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 exon_or_intron

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 exon_or_intron_start

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 exon_or_intron_end

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

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

=head2 hit_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 origin

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 score

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_annotation",
    size => [10, 0],
  },
  "gb_gene_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "seq_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "result_type",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "class",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "chr",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "gene",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "strand",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "known",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "ensembl",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "refseq",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "swissprot",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "sptrembl",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "gene_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "gene_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "exon_or_intron",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "exon_or_intron_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "exon_or_intron_end",
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
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "hit_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "origin",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "score",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 RELATIONS

=head2 seq

Type: belongs_to

Related object: L<HTGTDB::Result::SequenceTag>

=cut

__PACKAGE__->belongs_to(
  "seq",
  "HTGTDB::Result::SequenceTag",
  { seq_id => "seq_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DxbEPjkCf1FCv1WiAwHYOg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
