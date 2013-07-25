use utf8;
package Tarmits::Schema::Result::PhenotypeAttempt;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::PhenotypeAttempt

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

=head1 TABLE: C<phenotype_attempts>

=cut

__PACKAGE__->table("phenotype_attempts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_attempts_id_seq'

=head2 mi_attempt_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 rederivation_started

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 rederivation_complete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 number_of_cre_matings_started

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 number_of_cre_matings_successful

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 phenotyping_started

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 phenotyping_complete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 mi_plan_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 colony_name

  data_type: 'varchar'
  is_nullable: 0
  size: 125

=head2 mouse_allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 deleter_strain_id

  data_type: 'integer'
  is_nullable: 1

=head2 colony_background_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 cre_excision_required

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_attempts_id_seq",
  },
  "mi_attempt_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "rederivation_started",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "rederivation_complete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "number_of_cre_matings_started",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "number_of_cre_matings_successful",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "phenotyping_started",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "phenotyping_complete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "mi_plan_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "colony_name",
  { data_type => "varchar", is_nullable => 0, size => 125 },
  "mouse_allele_type",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "deleter_strain_id",
  { data_type => "integer", is_nullable => 1 },
  "colony_background_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "cre_excision_required",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_phenotype_attempts_on_colony_name>

=over 4

=item * L</colony_name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_phenotype_attempts_on_colony_name", ["colony_name"]);

=head1 RELATIONS

=head2 colony_background_strain

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Strain>

=cut

__PACKAGE__->belongs_to(
  "colony_background_strain",
  "Tarmits::Schema::Result::Strain",
  { id => "colony_background_strain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

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

=head2 mi_plan

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlan>

=cut

__PACKAGE__->belongs_to(
  "mi_plan",
  "Tarmits::Schema::Result::MiPlan",
  { id => "mi_plan_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 phenotype_attempt_distribution_centres

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre>

=cut

__PACKAGE__->has_many(
  "phenotype_attempt_distribution_centres",
  "Tarmits::Schema::Result::PhenotypeAttemptDistributionCentre",
  { "foreign.phenotype_attempt_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempt_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptStatusStamp>

=cut

__PACKAGE__->has_many(
  "phenotype_attempt_status_stamps",
  "Tarmits::Schema::Result::PhenotypeAttemptStatusStamp",
  { "foreign.phenotype_attempt_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::PhenotypeAttemptStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::PhenotypeAttemptStatus",
  { id => "status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3eQ/SkHdHaheMbLl5srKUQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
