use utf8;
package HTGTDB::Result::DisplayExon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DisplayExon

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DISPLAY_EXON>

=cut

__PACKAGE__->table("DISPLAY_EXON");

=head1 ACCESSORS

=head2 display_exon_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_stable_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 ensembl_transcript_stable_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 ensembl_exon_stable_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 chr_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 chr_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 chr_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 chr_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 ensembl_version

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 created_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 revision

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [2,0]

=cut

__PACKAGE__->add_columns(
  "display_exon_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_transcript_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_exon_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "chr_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "chr_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "ensembl_version",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "revision",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [2, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</display_exon_id>

=back

=cut

__PACKAGE__->set_primary_key("display_exon_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/gb/UP08HvqGD1CYVsl4TA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
