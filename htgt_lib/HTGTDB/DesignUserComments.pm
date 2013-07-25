package HTGTDB::DesignUserComments;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_user_comments');

__PACKAGE__->sequence('S_DESIGN_USER_COMMENTS');

#__PACKAGE__->add_columns(
#  "design_comment_id",
#  {
#    data_type => "numeric",
#    is_auto_increment => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    sequence => "s_design_user_comment",
#    size => [10, 0],
#  },
#  "design_id",
#  {
#    data_type => "numeric",
#    is_foreign_key => 1,
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "design_comment",
#  { data_type => "varchar2", is_nullable => 1, size => 600 },
#  "visibility",
#  { data_type => "varchar2", is_nullable => 1, size => 10 },
#  "edited_user",
#  { data_type => "varchar2", is_nullable => 1, size => 30 },
#  "edited_date",
#  {
#    data_type     => "timestamp",
#    default_value => \"systimestamp",
#    is_nullable   => 0,
#  },
#  "category_id",
#  {
#    data_type => "numeric",
#    is_foreign_key => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => 126,
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_comment_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_user_comment",
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_comment",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "visibility",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "edited_user",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "edited_date",
  {
    data_type     => "timestamp",
    default_value => \"systimestamp",
    is_nullable   => 0,
  },
  "category_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data
#__PACKAGE__->add_columns(
#    design_comment_id => { is_auto_increment => 1, data_type => 'NUMBER' },
#       'design_id' => { data_type => 'NUMBER'  },
#       'category_id' => { data_type => 'NUMBER' },
#       'design_comment' => { data_type => 'VARCHAR2' },
#       'visibility' => { data_type => 'VARCHAR2' },
#       'edited_user' => { data_type => 'VARCHAR2' },
#       'edited_date' => { data_type => 'TIMESTAMP' },
#);

__PACKAGE__->set_primary_key(qw/design_comment_id/);
__PACKAGE__->belongs_to( design   => "HTGTDB::Design",   'design_id' );
__PACKAGE__->belongs_to( category => 'HTGTDB::DesignUserCommentCategories', 'category_id' );

1;
