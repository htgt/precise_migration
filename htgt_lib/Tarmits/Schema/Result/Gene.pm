use utf8;
package Tarmits::Schema::Result::Gene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::Gene

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

=head1 TABLE: C<genes>

=cut

__PACKAGE__->table("genes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genes_id_seq'

=head2 marker_symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 75

=head2 mgi_accession_id

  data_type: 'varchar'
  is_nullable: 1
  size: 40

=head2 ikmc_projects_count

  data_type: 'integer'
  is_nullable: 1

=head2 conditional_es_cells_count

  data_type: 'integer'
  is_nullable: 1

=head2 non_conditional_es_cells_count

  data_type: 'integer'
  is_nullable: 1

=head2 deletion_es_cells_count

  data_type: 'integer'
  is_nullable: 1

=head2 other_targeted_mice_count

  data_type: 'integer'
  is_nullable: 1

=head2 other_condtional_mice_count

  data_type: 'integer'
  is_nullable: 1

=head2 mutation_published_as_lethal_count

  data_type: 'integer'
  is_nullable: 1

=head2 publications_for_gene_count

  data_type: 'integer'
  is_nullable: 1

=head2 go_annotations_for_gene_count

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
    sequence          => "genes_id_seq",
  },
  "marker_symbol",
  { data_type => "varchar", is_nullable => 0, size => 75 },
  "mgi_accession_id",
  { data_type => "varchar", is_nullable => 1, size => 40 },
  "ikmc_projects_count",
  { data_type => "integer", is_nullable => 1 },
  "conditional_es_cells_count",
  { data_type => "integer", is_nullable => 1 },
  "non_conditional_es_cells_count",
  { data_type => "integer", is_nullable => 1 },
  "deletion_es_cells_count",
  { data_type => "integer", is_nullable => 1 },
  "other_targeted_mice_count",
  { data_type => "integer", is_nullable => 1 },
  "other_condtional_mice_count",
  { data_type => "integer", is_nullable => 1 },
  "mutation_published_as_lethal_count",
  { data_type => "integer", is_nullable => 1 },
  "publications_for_gene_count",
  { data_type => "integer", is_nullable => 1 },
  "go_annotations_for_gene_count",
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

=head2 C<index_genes_on_marker_symbol>

=over 4

=item * L</marker_symbol>

=back

=cut

__PACKAGE__->add_unique_constraint("index_genes_on_marker_symbol", ["marker_symbol"]);

=head2 C<index_genes_on_mgi_accession_id>

=over 4

=item * L</mgi_accession_id>

=back

=cut

__PACKAGE__->add_unique_constraint("index_genes_on_mgi_accession_id", ["mgi_accession_id"]);

=head1 RELATIONS

=head2 mi_plans

Type: has_many

Related object: L<Tarmits::Schema::Result::MiPlan>

=cut

__PACKAGE__->has_many(
  "mi_plans",
  "Tarmits::Schema::Result::MiPlan",
  { "foreign.gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targ_rep_allele

Type: has_many

Related object: L<Tarmits::Schema::Result::TargRepAllele>

=cut

__PACKAGE__->has_many(
  "targ_rep_allele",
  "Tarmits::Schema::Result::TargRepAllele",
  { "foreign.gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 notifications

Type: has_many

Related object: L<Tarmits::Schema::Result::Notification>

=cut

__PACKAGE__->has_many(
  "notifications",
  "Tarmits::Schema::Result::Notification",
  { "foreign.gene_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VjFmYbr/NHH/Ddgi2q7lIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
