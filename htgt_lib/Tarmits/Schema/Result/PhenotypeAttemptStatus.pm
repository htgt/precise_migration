use utf8;
package Tarmits::Schema::Result::PhenotypeAttemptStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::PhenotypeAttemptStatus

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

=head1 TABLE: C<phenotype_attempt_statuses>

=cut

__PACKAGE__->table("phenotype_attempt_statuses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_attempt_statuses_id_seq'

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
    sequence          => "phenotype_attempt_statuses_id_seq",
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

=head1 RELATIONS

=head2 phenotype_attempt_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptStatusStamp>

=cut

__PACKAGE__->has_many(
  "phenotype_attempt_status_stamps",
  "Tarmits::Schema::Result::PhenotypeAttemptStatusStamp",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.status_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6GEOsuw42mmR411QlCaf9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
