use utf8;
package HTGTDB::Result::AuthUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::AuthUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<AUTH_USER>

=cut

__PACKAGE__->table("AUTH_USER");

=head1 ACCESSORS

=head2 auth_user_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 auth_user_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 200

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</auth_user_id>

=back

=cut

__PACKAGE__->set_primary_key("auth_user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<auth_user_uk1>

=over 4

=item * L</auth_user_name>

=back

=cut

__PACKAGE__->add_unique_constraint("auth_user_uk1", ["auth_user_name"]);

=head1 RELATIONS

=head2 auth_user_roles

Type: has_many

Related object: L<HTGTDB::Result::AuthUserRole>

=cut

__PACKAGE__->has_many(
  "auth_user_roles",
  "HTGTDB::Result::AuthUserRole",
  { "foreign.auth_user_id" => "self.auth_user_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 auth_roles

Type: many_to_many

Composing rels: L</auth_user_roles> -> auth_role

=cut

__PACKAGE__->many_to_many("auth_roles", "auth_user_roles", "auth_role");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ru+jt9p0RhE+Qm816EoSYQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
