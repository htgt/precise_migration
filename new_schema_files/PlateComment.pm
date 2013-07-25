package HTGTDB::PlateComment;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
#__PACKAGE__->load_components(qw/ InflateColumn::DateTime /);

__PACKAGE__->table('plate_comment');

#__PACKAGE__->add_columns(
#    qw/
#      plate_comment_id
#      plate_comment
#      plate_id
#      edit_user
#      edit_date
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "plate_comment",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "plate_comment_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_comment",
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);
# End of dbicdump add_columns data

#__PACKAGE__->add_columns(
#    edit_date => { data_type => 'date' }
#);

__PACKAGE__->set_primary_key(qw/plate_comment_id/);

__PACKAGE__->sequence('S_PLATE_COMMENT');

__PACKAGE__->belongs_to( plate => "HTGTDB::Plate", 'plate_id' );

1;

