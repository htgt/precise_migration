use utf8;
package HTGTDB::Result::Session;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Session

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<SESSIONS>

=cut

__PACKAGE__->table("SESSIONS");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar2'
  is_nullable: 0
  size: 72

=head2 session_data

  data_type: 'clob'
  is_nullable: 1

=head2 expires

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KWSFU0lFaIcxy9Ram2H6Hw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
