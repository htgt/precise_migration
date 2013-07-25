package HTGTDB::DesignGroup;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_group');
#__PACKAGE__->add_columns(qw/design_group_id name/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_group_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_group_id/);
__PACKAGE__->has_many(design_design_groups => 'HTGTDB::DesignDesignGroup', 'design_group_id');

return 1;

