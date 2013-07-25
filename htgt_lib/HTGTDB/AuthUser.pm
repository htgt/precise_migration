package HTGTDB::AuthUser;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('auth_user');
#__PACKAGE__->add_columns( qw(
#    auth_user_id
#    auth_user_name
#));

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "auth_user_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "auth_user_name",
  { data_type => "varchar2", is_nullable => 0, size => 200 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/auth_user_id/);
__PACKAGE__->sequence('S_AUTH_USER_ID');

__PACKAGE__->has_many( user_roles => 'HTGTDB::AuthUserRole', 'auth_user_id' );
__PACKAGE__->many_to_many( roles => 'user_roles', 'auth_role' );

# Backwards-compatibility hack for code that calls $c->user->id and
# expects to see the username.
sub id {
    my $self = shift;
    $self->auth_user_name;
}

1;

__END__
