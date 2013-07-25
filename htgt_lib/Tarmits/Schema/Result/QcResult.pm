use utf8;
package Tarmits::Schema::Result::QcResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::QcResult

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

=head1 TABLE: C<qc_results>

=cut

__PACKAGE__->table("qc_results");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'qc_results_id_seq'

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 50

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
    sequence          => "qc_results_id_seq",
  },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 50 },
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

=head2 C<index_qc_results_on_description>

=over 4

=item * L</description>

=back

=cut

__PACKAGE__->add_unique_constraint("index_qc_results_on_description", ["description"]);

=head1 RELATIONS

=head2 mi_attempts_qc_five_prime_cassette_integrities

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_five_prime_cassette_integrities",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_five_prime_cassette_integrity_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_five_prime_lr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_five_prime_lr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_five_prime_lr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_homozygous_loa_sr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_homozygous_loa_sr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_homozygous_loa_sr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_lacz_sr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_lacz_sr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_lacz_sr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_loa_qpcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_loa_qpcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_loa_qpcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_loxp_confirmations

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_loxp_confirmations",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_loxp_confirmation_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_mutant_specific_sr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_mutant_specific_sr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_mutant_specific_sr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_neo_count_qpcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_neo_count_qpcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_neo_count_qpcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_neo_sr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_neo_sr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_neo_sr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_southern_blots

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_southern_blots",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_southern_blot_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_three_prime_lr_pcrs

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_three_prime_lr_pcrs",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_three_prime_lr_pcr_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mi_attempts_qc_tv_backbone_assays

Type: has_many

Related object: L<Tarmits::Schema::Result::MiAttempt>

=cut

__PACKAGE__->has_many(
  "mi_attempts_qc_tv_backbone_assays",
  "Tarmits::Schema::Result::MiAttempt",
  { "foreign.qc_tv_backbone_assay_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8ispOfnBv5/c+/RvZR4kag


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
