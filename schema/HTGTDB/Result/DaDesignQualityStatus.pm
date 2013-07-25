use utf8;
package HTGTDB::Result::DaDesignQualityStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DaDesignQualityStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DA_DESIGN_QUALITY_STATUS>

=cut

__PACKAGE__->table("DA_DESIGN_QUALITY_STATUS");

=head1 ACCESSORS

=head2 design_quality_status_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 design_quality_status_desc

  data_type: 'varchar2'
  is_nullable: 0
  size: 4000

=cut

__PACKAGE__->add_columns(
  "design_quality_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "design_quality_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_quality_status_id>

=back

=cut

__PACKAGE__->set_primary_key("design_quality_status_id");

=head1 RELATIONS

=head2 da_human_annotation_statuses

Type: has_many

Related object: L<HTGTDB::Result::DaHumanAnnotationStatus>

=cut

__PACKAGE__->has_many(
  "da_human_annotation_statuses",
  "HTGTDB::Result::DaHumanAnnotationStatus",
  {
    "foreign.design_quality_status_id" => "self.design_quality_status_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 da_human_annotations

Type: has_many

Related object: L<HTGTDB::Result::DaHumanAnnotation>

=cut

__PACKAGE__->has_many(
  "da_human_annotations",
  "HTGTDB::Result::DaHumanAnnotation",
  {
    "foreign.design_quality_status_id" => "self.design_quality_status_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_annotations

Type: has_many

Related object: L<HTGTDB::Result::DesignAnnotation>

=cut

__PACKAGE__->has_many(
  "design_annotations",
  "HTGTDB::Result::DesignAnnotation",
  {
    "foreign.design_quality_status_id" => "self.design_quality_status_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Sa75FgXNL1Cq4RZJ5HR/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
