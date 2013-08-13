package HTGTDB::QCSeqRead;

use strict;
use warnings FATAL => 'all';

use Bio::Seq;

use base qw( DBIx::Class::Core );

my $SEQ_READ_ID_RX = qr/^
                               (.+)          # Plate name
                               (\w+\d\d)     # Well name
                               \.p1k[a-z]?
                               (.+)          # Primer name
                               $/x;

__PACKAGE__->table( 'qc_seq_reads' );

#__PACKAGE__->add_columns(
#    qw( qc_seq_read_id description length seq )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_seq_read_id",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "description",
  { data_type => "varchar2", default_value => "", is_nullable => 0, size => 200 },
  "seq",
  { data_type => "clob", is_nullable => 0 },
  "length",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_seq_read_id' );

__PACKAGE__->has_many( 'alignments' => 'HTGTDB::QCTestResultAlignment' => 'qc_seq_read_id' );

__PACKAGE__->has_many( 'qc_run_seq_reads' => 'HTGTDB::QCRunSeqRead', 'qc_seq_read_id' );

__PACKAGE__->many_to_many( 'qc_runs' => 'qc_run_seq_reads', 'qc_run' );

sub bio_seq {
    my $self = shift;    
    
    Bio::Seq->new(
        -display_id => $self->qc_seq_read_id,
        -desc       => $self->description,
        -alphabet   => 'dna',
        -seq        => $self->seq
    );
}

sub _parse_qc_seq_read_id {
    my $self = shift;

    my ( $plate_name, $well_name, $primer_name ) = $self->qc_seq_read_id =~ $SEQ_READ_ID_RX;

    return +{
        plate_name  => $plate_name,
        well_name   => $well_name,
        primer_name => $primer_name
    };
}

sub plate_name {
    shift->_parse_qc_seq_read_id->{plate_name};
}

sub well_name {
    shift->_parse_qc_seq_read_id->{well_name};
}

sub primer_name {
    shift->_parse_qc_seq_read_id->{primer_name};
}

sub _get_seq_read_regex { 
  return $SEQ_READ_ID_RX 
}

1;

__END__
