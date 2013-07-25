use utf8;
package HTGTDB::Result::DaHumanAnnotationStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DaHumanAnnotationStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DA_HUMAN_ANNOTATION_STATUS>

=cut

__PACKAGE__->table("DA_HUMAN_ANNOTATION_STATUS");

=head1 ACCESSORS

=head2 human_annotation_status_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 human_annotation_status_desc

  data_type: 'varchar2'
  is_nullable: 0
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

=head2 edit

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 override

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</human_annotation_status_id>

=back

=cut

__PACKAGE__->set_primary_key("human_annotation_status_id");

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

=head2 da_human_annotations

Type: has_many

Related object: L<HTGTDB::Result::DaHumanAnnotation>

=cut

__PACKAGE__->has_many(
  "da_human_annotations",
  "HTGTDB::Result::DaHumanAnnotation",
  {
    "foreign.human_annotation_status_id" => "self.human_annotation_status_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dk3OBpT3OQCkN3eyrlDqyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
