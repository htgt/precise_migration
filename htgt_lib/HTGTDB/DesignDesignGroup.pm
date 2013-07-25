package HTGTDB::DesignDesignGroup;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('DESIGN_DESIGN_GROUP');

#__PACKAGE__->add_columns(qw/design_id design_group_id/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_group_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0, # Primary keys cannot be nullable - DJP-S
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_id design_group_id/);
__PACKAGE__->belongs_to(design_group => 'HTGTDB::DesignGroup','design_group_id');
__PACKAGE__->belongs_to(designs => 'HTGTDB::Design','design_id');
__PACKAGE__->belongs_to(design_groups => 'HTGTDB::DesignGroup','design_group_id');

return 1;

