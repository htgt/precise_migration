package HTGTDB::MGIGeneIdMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

HTGTDB::MGIGeneIdMap

=cut

__PACKAGE__->table("mgi_gene_id_map");

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

#__PACKAGE__->add_columns(
#  "mgi_gene_id",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "mgi_accession_id",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
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
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key("mgi_gene_id");


# Created by DBIx::Class::Schema::Loader v0.07008 @ 2011-04-04 13:01:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zcj0NsDNKyhvj7n/bnhuSg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
