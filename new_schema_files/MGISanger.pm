package HTGTDB::MGISanger;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
Darren Oakley

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mgi_sanger');

__PACKAGE__->sequence('S_MGI_SANGER');

#__PACKAGE__->add_columns(
#    qw/
#      mgi_sanger_id
#      mgi_gene_id
#      mgi_accession_id
#      marker_symbol
#      marker_name
#      cm_position
#      chromosome
#      sanger_gene_id
#      origin
#      otter_import
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_sanger_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_mgi_sanger",
    size => [10, 0],
  },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "marker_name",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "cm_position",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "sanger_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "origin",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "otter_import",
  {
    data_type => "numeric",
    default_value => \"null",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('mgi_sanger_id');

__PACKAGE__->belongs_to( mgi_gene => "HTGTDB::MGIGene", 'mgi_gene_id' );

return 1;

