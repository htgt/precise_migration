use utf8;
package Tarmits::Schema::Result::MiAttemptStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiAttemptStatus

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

=head1 TABLE: C<mi_attempt_statuses>

=cut

__PACKAGE__->table("mi_attempt_statuses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_attempt_statuses_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 order_by

  data_type: 'integer'
  is_nullable: 1

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_attempt_statuses_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "order_by",
  { data_type => "integer", is_nullable => 1 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_mi_attempt_statuses_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_mi_attempt_statuses_on_name", ["name"]);

=head1 RELATIONS

=head2 mi_attempt_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttemptStatusStamp>

=cut

__PACKAGE__->has_many(
  "mi_attempt_status_stamps",
  "Tarmits::Schema::Result::MiAttemptStatusStamp",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KmLTUw+sX8b9oqibjVBupQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
