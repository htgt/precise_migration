use utf8;
package HTGTDB::Result::FeatureData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::FeatureData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<FEATURE_DATA>

=cut

__PACKAGE__->table("FEATURE_DATA");

=head1 ACCESSORS

=head2 feature_data_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 1
  original: {data_type => "number"}
  sequence: 's_107_1_feature_data'
  size: [10,0]

=head2 feature_data_type_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 feature_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 data_item

  data_type: 'clob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "feature_data_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    sequence => "s_107_1_feature_data",
    size => [10, 0],
  },
  "feature_data_type_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "data_item",
  { data_type => "clob", is_nullable => 1 },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 feature_data_type

Type: belongs_to

Related object: L<HTGTDB::Result::FeatureDataTypeDict>

=cut

__PACKAGE__->belongs_to(
  "feature_data_type",
  "HTGTDB::Result::FeatureDataTypeDict",
  { feature_data_type_id => "feature_data_type_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JJ1SWMc+Wd8QgyJLpNAnXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
