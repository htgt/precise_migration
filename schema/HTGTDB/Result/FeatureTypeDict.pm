use utf8;
package HTGTDB::Result::FeatureTypeDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::FeatureTypeDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<FEATURE_TYPE_DICT>

=cut

__PACKAGE__->table("FEATURE_TYPE_DICT");

=head1 ACCESSORS

=head2 feature_type_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_109_1_feature_type_dict'
  size: [10,0]

=head2 description

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "feature_type_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_109_1_feature_type_dict",
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</feature_type_id>

=back

=cut

__PACKAGE__->set_primary_key("feature_type_id");

=head1 RELATIONS

=head2 features

Type: has_many

Related object: L<HTGTDB::Result::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "HTGTDB::Result::Feature",
  { "foreign.feature_type_id" => "self.feature_type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SiYIXmzoGiH9UEd92r2Uug


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
