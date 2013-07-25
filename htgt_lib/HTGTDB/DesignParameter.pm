package HTGTDB::DesignParameter;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_parameter');
__PACKAGE__->sequence('S_112_DESIGN_PARAMETER');
#__PACKAGE__->add_columns(qw/design_parameter_id parameter_name parameter_value/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_parameter_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_112_design_parameter",
    size => [10, 0],
  },
  "parameter_name",
  { data_type => "varchar2", default_value => "", is_nullable => 0, size => 45 },
  "parameter_value",
  { data_type => "clob", is_nullable => 1 },
  "created",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key('design_parameter_id');

__PACKAGE__->has_many(designs=>"HTGTDB::Design",'design_parameter_id');

return 1;

