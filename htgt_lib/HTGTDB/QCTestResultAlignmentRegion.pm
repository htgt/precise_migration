package HTGTDB::QCTestResultAlignmentRegion;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

use HTGT::QC::Util::Alignment;

__PACKAGE__->table( 'qc_test_result_align_regions' );

#__PACKAGE__->add_columns(
#    qw( qc_test_result_alignment_id
#        name
#        length
#        match_count
#        query_str
#        target_str
#        match_str
#        pass
#    )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "length",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "match_count",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_str",
  { data_type => "clob", is_nullable => 0 },
  "target_str",
  { data_type => "clob", is_nullable => 0 },
  "match_str",
  { data_type => "clob", is_nullable => 0 },
  "pass",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_test_result_alignment_id', 'name' );

__PACKAGE__->belongs_to( 'alignment' => 'HTGTDB::QCTestResultAlignment' => 'qc_test_result_alignment_id' );

sub format_alignment {
    my ( $self, $line_len, $header_len ) = @_;

    my $strand = $self->alignment->target_strand == 1 ? '+' : '-';
    
    HTGT::QC::Util::Alignment::format_alignment(
        target_id  => "Target ($strand)",
        target_str => $self->target_str,
        query_id   => 'Sequence Read',
        query_str  => $self->query_str,
        match_str  => $self->match_str,
        line_len   => $line_len,
        header_len => $header_len
    );
}

1;

__END__
