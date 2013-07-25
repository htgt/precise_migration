package HTGTDB::BAC;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('BAC');
#__PACKAGE__->add_columns(
#    qw/
#      bac_clone_id
#      remote_clone_id
#      clone_lib_id
#      chr_id
#      bac_start
#      bac_end
#      bac_midpoint
#      build_id
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "bac_clone_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_93_1_bac",
    size => [10, 0],
  },
  "remote_clone_id",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "clone_lib_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_start",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_end",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_midpoint",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "build_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/bac_clone_id/);

__PACKAGE__->belongs_to( clone_lib => "HTGTDB::CloneLib", 'clone_lib_id' );

__PACKAGE__->has_many( design_bacs => 'HTGTDB::DesignBAC', 'design_id' );
__PACKAGE__->many_to_many( designs => 'design_bacs', 'design_id' );

return 1;

