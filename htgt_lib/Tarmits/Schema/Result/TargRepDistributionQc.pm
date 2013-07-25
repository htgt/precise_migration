use utf8;
package Tarmits::Schema::Result::TargRepDistributionQc;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepDistributionQc

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

=head1 TABLE: C<targ_rep_distribution_qcs>

=cut

__PACKAGE__->table("targ_rep_distribution_qcs");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_distribution_qcs_id_seq'

=head2 five_prime_sr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 three_prime_sr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 karyotype_low

  data_type: 'double precision'
  is_nullable: 1

=head2 karyotype_high

  data_type: 'double precision'
  is_nullable: 1

=head2 copy_number

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 five_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 three_prime_lr_pcr

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 thawing

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 loa

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 loxp

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 lacz

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chr1

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chr8a

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chr8b

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chr11a

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chr11b

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 chry

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 es_cell_id

  data_type: 'integer'
  is_nullable: 1

=head2 es_cell_distribution_centre_id

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
    sequence          => "targ_rep_distribution_qcs_id_seq",
  },
  "five_prime_sr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "three_prime_sr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "karyotype_low",
  { data_type => "double precision", is_nullable => 1 },
  "karyotype_high",
  { data_type => "double precision", is_nullable => 1 },
  "copy_number",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "five_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "three_prime_lr_pcr",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "thawing",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "loa",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "loxp",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "lacz",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chr1",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chr8a",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chr8b",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chr11a",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chr11b",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "chry",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "es_cell_id",
  { data_type => "integer", is_nullable => 1 },
  "es_cell_distribution_centre_id",
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

=head2 C<index_distribution_qcs_centre_es_cell>

=over 4

=item * L</es_cell_distribution_centre_id>

=item * L</es_cell_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_distribution_qcs_centre_es_cell",
  ["es_cell_distribution_centre_id", "es_cell_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/ymx3HKQoI4dUCysRJ+67w

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->belongs_to(
  "targ_rep_escell",
  "Tarmits::Schema::Result::TargRepEsCell",
  { id => "es_cell_id" },
  { is_deferrable => 1},
);

__PACKAGE__->belongs_to(
  "targ_rep_es_cell_distribution_centre",
  "Tarmits::Schema::Result::TargRepEsCellDistributionCentre",
  { id => "es_cell_distribution_centre_id" },
  { is_deferrable => 1},
);

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
