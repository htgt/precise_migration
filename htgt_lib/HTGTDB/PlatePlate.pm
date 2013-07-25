package HTGTDB::PlatePlate;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('plate_plate');

#__PACKAGE__->add_columns(
#    qw/
#        parent_plate_id
#        child_plate_id
#    /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "parent_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0, # Primary keys are not nullable
    original => { data_type => "number" },
    size => [10, 0],
  },
  "child_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/parent_plate_id child_plate_id/);

__PACKAGE__->belongs_to( 'parent_plate' => 'HTGTDB::Plate', 'parent_plate_id' );
__PACKAGE__->belongs_to( 'child_plate'  => 'HTGTDB::Plate', 'child_plate_id' );

return 1;

