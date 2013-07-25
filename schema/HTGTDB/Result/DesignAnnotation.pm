use utf8;
package HTGTDB::Result::DesignAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignAnnotation

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_ANNOTATION>

=cut

__PACKAGE__->table("DESIGN_ANNOTATION");

=head1 ACCESSORS

=head2 design_annotation_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_design_annotation'
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 assembly_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 build_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 oligo_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 oligo_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 target_region_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 target_region_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 design_quality_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 design_quality_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 artificial_intron_status_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 1
  size: 50

=head2 artificial_intron_status_notes

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 target_gene

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 final_status_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 50

=head2 edited_date

  data_type: 'timestamp'
  default_value: systimestamp
  is_nullable: 1

=head2 edited_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=cut

__PACKAGE__->add_columns(
  "design_annotation_id",
  {
    data_type => "numeric",
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
    data_type     => "timestamp",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_annotation_id>

=back

=cut

__PACKAGE__->set_primary_key("design_annotation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_id_assembly_build>

=over 4

=item * L</design_id>

=item * L</assembly_id>

=item * L</build_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "design_id_assembly_build",
  ["design_id", "assembly_id", "build_id"],
);

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
  { "foreign.design_annotation_id" => "self.design_annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 da_target_region_genes

Type: has_many

Related object: L<HTGTDB::Result::DaTargetRegionGene>

=cut

__PACKAGE__->has_many(
  "da_target_region_genes",
  "HTGTDB::Result::DaTargetRegionGene",
  { "foreign.design_annotation_id" => "self.design_annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MDIKlVym7Td48cK9Avax0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
