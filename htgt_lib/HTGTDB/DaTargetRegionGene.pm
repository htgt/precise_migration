package HTGTDB::DaTargetRegionGene;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table("da_target_region_gene");

#__PACKAGE__->add_columns(
#  "target_region_gene_id",
#  "design_annotation_id",
#  "ensembl_gene_id",
#  "mgi_accession_id",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "target_region_gene_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_da_target_region_gene",
    size => [10, 0],
  },
  "design_annotation_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("target_region_gene_id");
__PACKAGE__->sequence('s_da_target_region_gene');

__PACKAGE__->belongs_to( design_annotation => "HTGTDB::DesignAnnotation", 'design_annotation_id' );

1;
