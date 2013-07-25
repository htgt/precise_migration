use utf8;
package HTGTDB::Result::VegaGeneData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::VegaGeneData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<VEGA_GENE_DATA>

=cut

__PACKAGE__->table("VEGA_GENE_DATA");

=head1 ACCESSORS

=head2 vega_gene_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 vega_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 vega_gene_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 vega_gene_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "vega_gene_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "vega_gene_chromosome",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "vega_gene_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vega_gene_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "vega_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</vega_gene_id>

=back

=cut

__PACKAGE__->set_primary_key("vega_gene_id");

=head1 RELATIONS

=head2 mgi_vega_gene_maps

Type: has_many

Related object: L<HTGTDB::Result::MgiVegaGeneMap>

=cut

__PACKAGE__->has_many(
  "mgi_vega_gene_maps",
  "HTGTDB::Result::MgiVegaGeneMap",
  { "foreign.vega_gene_id" => "self.vega_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mgi_accessions

Type: many_to_many

Composing rels: L</mgi_vega_gene_maps> -> mgi_accession

=cut

__PACKAGE__->many_to_many("mgi_accessions", "mgi_vega_gene_maps", "mgi_accession");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:34EyoF55gjeSGov6IRbkrw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
