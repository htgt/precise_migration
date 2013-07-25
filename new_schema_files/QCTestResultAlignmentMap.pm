package HTGTDB::QCTestResultAlignmentMap;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

__PACKAGE__->table( 'qc_test_result_alignment_map' );

#__PACKAGE__->add_columns( qw( qc_test_result_id qc_test_result_alignment_id ) );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_test_result_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( qw( qc_test_result_id qc_test_result_alignment_id ) );

__PACKAGE__->belongs_to( 'alignment',
                         'HTGTDB::QCTestResultAlignment',
                         'qc_test_result_alignment_id'
                     );

__PACKAGE__->belongs_to(
    'test_result',
    'HTGTDB::QCTestResult',
    'qc_test_result_id'
);

1;

__END__
