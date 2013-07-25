use utf8;
package Tarmits::Schema::Result::IntermediateReport;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::IntermediateReport

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

=head1 TABLE: C<intermediate_report>

=cut

__PACKAGE__->table("intermediate_report");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'intermediate_report_id_seq'

=head2 consortium

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 sub_project

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 priority

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_centre

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 gene

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 overall_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 mi_plan_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 mi_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 phenotype_attempt_status

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 ikmc_project_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_sub_type

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 allele_symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 genetic_background

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 assigned_date

  data_type: 'date'
  is_nullable: 1

=head2 assigned_es_cell_qc_in_progress_date

  data_type: 'date'
  is_nullable: 1

=head2 assigned_es_cell_qc_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 micro_injection_in_progress_date

  data_type: 'date'
  is_nullable: 1

=head2 chimeras_obtained_date

  data_type: 'date'
  is_nullable: 1

=head2 genotype_confirmed_date

  data_type: 'date'
  is_nullable: 1

=head2 micro_injection_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotype_attempt_registered_date

  data_type: 'date'
  is_nullable: 1

=head2 rederivation_started_date

  data_type: 'date'
  is_nullable: 1

=head2 rederivation_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 cre_excision_started_date

  data_type: 'date'
  is_nullable: 1

=head2 cre_excision_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_started_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotyping_complete_date

  data_type: 'date'
  is_nullable: 1

=head2 phenotype_attempt_aborted_date

  data_type: 'date'
  is_nullable: 1

=head2 distinct_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 distinct_old_non_genotype_confirmed_es_cells

  data_type: 'integer'
  is_nullable: 1

=head2 mi_plan_id

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 total_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 gc_pipeline_efficiency_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 is_bespoke_allele

  data_type: 'boolean'
  is_nullable: 1

=head2 aborted_es_cell_qc_failed_date

  data_type: 'date'
  is_nullable: 1

=head2 mi_attempt_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mi_attempt_consortium

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mi_attempt_production_centre

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 phenotype_attempt_colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "intermediate_report_id_seq",
  },
  "consortium",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sub_project",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "priority",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_centre",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "gene",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "overall_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "mi_plan_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "mi_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "phenotype_attempt_status",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "ikmc_project_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_sub_type",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "allele_symbol",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "genetic_background",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "assigned_date",
  { data_type => "date", is_nullable => 1 },
  "assigned_es_cell_qc_in_progress_date",
  { data_type => "date", is_nullable => 1 },
  "assigned_es_cell_qc_complete_date",
  { data_type => "date", is_nullable => 1 },
  "micro_injection_in_progress_date",
  { data_type => "date", is_nullable => 1 },
  "chimeras_obtained_date",
  { data_type => "date", is_nullable => 1 },
  "genotype_confirmed_date",
  { data_type => "date", is_nullable => 1 },
  "micro_injection_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "phenotype_attempt_registered_date",
  { data_type => "date", is_nullable => 1 },
  "rederivation_started_date",
  { data_type => "date", is_nullable => 1 },
  "rederivation_complete_date",
  { data_type => "date", is_nullable => 1 },
  "cre_excision_started_date",
  { data_type => "date", is_nullable => 1 },
  "cre_excision_complete_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_started_date",
  { data_type => "date", is_nullable => 1 },
  "phenotyping_complete_date",
  { data_type => "date", is_nullable => 1 },
  "phenotype_attempt_aborted_date",
  { data_type => "date", is_nullable => 1 },
  "distinct_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "distinct_old_non_genotype_confirmed_es_cells",
  { data_type => "integer", is_nullable => 1 },
  "mi_plan_id",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "total_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "gc_pipeline_efficiency_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "is_bespoke_allele",
  { data_type => "boolean", is_nullable => 1 },
  "aborted_es_cell_qc_failed_date",
  { data_type => "date", is_nullable => 1 },
  "mi_attempt_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mi_attempt_consortium",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mi_attempt_production_centre",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "phenotype_attempt_colony_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eByNEsnCk1F+OlwLHtLYMw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
