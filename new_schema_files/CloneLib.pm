package HTGTDB::CloneLib;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('clone_lib_dict');
__PACKAGE__->sequence('S_97_1_CLONE_LIB_DICT');
#__PACKAGE__->add_columns(qw/clone_lib_id library/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "clone_lib_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_97_1_clone_lib_dict",
    size => [10, 0],
  },
  "library",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/clone_lib_id/);

return 1;

