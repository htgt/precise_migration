package HTGTDB::GRRedesign;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRRedesign.pm $
# $LastChangedRevision: 1248 $
# $LastChangedDate: 2010-03-09 16:03:32 +0000 (Tue, 09 Mar 2010) $
# $LastChangedBy: rm7 $

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gr_redesign');

#__PACKAGE__->add_columns( qw/gr_redesign_id gr_gene_status_id rdr_well_id/ );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gr_redesign_id",
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
  "rdr_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'gr_redesign_id' );

__PACKAGE__->belongs_to( gene_recovery => 'HTGTDB::GRGeneStatus', 'gr_gene_status_id' );

__PACKAGE__->belongs_to( rdr_well => 'HTGTDB::Well', 'rdr_well_id' );

1;

__END__
