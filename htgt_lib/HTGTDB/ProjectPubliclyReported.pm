package HTGTDB::ProjectPubliclyReported;
use strict;
use warnings;

=head1 AUTHOR

Sajith Perera

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);


__PACKAGE__->table('project_publicly_reported_dict');
#__PACKAGE__->add_columns(qw/is_publicly_reported description/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "is_publicly_reported",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 0, size => 225 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/is_publicly_reported/);
__PACKAGE__->has_many(projects=>'HTGTDB::Project','is_publicly_reported');

return 1;
