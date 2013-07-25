use utf8;
package HTGTDB::Result::DaHumanAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DaHumanAnnotation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DA_HUMAN_ANNOTATION>

=cut

__PACKAGE__->table("DA_HUMAN_ANNOTATION");

=head1 ACCESSORS

=head2 human_annotation_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_da_human_annotation'
  size: [10,0]

=head2 design_annotation_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 human_annotation_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 255

=head2 human_annotation_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 design_quality_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 oligo_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 target_region_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 artificial_intron_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 design_check_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 is_forced

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 created_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 created_at

  data_type: 'timestamp'
  default_value: systimestamp
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "human_annotation_id",
  {
    data_type => "numeric",
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
    data_type     => "timestamp",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</human_annotation_id>

=back

=cut

__PACKAGE__->set_primary_key("human_annotation_id");

=head1 RELATIONS

=head2 artificial_intron_status

Type: belongs_to

Related object: L<HTGTDB::Result::DaArtificialIntronStatus>

=cut

__PACKAGE__->belongs_to(
  "artificial_intron_status",
  "HTGTDB::Result::DaArtificialIntronStatus",
  { artificial_intron_status_id => "artificial_intron_status_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 design_annotation

Type: belongs_to

Related object: L<HTGTDB::Result::DesignAnnotation>

=cut

__PACKAGE__->belongs_to(
  "design_annotation",
  "HTGTDB::Result::DesignAnnotation",
  { design_annotation_id => "design_annotation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_quality_status

Type: belongs_to

Related object: L<HTGTDB::Result::DaDesignQualityStatus>

=cut

__PACKAGE__->belongs_to(
  "design_quality_status",
  "HTGTDB::Result::DaDesignQualityStatus",
  { design_quality_status_id => "design_quality_status_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 human_annotation_status

Type: belongs_to

Related object: L<HTGTDB::Result::DaHumanAnnotationStatus>

=cut

__PACKAGE__->belongs_to(
  "human_annotation_status",
  "HTGTDB::Result::DaHumanAnnotationStatus",
  { human_annotation_status_id => "human_annotation_status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 oligo_status

Type: belongs_to

Related object: L<HTGTDB::Result::DaOligoStatus>

=cut

__PACKAGE__->belongs_to(
  "oligo_status",
  "HTGTDB::Result::DaOligoStatus",
  { oligo_status_id => "oligo_status_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 target_region_status

Type: belongs_to

Related object: L<HTGTDB::Result::DaTargetRegionStatus>

=cut

__PACKAGE__->belongs_to(
  "target_region_status",
  "HTGTDB::Result::DaTargetRegionStatus",
  { target_region_status_id => "target_region_status_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CkkFeV1du7c9HguYmkvjuw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
