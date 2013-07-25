use utf8;
package Tarmits::Schema::Result::Audit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Audit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<audits>

=cut

__PACKAGE__->table("audits");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'audits_id_seq'

=head2 auditable_id

  data_type: 'integer'
  is_nullable: 1

=head2 auditable_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 associated_id

  data_type: 'integer'
  is_nullable: 1

=head2 associated_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 user_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 action

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 audited_changes

  data_type: 'text'
  is_nullable: 1

=head2 version

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 remote_address

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 dummy_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "audits_id_seq",
  },
  "auditable_id",
  { data_type => "integer", is_nullable => 1 },
  "auditable_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "associated_id",
  { data_type => "integer", is_nullable => 1 },
  "associated_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "user_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "action",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "audited_changes",
  { data_type => "text", is_nullable => 1 },
  "version",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "remote_address",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "dummy_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u8NQhdlGyVjTKLEP0WbMEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
