package HTGTDB::MGIEnsemblGeneMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::MGIEnsemblGeneMap

=cut

__PACKAGE__->table("mgi_ensembl_gene_map");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 100

=head2 ensembl_gene_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 100

=cut

#__PACKAGE__->add_columns(
#  "mgi_accession_id",
#  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
#  "ensembl_gene_id",
#  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
  "ensembl_gene_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 100 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key("mgi_accession_id","ensembl_gene_id");

=head1 RELATIONS

=head2 ensembl_gene

Type: belongs_to

Related object: L<HTGTDB::EnsemblGeneData>

=cut

__PACKAGE__->belongs_to(
  "ensembl_gene",
  "HTGTDB::EnsemblGeneData",
  { ensembl_gene_id => "ensembl_gene_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 mgi_accession

Type: belongs_to

Related object: L<HTGTDB::MGIGeneData>

=cut

__PACKAGE__->belongs_to(
  "mgi_accession",
  "HTGTDB::MGIGeneData",
  { mgi_accession_id => "mgi_accession_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:u78Rrt4Y8+ZED6M7JXdvsQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
