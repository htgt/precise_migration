package HTGTDB::QCTestResult;

use strict;
use warnings FATAL => 'all';

use List::Util qw( sum );

use base qw( DBIx::Class::Core );

__PACKAGE__->table( 'qc_test_results' );

#__PACKAGE__->add_columns(
#    qw( qc_test_result_id qc_run_id qc_synvec_id plate_name well_name score pass )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_test_result_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "qc_test_results_seq",
    size => [10, 0],
  },
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "qc_synvec_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "well_name",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "score",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pass",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "plate_name",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_test_result_id' );

__PACKAGE__->belongs_to( 'qc_run' => 'HTGTDB::QCRun' => 'qc_run_id' );

__PACKAGE__->belongs_to( 'synvec' => 'HTGTDB::QCSynvec' => 'qc_synvec_id' );

__PACKAGE__->has_many( 'test_result_alignment_maps',
                       'HTGTDB::QCTestResultAlignmentMap',
                       'qc_test_result_id' );

__PACKAGE__->many_to_many( 'alignments', 'test_result_alignment_maps', 'alignment' );

sub valid_primers {
    my $self = shift;    

    [ sort map { $_->primer_name } grep { $_->pass } $self->alignments ];
}

sub valid_primer_score {
    my $self = shift;

    sum( map { $_->score } grep { $_->pass } $self->alignments );
}

1;

__END__

