package HTGTDB::DesignInstanceBAC;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('DESIGN_INSTANCE_BAC');

#__PACKAGE__->add_columns(qw/design_instance_id bac_clone_id bac_plate/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_clone_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_plate",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_instance_id bac_clone_id/);
__PACKAGE__->belongs_to( design_instance => "HTGTDB::DesignInstance", 'design_instance_id' );
__PACKAGE__->belongs_to( bac             => "HTGTDB::BAC",            'bac_clone_id' );

return 1;

