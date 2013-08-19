package HTGTDB::DesignAnnotation;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table("design_annotation");

#__PACKAGE__->add_columns(
#  "design_annotation_id",
#  "design_id",
#  "assembly_id",
#  "build_id",
#  "oligo_status_id",
#  "oligo_status_notes",
#  "target_region_status_id",
#  "target_region_status_notes",
#  "design_quality_status_id",
#  "design_quality_status_notes",
#  "artificial_intron_status_id",
#  "artificial_intron_status_notes",
#  "target_gene",
#  "final_status_id",
#  "edited_date",
#  "edited_by",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_annotation_id",
  {
#    data_type => "numeric",
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_annotation",
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "assembly_id",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "build_id",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "oligo_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "oligo_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "target_region_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "target_region_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "design_quality_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "design_quality_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "artificial_intron_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "artificial_intron_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "target_gene",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "final_status_id",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "edited_date",
  {
    data_type     => "datetime",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("design_annotation_id");
__PACKAGE__->sequence('s_design_annotation');

__PACKAGE__->has_many( target_region_genes => "HTGTDB::DaTargetRegionGene", 'design_annotation_id' );
__PACKAGE__->has_many( human_annotations => "HTGTDB::DaHumanAnnotation", 'design_annotation_id' );

__PACKAGE__->belongs_to( oligo_status             => "HTGTDB::DaOligoStatus", 'oligo_status_id' );
__PACKAGE__->belongs_to( target_region_status     => "HTGTDB::DaTargetRegionStatus", 'target_region_status_id' );
__PACKAGE__->belongs_to( design_quality_status    => "HTGTDB::DaDesignQualityStatus", 'design_quality_status_id' );
__PACKAGE__->belongs_to( artificial_intron_status => "HTGTDB::DaArtificialIntronStatus", 'artificial_intron_status_id' );
__PACKAGE__->belongs_to( design                   => "HTGTDB::Design", 'design_id' );

1;
