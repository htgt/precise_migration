use utf8;
package HTGTDB::Result::Design;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Design

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN>

=cut

__PACKAGE__->table("DESIGN");

=head1 ACCESSORS

=head2 design_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_98_1_design'
  size: [10,0]

=head2 target_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 build_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=head2 pseudo_plate

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 final_plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=head2 well_loc

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 design_parameter_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 locus_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 random_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 125

=head2 start_exon_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 end_exon_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 gene_build_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lr_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 created_date

  data_type: 'datetime'
  default_value: systimestamp
  is_nullable: 1
  original: {data_type => "date"}

=head2 sp

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 tm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 atg

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 phase

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 pi

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 created_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 design_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 subtype

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 subtype_description

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=head2 validated_by_annotation

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

=head2 edited_date

  data_type: 'timestamp'
  default_value: systimestamp
  is_nullable: 1

=head2 edited_by

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 has_ensembl_image

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "design_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_98_1_design",
    size => [10, 0],
  },
  "target_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "build_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_name",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "pseudo_plate",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "final_plate",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "well_loc",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "design_parameter_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "locus_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "random_name",
  { data_type => "varchar2", is_nullable => 1, size => 125 },
  "start_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "end_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gene_build_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"systimestamp",
    is_nullable   => 1,
    original      => { data_type => "date" },
  },
  "sp",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "tm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "atg",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "phase",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "pi",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_type",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "subtype",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "subtype_description",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "validated_by_annotation",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "edited_date",
  {
    data_type     => "timestamp",
    default_value => \"systimestamp",
    is_nullable   => 1,
  },
  "edited_by",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "has_ensembl_image",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_id>

=back

=cut

__PACKAGE__->set_primary_key("design_id");

=head1 RELATIONS

=head2 alleles

Type: has_many

Related object: L<HTGTDB::Result::Allele>

=cut

__PACKAGE__->has_many(
  "alleles",
  "HTGTDB::Result::Allele",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_annotations

Type: has_many

Related object: L<HTGTDB::Result::DesignAnnotation>

=cut

__PACKAGE__->has_many(
  "design_annotations",
  "HTGTDB::Result::DesignAnnotation",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_bacs

Type: has_many

Related object: L<HTGTDB::Result::DesignBac>

=cut

__PACKAGE__->has_many(
  "design_bacs",
  "HTGTDB::Result::DesignBac",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_design_groups

Type: has_many

Related object: L<HTGTDB::Result::DesignDesignGroup>

=cut

__PACKAGE__->has_many(
  "design_design_groups",
  "HTGTDB::Result::DesignDesignGroup",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_instances

Type: has_many

Related object: L<HTGTDB::Result::DesignInstance>

=cut

__PACKAGE__->has_many(
  "design_instances",
  "HTGTDB::Result::DesignInstance",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_notes

Type: has_many

Related object: L<HTGTDB::Result::DesignNote>

=cut

__PACKAGE__->has_many(
  "design_notes",
  "HTGTDB::Result::DesignNote",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_statuses

Type: has_many

Related object: L<HTGTDB::Result::DesignStatus>

=cut

__PACKAGE__->has_many(
  "design_statuses",
  "HTGTDB::Result::DesignStatus",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_taqman_assays

Type: has_many

Related object: L<HTGTDB::Result::DesignTaqmanAssay>

=cut

__PACKAGE__->has_many(
  "design_taqman_assays",
  "HTGTDB::Result::DesignTaqmanAssay",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 design_user_comments

Type: has_many

Related object: L<HTGTDB::Result::DesignUserComment>

=cut

__PACKAGE__->has_many(
  "design_user_comments",
  "HTGTDB::Result::DesignUserComment",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<HTGTDB::Result::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "HTGTDB::Result::Feature",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_synvecs

Type: has_many

Related object: L<HTGTDB::Result::QcSynvec>

=cut

__PACKAGE__->has_many(
  "qc_synvecs",
  "HTGTDB::Result::QcSynvec",
  { "foreign.design_id" => "self.design_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VaeOqAL0qzy1hAQgNM2axA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
