package HTGTDB::CachedRegeneronStatus;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components( qw( InflateColumn::DateTime Core ) );

__PACKAGE__->table( 'cached_regeneron_status' );

#__PACKAGE__->add_columns(
#    'mgi_accession_id',
#    'status',
#    'last_updated' => { data_type => 'datetime' }, 
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "status",
  {
    data_type => "varchar2",
    default_value => "(none)",
    is_nullable => 0,
    size => 200,
  },
  "last_updated",
  { data_type => "datetime", is_nullable => 0 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'mgi_accession_id' );

__PACKAGE__->belongs_to( mgi_gene => 'HTGTDB::MGIGene', { 'foreign.mgi_accession_id' => 'self.mgi_accession_id' } );

1;

__END__
