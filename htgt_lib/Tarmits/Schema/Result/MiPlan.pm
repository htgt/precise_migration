use utf8;
package Tarmits::Schema::Result::MiPlan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiPlan

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

=head1 TABLE: C<mi_plans>

=cut

__PACKAGE__->table("mi_plans");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_plans_id_seq'

=head2 gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 consortium_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 priority_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 production_centre_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 number_of_es_cells_starting_qc

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_es_cells_passing_qc

  data_type: 'integer'
  is_nullable: 1

=head2 sub_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 is_bespoke_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_conditional_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_deletion_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_cre_knock_in_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 is_cre_bac_allele

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 1

=head2 withdrawn

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 es_qc_comment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 phenotype_only

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_plans_id_seq",
  },
  "gene_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "consortium_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "priority_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "production_centre_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "number_of_es_cells_starting_qc",
  { data_type => "integer", is_nullable => 1 },
  "number_of_es_cells_passing_qc",
  { data_type => "integer", is_nullable => 1 },
  "sub_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "is_bespoke_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_conditional_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_deletion_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_cre_knock_in_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "is_cre_bac_allele",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 1 },
  "withdrawn",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "es_qc_comment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "phenotype_only",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<mi_plan_logical_key>

=over 4

=item * L</gene_id>

=item * L</consortium_id>

=item * L</production_centre_id>

=item * L</sub_project_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "mi_plan_logical_key",
  [
    "gene_id",
    "consortium_id",
    "production_centre_id",
    "sub_project_id",
  ],
);

=head1 RELATIONS

=head2 consortium

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Consortia>

=cut

__PACKAGE__->belongs_to(
  "consortium",
  "Tarmits::Schema::Result::Consortia",
  { id => "consortium_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 es_qc_comment

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlanEsQcComment>

=cut

__PACKAGE__->belongs_to(
  "es_qc_comment",
  "Tarmits::Schema::Result::MiPlanEsQcComment",
  { id => "es_qc_comment_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 gene

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Tarmits::Schema::Result::Gene",
  { id => "gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 mi_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.mi_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_plan_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::MiPlanStatusStamp>

=cut

__PACKAGE__->has_many(
  "mi_plan_status_stamps",
  "Tarmits::Schema::Result::MiPlanStatusStamp",
  { "foreign.mi_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.mi_plan_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 priority

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlanPriority>

=cut

__PACKAGE__->belongs_to(
  "priority",
  "Tarmits::Schema::Result::MiPlanPriority",
  { id => "priority_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 production_centre

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Centre>

=cut

__PACKAGE__->belongs_to(
  "production_centre",
  "Tarmits::Schema::Result::Centre",
  { id => "production_centre_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 status

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlanStatus>

=cut

__PACKAGE__->belongs_to(
  "status",
  "Tarmits::Schema::Result::MiPlanStatus",
  { id => "status_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 sub_project

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MiPlanSubProject>

=cut

__PACKAGE__->belongs_to(
  "sub_project",
  "Tarmits::Schema::Result::MiPlanSubProject",
  { id => "sub_project_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Sb1fy/quya40Vb0iPlizcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
