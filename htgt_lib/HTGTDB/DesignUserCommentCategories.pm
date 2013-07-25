package HTGTDB::DesignUserCommentCategories;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_user_comment_categories');

__PACKAGE__->sequence('s_design_user_comment_category');

#__PACKAGE__->add_columns(
#  "category_id",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => 126,
#  },
#  "category_name",
#  { data_type => "varchar2", is_nullable => 0, size => 1000 },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "category_name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
);
# End of dbicdump add_columns data
#__PACKAGE__->add_columns( qw( category_id category_name ) );

__PACKAGE__->set_primary_key( 'category_id' );

__PACKAGE__->has_many( 'design_user_comments' => 'HTGTDB::DesignUserComments' => 'category_id' );

__PACKAGE__->many_to_many( 'designs' => 'HTGTDB::DesignUserComments' => 'design' );

1;
