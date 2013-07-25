use utf8;
package Tarmits::Schema::Result::MiAttemptStatusStamp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiAttemptStatusStamp

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

=head1 TABLE: C<mi_attempt_status_stamps>

=cut

__PACKAGE__->table("mi_attempt_status_stamps");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_attempt_status_stamps_id_seq'

=head2 mi_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_attempt_status_stamps_id_seq",
  },
  "mi_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_one_status_stamp_per_status_and_mi_attempt>

=over 4

=item * L</status_id>

=item * L</mi_attempt_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_one_status_stamp_per_status_and_mi_attempt",
  ["status_id", "mi_attempt_id"],
);

=head1 RELATIONS

=head2 mi_attempt

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->belongs_to(
  "mi_attempt",
  "Tarmits::Schema::Result::MiAttempt",
  { id => "mi_attempt_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiAttemptStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::MiAttemptStatus",
  { id => "status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bFiHbDpEXjlNp77ikbBpig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
