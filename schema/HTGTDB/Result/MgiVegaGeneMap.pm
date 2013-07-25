use utf8;
package HTGTDB::Result::MgiVegaGeneMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiVegaGeneMap

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_VEGA_GENE_MAP>

=cut

__PACKAGE__->table("MGI_VEGA_GENE_MAP");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 100

=head2 vega_gene_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
  "vega_gene_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mgi_accession_id>

=item * L</vega_gene_id>

=back

=cut

__PACKAGE__->set_primary_key("mgi_accession_id", "vega_gene_id");

=head1 RELATIONS

=head2 mgi_accession

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneData>

=cut

__PACKAGE__->belongs_to(
  "mgi_accession",
  "HTGTDB::Result::MgiGeneData",
  { mgi_accession_id => "mgi_accession_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 vega_gene

Type: belongs_to

Related object: L<HTGTDB::Result::VegaGeneData>

=cut

__PACKAGE__->belongs_to(
  "vega_gene",
  "HTGTDB::Result::VegaGeneData",
  { vega_gene_id => "vega_gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZoEYFkC92MAhiPnJTud2Kg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
