package HTGTDB::DaHumanAnnotation;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table("da_human_annotation");

#__PACKAGE__->add_columns(
#  "human_annotation_id",
#  "design_annotation_id",
#  "human_annotation_status_id",
#  "human_annotation_status_notes",
#  "design_quality_status_id",
#  "oligo_status_id",
#  "target_region_status_id",
#  "artificial_intron_status_id",
#  "design_check_status_notes",
#  "is_forced",
#  "created_by",
#  "created_at",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "human_annotation_id",
  {
#    data_type => "numeric",
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_da_human_annotation",
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
  "human_annotation_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 255 },
  "human_annotation_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "design_quality_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "oligo_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "target_region_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "artificial_intron_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "design_check_status_notes",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "is_forced",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "created_by",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "created_at",
  {
    data_type     => "datetime",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("human_annotation_id");
__PACKAGE__->sequence('s_da_human_annotation');

__PACKAGE__->belongs_to( design_annotation        => "HTGTDB::DesignAnnotation", 'design_annotation_id' );
__PACKAGE__->belongs_to( human_annotation_status  => "HTGTDB::DaHumanAnnotationStatus", 'human_annotation_status_id' );
__PACKAGE__->belongs_to( design_quality_status    => "HTGTDB::DaDesignQualityStatus", 'design_quality_status_id' );
__PACKAGE__->belongs_to( oligo_status             => "HTGTDB::DaOligoStatus", 'oligo_status_id' );
__PACKAGE__->belongs_to( target_region_status     => "HTGTDB::DaTargetRegionStatus", 'target_region_status_id' );
__PACKAGE__->belongs_to( artificial_intron_status => "HTGTDB::DaArtificialIntronStatus", 'artificial_intron_status_id' );

1;
