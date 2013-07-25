package HTGTDB::EnsemblGeneData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::EnsemblGeneData

=cut

__PACKAGE__->table("ensembl_gene_data");

=head1 ACCESSORS

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 ensembl_gene_chromosome

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 ensembl_gene_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 sp

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 tm

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=cut

#__PACKAGE__->add_columns(
#  "ensembl_gene_id",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "ensembl_gene_chromosome",
#  { data_type => "varchar2", is_nullable => 0, size => 100 },
#  "ensembl_gene_start",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ensembl_gene_end",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "ensembl_gene_strand",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "sp",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#  "tm",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [1, 0],
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "ensembl_gene_chromosome",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "ensembl_gene_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "sp",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "tm",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key("ensembl_gene_id");

=head1 RELATIONS

=head2 mgi_ensembl_gene_maps

Type: has_many

Related object: L<HTGTDB::MGIEnsemblGeneMap>

=cut

__PACKAGE__->has_many(
  "mgi_ensembl_gene_maps",
  "HTGTDB::MGIEnsemblGeneMap",
  { "foreign.ensembl_gene_id" => "self.ensembl_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eFPa0HlnC0Xs7hdjn7AStA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
