use utf8;
package HTGTDB::Result::ExtUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ExtUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<EXT_USER>

=cut

__PACKAGE__->table("EXT_USER");

=head1 ACCESSORS

=head2 edited_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 email_address

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 email_text

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 edited_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 ext_user_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_ext_user'
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "edited_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "email_address",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "email_text",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "edited_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "ext_user_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_ext_user",
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</ext_user_id>

=back

=cut

__PACKAGE__->set_primary_key("ext_user_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xpcU0SnCoQXS/n1szDdFQg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
