use utf8;
package HTGTDB::Result::DisplayFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DisplayFeature

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DISPLAY_FEATURE>

=cut

__PACKAGE__->table("DISPLAY_FEATURE");

=head1 ACCESSORS

=head2 display_feature_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_display_feature'
  size: [10,0]

=head2 gene_build_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 display_feature_type

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 display_feature_group

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 chr_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 created_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=head2 created_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 label

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 assembly_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "display_feature_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_display_feature",
    size => [10, 0],
  },
  "gene_build_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "display_feature_type",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "display_feature_group",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "chr_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_user",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "label",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "assembly_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</display_feature_id>

=item * L</display_feature_type>

=item * L</feature_start>

=item * L</feature_end>

=back

=cut

__PACKAGE__->set_primary_key(
  "display_feature_id",
  "display_feature_type",
  "feature_start",
  "feature_end",
);

=head1 RELATIONS

=head2 feature

Type: belongs_to

Related object: L<HTGTDB::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "HTGTDB::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X8suAuwOR39Qt9Z7cfH6MA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
