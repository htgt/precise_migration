package HTGTDB::QCTestResultAlignment;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

__PACKAGE__->table( 'qc_test_result_alignments' );

#__PACKAGE__->add_columns(
#    qw( qc_test_result_alignment_id
#        qc_seq_read_id primer_name
#        query_start query_end query_strand
#        target_start target_end target_strand
#        op_str score pass features cigar )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_seq_read_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 128 },
  "primer_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "query_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "target_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "score",
  {
    data_type => "numeric",
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
  "op_str",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "cigar",
  { data_type => "varchar2", is_nullable => 0, size => 2048 },
  "features",
  {
    data_type => "varchar2",
    default_value => "",
    is_nullable => 0,
    size => 2048,
  },
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_test_result_alignment_id' );

__PACKAGE__->belongs_to( 'seq_read' => 'HTGTDB::QCSeqRead' => 'qc_seq_read_id' );

__PACKAGE__->has_many( align_regions => 'HTGTDB::QCTestResultAlignmentRegion' => 'qc_test_result_alignment_id' );

__PACKAGE__->has_many( 'test_result_alignment_maps',
                       'HTGTDB::QCTestResultAlignmentMap',
                       'qc_test_result_alignment_id' );

__PACKAGE__->many_to_many( 'test_results', 'test_result_alignment_maps', 'test_result' );

sub align_length {
    my $self = shift;

    abs( $self->target_end - $self->target_start );
}

1;

__END__
