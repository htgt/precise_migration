use utf8;
package Tarmits::Schema::Result::TargRepEsCell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepEsCell

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

=head1 TABLE: C<targ_rep_es_cells>

=cut

__PACKAGE__->table("targ_rep_es_cells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_es_cells_id_seq'

=head2 allele_id

  data_type: 'integer'
  is_nullable: 0

=head2 targeting_vector_id

  data_type: 'integer'
  is_nullable: 1

=head2 parental_cell_line

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mgi_allele_symbol_superscript

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 comment

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 contact

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ikmc_project_id

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mgi_allele_id

  data_type: 'varchar'
  is_nullable: 1
  size: 50

=head2 pipeline_id

  data_type: 'integer'
  is_nullable: 1

=head2 report_to_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 0

=head2 strain

  data_type: 'varchar'
  is_nullable: 1
  size: 25

=head2 production_qc_five_prime_screen

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_qc_three_prime_screen

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_qc_loxp_screen

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_qc_loss_of_allele

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 production_qc_vector_integrity

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_map_test

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_karyotype

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_tv_backbone_assay

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_loxp_confirmation

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_southern_blot

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_loss_of_wt_allele

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_neo_count_qpcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_lacz_sr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_mutant_specific_sr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_five_prime_cassette_integrity

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_neo_sr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_five_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_three_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 user_qc_comment

  data_type: 'text'
  is_nullable: 1

=head2 allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 mutation_subtype

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 allele_symbol_superscript_template

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 legacy_id

  data_type: 'integer'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 production_centre_auto_update

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
    sequence          => "targ_rep_es_cells_id_seq",
  },
  "allele_id",
  { data_type => "integer", is_nullable => 0 },
  "targeting_vector_id",
  { data_type => "integer", is_nullable => 1 },
  "parental_cell_line",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mgi_allele_symbol_superscript",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "comment",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "contact",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ikmc_project_id",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mgi_allele_id",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "pipeline_id",
  { data_type => "integer", is_nullable => 1 },
  "report_to_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
  "strain",
  { data_type => "varchar", is_nullable => 1, size => 25 },
  "production_qc_five_prime_screen",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_qc_three_prime_screen",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_qc_loxp_screen",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_qc_loss_of_allele",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "production_qc_vector_integrity",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_map_test",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_karyotype",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_tv_backbone_assay",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_loxp_confirmation",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_southern_blot",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_loss_of_wt_allele",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_neo_count_qpcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_lacz_sr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_mutant_specific_sr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_five_prime_cassette_integrity",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_neo_sr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_five_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_three_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "user_qc_comment",
  { data_type => "text", is_nullable => 1 },
  "allele_type",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "mutation_subtype",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "allele_symbol_superscript_template",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "legacy_id",
  { data_type => "integer", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "production_centre_auto_update",
  { data_type => "boolean", default_value => \"true", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<targ_rep_index_es_cells_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("targ_rep_index_es_cells_on_name", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mHu8/WkVmVCgd84RZK37tg

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

=head2 distribution_qcs

Type: has_many

Related object: L<Tarmits::Schema::Result::DistributionQc>

=cut

__PACKAGE__->has_many(
  "targ_rep_distribution_qcs",
  "Tarmits::Schema::Result::TargRepDistributionQc",
  { "foreign.es_cell_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 allele

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Allele>

=cut

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
