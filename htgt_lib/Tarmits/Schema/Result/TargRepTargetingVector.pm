use utf8;
package Tarmits::Schema::Result::TargRepTargetingVector;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepTargetingVector

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

=head1 TABLE: C<targ_rep_targeting_vectors>

=cut

__PACKAGE__->table("targ_rep_targeting_vectors");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_targeting_vectors_id_seq'

=head2 allele_id

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 ikmc_project_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 intermediate_vector

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 report_to_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 pipeline_id

  data_type: 'integer'
  is_nullable: 1

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
    sequence          => "targ_rep_targeting_vectors_id_seq",
  },
  "allele_id",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "ikmc_project_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "intermediate_vector",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "report_to_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "pipeline_id",
  { data_type => "integer", is_nullable => 1 },
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

=head2 C<index_targvec>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_targvec", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Q1t/q6I+Qr3k7fvQ7kTug

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->belongs_to(
  "targ_rep_allele",
  "Tarmits::Schema::Result::TargRepAllele",
  { id => "allele_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 pipeline

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Pipeline>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_pipeline",
  "Tarmits::Schema::Result::TargRepPipeline",
  { id => "pipeline_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
