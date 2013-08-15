package HTGTDB::GRGeneStatusHistory;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRGeneStatus.pm $
# $LastChangedRevision: 1279 $
# $LastChangedDate: 2010-03-15 17:02:04 +0000 (Mon, 15 Mar 2010) $
# $LastChangedBy: rm7 $

use base 'DBIx::Class';

use DateTime;

__PACKAGE__->load_components(qw/InflateColumn::DateTime PK::Auto Core/);

__PACKAGE__->table('gr_gene_status_history');

#__PACKAGE__->add_columns( 'gr_gene_status_history_id', 'mgi_gene_id', 'state', 'note', 'updated' => { data_type => 'datetime' } );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gr_gene_status_history_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "state",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "updated",
  { data_type => "datetime", is_nullable => 0 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'gr_gene_status_history_id' );

__PACKAGE__->belongs_to( status => 'HTGTDB::GRValidState', 'state' );

__PACKAGE__->belongs_to( mgi_gene => 'HTGTDB::MGIGene', 'mgi_gene_id' );

1;

__END__
