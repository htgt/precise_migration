package HTGTDB::VegaGeneData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::VegaGeneData

=cut

__PACKAGE__->table("vega_gene_data");

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

#__PACKAGE__->add_columns(
#  "vega_gene_id",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "vega_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "vega_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "vega_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "vega_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
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
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key("vega_gene_id");

=head1 RELATIONS

=head2 mgi_vega_gene_maps

Type: has_many

Related object: L<HTGTDB::MGIVegaGeneMap>

=cut

__PACKAGE__->has_many(
  "mgi_vega_gene_maps",
  "HTGTDB::MGIVegaGeneMap",
  { "foreign.vega_gene_id" => "self.vega_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4VzL6szhLYi5Duu8aNiW0A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
