use utf8;
package HTGTDB::Result::DesignFinderGeneStructure;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignFinderGeneStructure

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_FINDER_GENE_STRUCTURE>

=cut

__PACKAGE__->table("DESIGN_FINDER_GENE_STRUCTURE");

=head1 ACCESSORS

=head2 ensembl_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 large_first_exon

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 valid_transcripts

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 symmetrical_exons

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 small_introns

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 number_of_exons

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [3,0]

=head2 ensembl_version

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "ensembl_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "large_first_exon",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "valid_transcripts",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "symmetrical_exons",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "small_introns",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "number_of_exons",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [3, 0],
  },
  "ensembl_version",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</ensembl_version>

=item * L</ensembl_id>

=back

=cut

__PACKAGE__->set_primary_key("ensembl_version", "ensembl_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iQtfnpd3toAJDa+FitMOtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
