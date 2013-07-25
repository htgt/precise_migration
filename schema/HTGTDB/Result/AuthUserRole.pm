use utf8;
package HTGTDB::Result::AuthUserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::AuthUserRole

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<AUTH_USER_ROLE>

=cut

__PACKAGE__->table("AUTH_USER_ROLE");

=head1 ACCESSORS

=head2 auth_user_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 auth_role_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</auth_user_id>

=item * L</auth_role_id>

=back

=cut

__PACKAGE__->set_primary_key("auth_user_id", "auth_role_id");

=head1 RELATIONS

=head2 auth_role

Type: belongs_to

Related object: L<HTGTDB::Result::AuthRole>

=cut

__PACKAGE__->belongs_to(
  "auth_role",
  "HTGTDB::Result::AuthRole",
  { auth_role_id => "auth_role_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 auth_user

Type: belongs_to

Related object: L<HTGTDB::Result::AuthUser>

=cut

__PACKAGE__->belongs_to(
  "auth_user",
  "HTGTDB::Result::AuthUser",
  { auth_user_id => "auth_user_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l03hqSVUmqQSZYNSgXyzvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
