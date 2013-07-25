package HTGTDB::PlateBlob;
use strict;
use warnings;

=head1 AUTHOR

Darren Oakley <do2@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('plate_blob');

#__PACKAGE__->add_columns(
#    qw/
#      plate_blob_id
#      plate_id
#      binary_data
#      binary_data_type
#      image_thumbnail
#      file_name
#      file_size
#      description
#      is_public
#      edit_user
#      edit_date
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "plate_blob_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_blob",
    size => [10, 0],
  },
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "binary_data",
  { data_type => "blob", is_nullable => 1 },
  "binary_data_type",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "image_thumbnail",
  { data_type => "blob", is_nullable => 1 },
  "file_name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "file_size",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "is_public",
  { data_type => "char", is_nullable => 1, size => 1 },
  "edit_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/plate_blob_id/);

__PACKAGE__->add_unique_constraint( plate_id_file_name => [qw/plate_id file_name/] );

__PACKAGE__->sequence('S_PLATE_BLOB');

__PACKAGE__->belongs_to( plate => "HTGTDB::Plate", 'plate_id' );

return 1;

