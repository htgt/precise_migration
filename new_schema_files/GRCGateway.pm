package HTGTDB::GRCGateway;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRCGateway.pm $
# $LastChangedRevision: 1408 $
# $LastChangedDate: 2010-03-31 10:21:37 +0100 (Wed, 31 Mar 2010) $
# $LastChangedBy: rm7 $

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('grc_gateway');

#__PACKAGE__->add_columns( qw( grc_gateway_id gr_gene_status_id pcs_well_id valid_primers ) );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "grc_gateway_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "gr_gene_status_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "pcs_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "valid_primers",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'grc_gateway_id' );

__PACKAGE__->belongs_to( gene_recovery => 'HTGTDB::GRGeneStatus', 'gr_gene_status_id' );

__PACKAGE__->belongs_to( pcs_well => 'HTGTDB::Well', 'pcs_well_id' );

1;

__END__
