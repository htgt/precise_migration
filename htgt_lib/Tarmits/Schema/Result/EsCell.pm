use utf8;
package Tarmits::Schema::Result::EsCell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::EsCell

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

=head1 TABLE: C<es_cells>

=cut

__PACKAGE__->table("es_cells");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'es_cells_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 allele_symbol_superscript_template

  data_type: 'varchar'
  is_nullable: 1
  size: 75

=head2 allele_type

  data_type: 'varchar'
  is_nullable: 1
  size: 2

=head2 pipeline_id

  data_type: 'integer'
  is_nullable: 0

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 gene_id

  data_type: 'integer'
  is_nullable: 0

=head2 parental_cell_line

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 ikmc_project_id

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 mutation_subtype

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 allele_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "es_cells_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "allele_symbol_superscript_template",
  { data_type => "varchar", is_nullable => 1, size => 75 },
  "allele_type",
  { data_type => "varchar", is_nullable => 1, size => 2 },
  "pipeline_id",
  { data_type => "integer", is_nullable => 0 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "gene_id",
  { data_type => "integer", is_nullable => 0 },
  "parental_cell_line",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "ikmc_project_id",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "mutation_subtype",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "allele_id",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_es_cells_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_es_cells_on_name", ["name"]);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sBLw9VW6XCWBMWuXwUTCuw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
