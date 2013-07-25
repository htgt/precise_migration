package HTGTDB::Sessions;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('sessions');
#__PACKAGE__->add_columns(qw/id session_data expires/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar2", is_nullable => 0, size => 72 },
  "session_data",
  { data_type => "clob", is_nullable => 1 },
  "expires",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->sequence('S_SESSIONS');

return 1;

