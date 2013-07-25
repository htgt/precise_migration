use utf8;
package Tarmits::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::User

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

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'users_id_seq'

=head2 email

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 encrypted_password

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 128

=head2 remember_created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 production_centre_id

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 is_contactable

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 es_cell_distribution_centre_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 legacy_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_id_seq",
  },
  "email",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "encrypted_password",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 128 },
  "remember_created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "production_centre_id",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "is_contactable",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "es_cell_distribution_centre_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "legacy_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_users_on_email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("index_users_on_email", ["email"]);

=head1 RELATIONS

=head2 es_cell_distribution_centre

Type: belongs_to

Related object: L<Tarmits::Schema::Result::TargRepEsCellDistributionCentre>

=cut

__PACKAGE__->belongs_to(
  "es_cell_distribution_centre",
  "Tarmits::Schema::Result::TargRepEsCellDistributionCentre",
  { id => "es_cell_distribution_centre_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 mi_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.updated_by_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jVMZ9goZ3nHKQ/XiiMOjjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
