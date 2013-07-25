use utf8;
package HTGTDB::Result::Allele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Allele

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ALLELE>

=cut

__PACKAGE__->table("ALLELE");

=head1 ACCESSORS

=head2 allele_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_allele'
  size: 126

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 bacs

  data_type: 'varchar2'
  is_nullable: 0
  size: 40

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 0
  size: 80

=head2 esc_strain

  data_type: 'varchar2'
  is_nullable: 0
  size: 40

=head2 labcode

  data_type: 'varchar2'
  is_nullable: 0
  size: 40

=head2 current_allele_name_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 targeted_trap

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 deletion

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 mgi_gene_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=cut

__PACKAGE__->add_columns(
  "allele_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_allele",
    size => 126,
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "bacs",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "cassette",
  { data_type => "varchar2", is_nullable => 0, size => 80 },
  "esc_strain",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "labcode",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "current_allele_name_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "deletion",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "mgi_gene_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</allele_id>

=back

=cut

__PACKAGE__->set_primary_key("allele_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<allele_uk1>

=over 4

=item * L</design_id>

=item * L</bacs>

=item * L</cassette>

=item * L</esc_strain>

=item * L</labcode>

=item * L</targeted_trap>

=item * L</deletion>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "allele_uk1",
  [
    "design_id",
    "bacs",
    "cassette",
    "esc_strain",
    "labcode",
    "targeted_trap",
    "deletion",
  ],
);

=head2 C<allele_uk2>

=over 4

=item * L</current_allele_name_id>

=back

=cut

__PACKAGE__->add_unique_constraint("allele_uk2", ["current_allele_name_id"]);

=head1 RELATIONS

=head2 allele_names

Type: has_many

Related object: L<HTGTDB::Result::AlleleName>

=cut

__PACKAGE__->has_many(
  "allele_names",
  "HTGTDB::Result::AlleleName",
  { "foreign.allele_id" => "self.allele_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 current_allele_name

Type: belongs_to

Related object: L<HTGTDB::Result::AlleleName>

=cut

__PACKAGE__->belongs_to(
  "current_allele_name",
  "HTGTDB::Result::AlleleName",
  { allele_name_id => "current_allele_name_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 mgi_gene

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneIdMap>

=cut

__PACKAGE__->belongs_to(
  "mgi_gene",
  "HTGTDB::Result::MgiGeneIdMap",
  { mgi_gene_id => "mgi_gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:krxr17KasDKqAnemr9zGtw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
