package HTGTDB::PlateData;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('plate_data');

#__PACKAGE__->add_columns(
#    qw/
#      plate_id
#      data_type
#      data_value
#      plate_data_id
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
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "data_value",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "data_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "plate_data_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_data",
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

__PACKAGE__->set_primary_key(qw/plate_data_id/);
__PACKAGE__->sequence('S_PLATE_DATA');

__PACKAGE__->add_unique_constraint( plate_id_data_type => [qw/plate_id data_type/] );

__PACKAGE__->belongs_to( plate => "HTGTDB::Plate", 'plate_id' );

return 1;

