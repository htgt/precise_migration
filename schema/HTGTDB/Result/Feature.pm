use utf8;
package HTGTDB::Result::Feature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Feature

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<FEATURE>

=cut

__PACKAGE__->table("FEATURE");

=head1 ACCESSORS

=head2 feature_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_105_1_feature'
  size: [10,0]

=head2 feature_type_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 chr_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_start

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_end

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 allocate_to_instance

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "feature_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_105_1_feature",
    size => [10, 0],
  },
  "feature_type_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_start",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_end",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "allocate_to_instance",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_id");

=head1 RELATIONS

=head2 chr

Type: belongs_to

Related object: L<HTGTDB::Result::ChromosomeDict>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "HTGTDB::Result::ChromosomeDict",
  { chr_id => "chr_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);

=head2 design_instance_features

Type: has_many

Related object: L<HTGTDB::Result::DesignInstanceFeature>

=cut

__PACKAGE__->has_many(
  "design_instance_features",
  "HTGTDB::Result::DesignInstanceFeature",
  { "foreign.feature_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 display_features

Type: has_many

Related object: L<HTGTDB::Result::DisplayFeature>

=cut

__PACKAGE__->has_many(
  "display_features",
  "HTGTDB::Result::DisplayFeature",
  { "foreign.feature_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_blasts

Type: has_many

Related object: L<HTGTDB::Result::FeatureBlast>

=cut

__PACKAGE__->has_many(
  "feature_blasts",
  "HTGTDB::Result::FeatureBlast",
  { "foreign.feature_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_datas

Type: has_many

Related object: L<HTGTDB::Result::FeatureData>

=cut

__PACKAGE__->has_many(
  "feature_datas",
  "HTGTDB::Result::FeatureData",
  { "foreign.feature_id" => "self.feature_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature_type

Type: belongs_to

Related object: L<HTGTDB::Result::FeatureTypeDict>

=cut

__PACKAGE__->belongs_to(
  "feature_type",
  "HTGTDB::Result::FeatureTypeDict",
  { feature_type_id => "feature_type_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2fiw88kvdauMNNg3wEqHfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
