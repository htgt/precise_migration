package HTGTDB::DesignFinderGeneStructure;

use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_finder_gene_structure');

#__PACKAGE__->add_columns(
#    qw/
#        ensembl_id
#        large_first_exon
#        valid_transcripts
#        symmetrical_exons
#        small_introns
#        number_of_exons
#        ensembl_version
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
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
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( qw/ ensembl_id ensembl_version / );


1;
