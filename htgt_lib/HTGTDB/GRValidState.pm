package HTGTDB::GRValidState;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRValidState.pm $
# $LastChangedRevision: 1261 $
# $LastChangedDate: 2010-03-10 16:05:51 +0000 (Wed, 10 Mar 2010) $
# $LastChangedBy: rm7 $

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('gr_valid_state');

#__PACKAGE__->add_columns(qw/state description/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "state",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'state' );

__PACKAGE__->has_many( 'gr_gene_status' => 'HTGTDB::GRGeneStatus', 'state' );

1;

__END__
