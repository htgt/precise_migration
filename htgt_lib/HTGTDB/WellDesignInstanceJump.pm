package HTGTDB::WellDesignInstanceJump;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('well_design_instance_jump');
#__PACKAGE__->add_columns( qw(
#    well_design_instance_jump_id
#    well_id
#    previous_design_instance_id
#    previous_parent_well_id
#    edit_user
#    edit_timestamp
#    edit_comment
#));

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "well_design_instance_jump_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "previous_design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "previous_parent_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_timestamp",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "edit_comment",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/well_design_instance_jump_id/);
__PACKAGE__->sequence('S_WELL_DESIGN_INSTANCE_JUMP_ID');

__PACKAGE__->belongs_to( well => 'HTGTDB::Well', 'well_id' );
__PACKAGE__->belongs_to( previous_design_instance => 'HTGTDB::DesignInstance', 'previous_design_instance_id' );
__PACKAGE__->belongs_to( previous_parent_well => 'HTGTDB::Well', 'previous_parent_well_id' );

1;

__END__
