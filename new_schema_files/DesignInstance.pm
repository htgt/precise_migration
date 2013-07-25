package HTGTDB::DesignInstance;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_instance');

#__PACKAGE__->add_columns(
#    qw/
#      design_instance_id
#      plate
#      well
#      source
#      design_id
#      /
#);

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
  "plate",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "well",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "source",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "design_instance_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_instance",
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('design_instance_id');

__PACKAGE__->sequence('S_DESIGN_INSTANCE');

__PACKAGE__->add_unique_constraint( [qw/plate well/] );

__PACKAGE__->belongs_to( design => 'HTGTDB::Design', 'design_id' );

__PACKAGE__->has_many( design_instance_bacs => 'HTGTDB::DesignInstanceBAC', 'design_instance_id' );
__PACKAGE__->has_many( wells => 'HTGTDB::Well', 'design_instance_id' );

__PACKAGE__->many_to_many( bacs => 'design_instance_bacs', 'bac' );

__PACKAGE__->has_many( projects => 'HTGTDB::Project', 'design_instance_id' );

sub platewelldesign { my $di = shift; return $di->plate . $di->well . "_" . $di->design_id }

return 1;

