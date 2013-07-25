use utf8;
package Tarmits::Schema::Result::TargRepPipeline;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepPipeline

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

=head1 TABLE: C<targ_rep_pipelines>

=cut

__PACKAGE__->table("targ_rep_pipelines");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_pipelines_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
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
    sequence          => "targ_rep_pipelines_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
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

=head2 C<index_targ_rep_pipelines_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_targ_rep_pipelines_on_name", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1TvW/lq0LxIj0bplx00Uhw

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->has_many(
  "targ_rep_es_cells",
  "Tarmits::Schema::Result::TargRepEsCell",
  { "foreign.pipeline_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targeting_vectors

Type: has_many

Related object: L<Tarmits::Schema::Result::TargetingVector>

=cut

__PACKAGE__->has_many(
  "targ_rep_targeting_vectors",
  "Tarmits::Schema::Result::TargRepTargetingVector",
  { "foreign.pipeline_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
