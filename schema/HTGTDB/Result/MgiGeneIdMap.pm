use utf8;
package HTGTDB::Result::MgiGeneIdMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiGeneIdMap

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_GENE_ID_MAP>

=cut

__PACKAGE__->table("MGI_GENE_ID_MAP");

=head1 ACCESSORS

=head2 mgi_gene_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mgi_gene_id>

=back

=cut

__PACKAGE__->set_primary_key("mgi_gene_id");

=head1 RELATIONS

=head2 alleles

Type: has_many

Related object: L<HTGTDB::Result::Allele>

=cut

__PACKAGE__->has_many(
  "alleles",
  "HTGTDB::Result::Allele",
  { "foreign.mgi_gene_id" => "self.mgi_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gene_comments

Type: has_many

Related object: L<HTGTDB::Result::GeneComment>

=cut

__PACKAGE__->has_many(
  "gene_comments",
  "HTGTDB::Result::GeneComment",
  { "foreign.mgi_gene_id" => "self.mgi_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_gene_status

Type: might_have

Related object: L<HTGTDB::Result::GrGeneStatus>

=cut

__PACKAGE__->might_have(
  "gr_gene_status",
  "HTGTDB::Result::GrGeneStatus",
  { "foreign.mgi_gene_id" => "self.mgi_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_gene_status_histories

Type: has_many

Related object: L<HTGTDB::Result::GrGeneStatusHistory>

=cut

__PACKAGE__->has_many(
  "gr_gene_status_histories",
  "HTGTDB::Result::GrGeneStatusHistory",
  { "foreign.mgi_gene_id" => "self.mgi_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summaries

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summaries",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.mgi_gene_id" => "self.mgi_gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kpBVcy6rxaBzRb8xQOfo7g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
