package HTGTDB::AuthRole;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('auth_role');
#__PACKAGE__->add_columns( qw(
#    auth_role_id
#    auth_role_name
#));

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "auth_role_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "auth_role_name",
  { data_type => "varchar2", is_nullable => 0, size => 200 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/auth_role_id/);
__PACKAGE__->sequence('S_AUTH_ROLE_ID');

__PACKAGE__->has_many( user_roles => 'HTGTDB::AuthUserRole', 'auth_role_id' );
__PACKAGE__->many_to_many( users => 'user_roles', 'auth_user' );


1;

__END__
