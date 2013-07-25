package HTGTDB::FeatureData;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('feature_data');
__PACKAGE__->sequence('S_107_1_FEATURE_DATA');

#__PACKAGE__->add_columns(qw/
#    feature_data_id 
#    feature_data_type_id 
#    feature_id 
#    data_item
#    /);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "feature_data_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0, # primary keys cannot be nullable - DJP-S
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
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('feature_data_id');
__PACKAGE__->add_unique_constraint( feature_id_feature_data_type_id => [qw/feature_id feature_data_type_id/] );
__PACKAGE__->belongs_to(feature_data_type=>"HTGTDB::FeatureDataType",'feature_data_type_id');
__PACKAGE__->belongs_to(feature=>"HTGTDB::Feature",'feature_id');

return 1;

