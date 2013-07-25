package HTGTDB::QCRunSeqRead;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

__PACKAGE__->table( 'qc_run_seq_read' );

#__PACKAGE__->add_columns( qw( qc_run_id qc_seq_read_id ) );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "qc_seq_read_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 128 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_run_id', 'qc_seq_read_id' );

__PACKAGE__->belongs_to( 'qc_run' => 'HTGTDB::QCRun' => 'qc_run_id' );

__PACKAGE__->belongs_to( 'seq_read' => 'HTGTDB::QCSeqRead' => 'qc_seq_read_id' );

1;

__END__
