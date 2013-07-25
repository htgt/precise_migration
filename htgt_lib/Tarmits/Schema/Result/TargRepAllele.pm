use utf8;
package Tarmits::Schema::Result::TargRepAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::TargRepAllele

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

=head1 TABLE: C<targ_rep_alleles>

=cut

__PACKAGE__->table("targ_rep_alleles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'targ_rep_alleles_id_seq'

=head2 gene_id

  data_type: 'integer'
  is_nullable: 1

=head2 assembly

  data_type: 'varchar'
  default_value: 'NCBIM37'
  is_nullable: 0
  size: 50

=head2 chromosome

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 strand

  data_type: 'varchar'
  is_nullable: 0
  size: 1

=head2 homology_arm_start

  data_type: 'integer'
  is_nullable: 0

=head2 homology_arm_end

  data_type: 'integer'
  is_nullable: 0

=head2 loxp_start

  data_type: 'integer'
  is_nullable: 1

=head2 loxp_end

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_start

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_end

  data_type: 'integer'
  is_nullable: 1

=head2 cassette

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 backbone

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 subtype_description

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 floxed_start_exon

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 floxed_end_exon

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 project_design_id

  data_type: 'integer'
  is_nullable: 1

=head2 reporter

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mutation_method_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_type_id

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_subtype_id

  data_type: 'integer'
  is_nullable: 1

=head2 cassette_type

  data_type: 'varchar'
  is_nullable: 1
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
    sequence          => "targ_rep_alleles_id_seq",
  },
  "gene_id",
  { data_type => "integer", is_nullable => 1 },
  "assembly",
  {
    data_type => "varchar",
    default_value => "NCBIM37",
    is_nullable => 0,
    size => 50,
  },
  "chromosome",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "strand",
  { data_type => "varchar", is_nullable => 0, size => 1 },
  "homology_arm_start",
  { data_type => "integer", is_nullable => 0 },
  "homology_arm_end",
  { data_type => "integer", is_nullable => 0 },
  "loxp_start",
  { data_type => "integer", is_nullable => 1 },
  "loxp_end",
  { data_type => "integer", is_nullable => 1 },
  "cassette_start",
  { data_type => "integer", is_nullable => 1 },
  "cassette_end",
  { data_type => "integer", is_nullable => 1 },
  "cassette",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "backbone",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "subtype_description",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "floxed_start_exon",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "floxed_end_exon",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "project_design_id",
  { data_type => "integer", is_nullable => 1 },
  "reporter",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mutation_method_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_type_id",
  { data_type => "integer", is_nullable => 1 },
  "mutation_subtype_id",
  { data_type => "integer", is_nullable => 1 },
  "cassette_type",
  { data_type => "varchar", is_nullable => 1, size => 50 },
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


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Njigetp6dbjze1sQlRDJUA

# NOTE Currently Foreign keys are missing from TargRep tables. Therefore relationships have been defined manually.
# If Foreign keys are add to this table we may see relationships defined multiple times.

__PACKAGE__->has_many(
  "targ_rep_es_cells",
  "Tarmits::Schema::Result::TargRepEsCell",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 genbank_files

Type: has_many

Related object: L<Tarmits::Schema::Result::GenbankFile>

=cut

__PACKAGE__->has_many(
  "targ_rep_genbank_files",
  "Tarmits::Schema::Result::TargRepGenbankFile",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targeting_vectors

Type: has_many

Related object: L<Tarmits::Schema::Result::TargetingVector>

=cut

__PACKAGE__->has_many(
  "targ_rep_targeting_vectors",
  "Tarmits::Schema::Result::TargRepTargetingVector",
  { "foreign.allele_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene

Type: belongs_to

Related object: L<Tarmits::Schema::Result::Gene>

=cut

__PACKAGE__->belongs_to(
  "gene",
  "Tarmits::Schema::Result::Gene",
  { id => "gene_id" },
);

=head2 mutation_method

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationMethod>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_method",
  "Tarmits::Schema::Result::TargRepMutationMethod",
  { id => "mutation_method_id" },
);

=head2 mutation_type

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationType>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_type",
  "Tarmits::Schema::Result::TargRepMutationType",
  { id => "mutation_type_id" },
);

=head2 mutation_method

Type: belongs_to

Related object: L<Tarmits::Schema::Result::MutationSubtype>

=cut

__PACKAGE__->belongs_to(
  "targ_rep_mutation_subtype",
  "Tarmits::Schema::Result::TargRepMutationSubtype",
  { id => "mutation_subtype_id" },
);

sub mutation_type_name {
    my $self = shift;

    return $self->targ_rep_mutation_type->name;
}

sub mutation_subtype_name {
    my $self = shift;
    return unless $self->targ_rep_mutation_subtype;
    return $self->targ_rep_mutation_subtype->name;
}

sub mutation_method_name {
    my $self = shift;

    return $self->targ_rep_mutation_method->name;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
