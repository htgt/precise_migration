use utf8;
package Tarmits::Schema::Result::MiAttempt;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiAttempt

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

=head1 TABLE: C<mi_attempts>

=cut

__PACKAGE__->table("mi_attempts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_attempts_id_seq'

=head2 es_cell_id

  data_type: 'integer'
  is_nullable: 0

=head2 mi_date

  data_type: 'date'
  is_nullable: 0

=head2 status_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 colony_name

  data_type: 'varchar'
  is_nullable: 1
  size: 125

=head2 updated_by_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 blast_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 total_blasts_injected

  data_type: 'integer'
  is_nullable: 1

=head2 total_transferred

  data_type: 'integer'
  is_nullable: 1

=head2 number_surrogates_receiving

  data_type: 'integer'
  is_nullable: 1

=head2 total_pups_born

  data_type: 'integer'
  is_nullable: 1

=head2 total_female_chimeras

  data_type: 'integer'
  is_nullable: 1

=head2 total_male_chimeras

  data_type: 'integer'
  is_nullable: 1

=head2 total_chimeras

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_males_with_0_to_39_percent_chimerism

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_males_with_40_to_79_percent_chimerism

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_males_with_80_to_99_percent_chimerism

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_males_with_100_percent_chimerism

  data_type: 'integer'
  is_nullable: 1

=head2 colony_background_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 test_cross_strain_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date_chimeras_mated

  data_type: 'date'
  is_nullable: 1

=head2 number_of_chimera_matings_attempted

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimera_matings_successful

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_glt_from_cct

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_glt_from_genotyping

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_0_to_9_percent_glt

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_10_to_49_percent_glt

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_50_to_99_percent_glt

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_chimeras_with_100_percent_glt

  data_type: 'integer'
  is_nullable: 1

=head2 total_f1_mice_from_matings

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_cct_offspring

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_het_offspring

  data_type: 'integer'
  is_nullable: 1

=head2 number_of_live_glt_offspring

  data_type: 'integer'
  is_nullable: 1

=head2 mouse_allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 qc_southern_blot_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_five_prime_lr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_five_prime_cassette_integrity_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_tv_backbone_assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_neo_count_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_neo_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loa_qpcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_homozygous_loa_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_lacz_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_mutant_specific_sr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_loxp_confirmation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 qc_three_prime_lr_pcr_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 report_to_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 is_active

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 is_released_from_genotyping

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 comments

  data_type: 'text'
  is_nullable: 1

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

=head2 genotyping_comment

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_attempts_id_seq",
  },
  "es_cell_id",
  { data_type => "integer", is_nullable => 0 },
  "mi_date",
  { data_type => "date", is_nullable => 0 },
  "status_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "colony_name",
  { data_type => "varchar", is_nullable => 1, size => 125 },
  "updated_by_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "blast_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "total_blasts_injected",
  { data_type => "integer", is_nullable => 1 },
  "total_transferred",
  { data_type => "integer", is_nullable => 1 },
  "number_surrogates_receiving",
  { data_type => "integer", is_nullable => 1 },
  "total_pups_born",
  { data_type => "integer", is_nullable => 1 },
  "total_female_chimeras",
  { data_type => "integer", is_nullable => 1 },
  "total_male_chimeras",
  { data_type => "integer", is_nullable => 1 },
  "total_chimeras",
  { data_type => "integer", is_nullable => 1 },
  "number_of_males_with_0_to_39_percent_chimerism",
  { data_type => "integer", is_nullable => 1 },
  "number_of_males_with_40_to_79_percent_chimerism",
  { data_type => "integer", is_nullable => 1 },
  "number_of_males_with_80_to_99_percent_chimerism",
  { data_type => "integer", is_nullable => 1 },
  "number_of_males_with_100_percent_chimerism",
  { data_type => "integer", is_nullable => 1 },
  "colony_background_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "test_cross_strain_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date_chimeras_mated",
  { data_type => "date", is_nullable => 1 },
  "number_of_chimera_matings_attempted",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimera_matings_successful",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_glt_from_cct",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_glt_from_genotyping",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_0_to_9_percent_glt",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_10_to_49_percent_glt",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_50_to_99_percent_glt",
  { data_type => "integer", is_nullable => 1 },
  "number_of_chimeras_with_100_percent_glt",
  { data_type => "integer", is_nullable => 1 },
  "total_f1_mice_from_matings",
  { data_type => "integer", is_nullable => 1 },
  "number_of_cct_offspring",
  { data_type => "integer", is_nullable => 1 },
  "number_of_het_offspring",
  { data_type => "integer", is_nullable => 1 },
  "number_of_live_glt_offspring",
  { data_type => "integer", is_nullable => 1 },
  "mouse_allele_type",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "qc_southern_blot_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_five_prime_lr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_five_prime_cassette_integrity_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_tv_backbone_assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_neo_count_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_neo_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loa_qpcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_homozygous_loa_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_lacz_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_mutant_specific_sr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_loxp_confirmation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "qc_three_prime_lr_pcr_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "report_to_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "is_active",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "is_released_from_genotyping",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "comments",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "mi_plan_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "genotyping_comment",
  { data_type => "varchar", is_nullable => 1, size => 512 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_mi_attempts_on_colony_name>

=over 4

=item * L</colony_name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_mi_attempts_on_colony_name", ["colony_name"]);

=head1 RELATIONS

=head2 blast_strain

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Strain>

=cut

__PACKAGE__->belongs_to(
  "blast_strain",
  "Tarmits::Schema::Result::Strain",
  { id => "blast_strain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

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

=head2 mi_attempt_distribution_centres

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttemptDistributionCentre>

=cut

__PACKAGE__->has_many(
  "mi_attempt_distribution_centres",
  "Tarmits::Schema::Result::MiAttemptDistributionCentre",
  { "foreign.mi_attempt_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempt_status_stamps

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttemptStatusStamp>

=cut

__PACKAGE__->has_many(
  "mi_attempt_status_stamps",
  "Tarmits::Schema::Result::MiAttemptStatusStamp",
  { "foreign.mi_attempt_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 phenotype_attempts

Type: has_many

Related object: L<Tarmits::Schema::Result::PhenotypeAttempt>

=cut

__PACKAGE__->has_many(
  "phenotype_attempts",
  "Tarmits::Schema::Result::PhenotypeAttempt",
  { "foreign.mi_attempt_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_five_prime_cassette_integrity

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_five_prime_cassette_integrity",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_five_prime_cassette_integrity_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_five_prime_lr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_five_prime_lr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_five_prime_lr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_homozygous_loa_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_homozygous_loa_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_homozygous_loa_sr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_lacz_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_lacz_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_lacz_sr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_loa_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loa_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loa_qpcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_loxp_confirmation

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_loxp_confirmation",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_loxp_confirmation_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_mutant_specific_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_mutant_specific_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_mutant_specific_sr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_neo_count_qpcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_neo_count_qpcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_neo_count_qpcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_neo_sr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_neo_sr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_neo_sr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_southern_blot

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_southern_blot",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_southern_blot_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_three_prime_lr_pcr

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_three_prime_lr_pcr",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_three_prime_lr_pcr_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 qc_tv_backbone_assay

Type: belongs_to

Related object: L<Tarmits::Schema::Result::QcResult>

=cut

__PACKAGE__->belongs_to(
  "qc_tv_backbone_assay",
  "Tarmits::Schema::Result::QcResult",
  { id => "qc_tv_backbone_assay_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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

=head2 test_cross_strain

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Strain>

=cut

__PACKAGE__->belongs_to(
  "test_cross_strain",
  "Tarmits::Schema::Result::Strain",
  { id => "test_cross_strain_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 updated_by

Type: belongs_to

Related object: L<Tarmits::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "updated_by",
  "Tarmits::Schema::Result::User",
  { id => "updated_by_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BFE7F3PZgTsWCMoCzwS16g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
