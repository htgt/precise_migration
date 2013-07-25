package HTGTDB::GRCAltCloneAlternate;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRCAltCloneAlternate.pm $
# $LastChangedRevision: 1261 $
# $LastChangedDate: 2010-03-10 16:05:51 +0000 (Wed, 10 Mar 2010) $
# $LastChangedBy: rm7 $

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('grc_alt_clone_alternate');

#__PACKAGE__->add_columns( qw/grc_alt_clone_alternate_id gr_gene_status_id alt_clone_well_id/ );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "grc_alt_clone_alternate_id",
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
  "alt_clone_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'grc_alt_clone_alternate_id' );

__PACKAGE__->belongs_to( gene_recovery => 'HTGTDB::GRGeneStatus', 'gr_gene_status_id' );

__PACKAGE__->belongs_to( alternate_well => 'HTGTDB::Well', 'alt_clone_well_id' );

1;

__END__
