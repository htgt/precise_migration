use utf8;
package HTGTDB::Result::FeatureDataTypeDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::FeatureDataTypeDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<FEATURE_DATA_TYPE_DICT>

=cut

__PACKAGE__->table("FEATURE_DATA_TYPE_DICT");

=head1 ACCESSORS

=head2 feature_data_type_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_108_1_feature_data_type_'
  size: [10,0]

=head2 description

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "feature_data_type_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_108_1_feature_data_type_",
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_data_type_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_data_type_id");

=head1 RELATIONS

=head2 feature_datas

Type: has_many

Related object: L<HTGTDB::Result::FeatureData>

=cut

__PACKAGE__->has_many(
  "feature_datas",
  "HTGTDB::Result::FeatureData",
  { "foreign.feature_data_type_id" => "self.feature_data_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:11
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xCVz2D5n3zyof6PJ/y7I0w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
