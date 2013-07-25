use utf8;
package HTGTDB::Result::HtgtStatusMsg;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::HtgtStatusMsg

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<HTGT_STATUS_MSGS>

=cut

__PACKAGE__->table("HTGT_STATUS_MSGS");

=head1 ACCESSORS

=head2 id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 msg

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 is_active

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 the_date

  data_type: 'timestamp with local time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"sysdate"}

=head2 is_eucomm

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "msg",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "is_active",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "the_date",
  {
    data_type     => "timestamp with local time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"sysdate" },
  },
  "is_eucomm",
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KHNkDisHuxI7U8yyWZaxvA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
