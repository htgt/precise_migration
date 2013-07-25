package HTGTDB::DesignStatusDict;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
=cut



use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);


__PACKAGE__->table('design_status_dict');
#__PACKAGE__->add_columns(qw/design_status_id description/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_status_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_103_1_design_status_dict",
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/design_status_id/);
__PACKAGE__->has_many(design_statuses=>"HTGTDB::DesignStatus",'design_status_id');

return 1;

