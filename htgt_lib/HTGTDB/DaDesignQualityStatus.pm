package HTGTDB::DaDesignQualityStatus;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table("da_design_quality_status");

#__PACKAGE__->add_columns(
#  "design_quality_status_id" => { data_type => 'char', size => 50 },
#  "design_quality_status_desc",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_quality_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "design_quality_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("design_quality_status_id");

__PACKAGE__->has_many( design_annotations => "HTGTDB::DesignAnnotation", 'design_quality_status_id' );
__PACKAGE__->has_many( human_annotations => "HTGTDB::DaHumanAnnotation", 'design_quality_status_id' );
#this won't be the same as the link on human_annotations, 
#these ones are basically used to set the conditions for a human annotation status
__PACKAGE__->has_many( human_annotation_statuses => "HTGTDB::DaHumanAnnotationStatus", 'design_quality_status_id' );

1;
