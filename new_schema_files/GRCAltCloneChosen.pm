package HTGTDB::GRCAltCloneChosen;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRCAltCloneChosen.pm $
# $LastChangedRevision: 1277 $
# $LastChangedDate: 2010-03-15 10:52:35 +0000 (Mon, 15 Mar 2010) $
# $LastChangedBy: rm7 $

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('grc_alt_clone_chosen');

#__PACKAGE__->add_columns( qw/grc_alt_clone_chosen_id gr_gene_status_id chosen_well_id chosen_clone_name child_plates/ );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "grc_alt_clone_chosen_id",
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
  "chosen_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "chosen_clone_name",
  { data_type => "varchar2", is_nullable => 0, size => 200 },
  "child_plates",
  { data_type => "varchar2", is_nullable => 0, size => 400 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'grc_alt_clone_chosen_id' );

__PACKAGE__->belongs_to( gene_recovery => 'HTGTDB::GRGeneStatus', 'gr_gene_status_id' );

__PACKAGE__->belongs_to( chosen_well => 'HTGTDB::Well', 'chosen_well_id' );


1;

__END__
