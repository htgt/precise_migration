package HTGTDB::ProjectStatus;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('project_status');

#__PACKAGE__->add_columns(
#    qw/
#      project_status_id
#      name
#      order_by
#      code
#      stage
#      status_type
#      description
#      is_terminal
#      does_not_compete_for_latest
#    /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "project_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "order_by",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [3, 0],
  },
  "code",
  { data_type => "varchar2", is_nullable => 0, size => 10 },
  "stage",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "status_type",
  {
    data_type => "varchar2",
    default_value => "normal",
    is_nullable => 1,
    size => 100,
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "is_terminal",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "does_not_compete_for_latest",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('project_status_id');

return 1;
