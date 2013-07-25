package HTGTDB::DesignStatus;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_status');
#__PACKAGE__->add_columns(qw/design_status_id design_id status_date is_current id_role/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_status_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "status_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "is_current",
  { data_type => "char", is_nullable => 1, size => 1 },
  "id_role",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_status_id design_id/);
__PACKAGE__->belongs_to(design_id=>"HTGTDB::Design",'design_id');
__PACKAGE__->belongs_to(design_status_dict=>"HTGTDB::DesignStatusDict",'design_status_id');

return 1;

