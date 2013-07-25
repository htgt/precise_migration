package HTGTDB::DesignBAC;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('DESIGN_BAC');

#__PACKAGE__->add_columns(
#    qw/
#      design_id
#      bac_clone_id
#      midpoint_diff
#      allocate_to_instance
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "bac_clone_id",
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
  "midpoint_diff",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "allocate_to_instance",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_id bac_clone_id/);
__PACKAGE__->belongs_to( design => "HTGTDB::Design", 'design_id' );
__PACKAGE__->belongs_to( bac    => "HTGTDB::BAC",    'bac_clone_id' );

return 1;

