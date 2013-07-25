use utf8;
package HTGTDB::Result::DaTargetRegionGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DaTargetRegionGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DA_TARGET_REGION_GENE>

=cut

__PACKAGE__->table("DA_TARGET_REGION_GENE");

=head1 ACCESSORS

=head2 target_region_gene_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_da_target_region_gene'
  size: [10,0]

=head2 design_annotation_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "target_region_gene_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_da_target_region_gene",
    size => [10, 0],
  },
  "design_annotation_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_id",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</target_region_gene_id>

=back

=cut

__PACKAGE__->set_primary_key("target_region_gene_id");

=head1 RELATIONS

=head2 design_annotation

Type: belongs_to

Related object: L<HTGTDB::Result::DesignAnnotation>

=cut

__PACKAGE__->belongs_to(
  "design_annotation",
  "HTGTDB::Result::DesignAnnotation",
  { design_annotation_id => "design_annotation_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g/awK8Xa80TRLLgoR8r85w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
