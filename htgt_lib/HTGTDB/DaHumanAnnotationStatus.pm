package HTGTDB::DaHumanAnnotationStatus;
use strict;
use warnings;


use base 'DBIx::Class';
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table("da_human_annotation_status");


#__PACKAGE__->add_columns(
#  'human_annotation_status_id' => { data_type => 'char', size => 50 },
#  'human_annotation_status_desc',
#  'design_quality_status_id'     => { data_type => 'char', size => 50, is_foreign_key => 1 },
#  'oligo_status_id'              => { data_type => 'char', size => 50, is_foreign_key => 1 },
#  'target_region_status_id'      => { data_type => 'char', size => 50, is_foreign_key => 1 },
#  'artificial_intron_status_id'  => { data_type => 'char', size => 50, is_foreign_key => 1 },
#  'edit',
#  'override',
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "human_annotation_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "human_annotation_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
  "design_quality_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "oligo_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "target_region_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "artificial_intron_status_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 1, size => 50 },
  "edit",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "override",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("human_annotation_status_id");

__PACKAGE__->has_many( human_annotations => "HTGTDB::DaHumanAnnotation", 'human_annotation_status_id' );

__PACKAGE__->belongs_to( design_quality_status    => 'HTGTDB::DaDesignQualityStatus', 'design_quality_status_id' );
__PACKAGE__->belongs_to( oligo_status             => 'HTGTDB::DaOligoStatus', 'oligo_status_id' );
__PACKAGE__->belongs_to( target_region_status     => 'HTGTDB::DaTargetRegionStatus', 'target_region_status_id' );
__PACKAGE__->belongs_to( artificial_intron_status => 'HTGTDB::DaArtificialIntronStatus', 'artificial_intron_status_id' );

1;
