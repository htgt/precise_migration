package HTGTDB::AuthUserRole;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('auth_user_role');
#__PACKAGE__->add_columns( qw(
#    auth_user_id
#    auth_role_id
#));

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "auth_user_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "auth_role_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/auth_user_id auth_role_id/);

__PACKAGE__->belongs_to( auth_user => 'HTGTDB::AuthUser', 'auth_user_id' );
__PACKAGE__->belongs_to( auth_role => 'HTGTDB::AuthRole', 'auth_role_id' );

1;

__END__
