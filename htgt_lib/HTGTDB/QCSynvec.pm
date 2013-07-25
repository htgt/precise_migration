package HTGTDB::QCSynvec;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

use Bio::SeqIO;
use IO::String;

__PACKAGE__->table( 'qc_synvecs' );

#__PACKAGE__->add_columns(
#    qw( qc_synvec_id design_id cassette backbone vector_stage apply_flp apply_cre apply_dre genbank )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_synvec_id",
  { data_type => "char", is_nullable => 0, size => 40 },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "cassette",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "apply_flp",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "apply_cre",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "genbank",
  { data_type => "clob", is_nullable => 0 },
  "vector_stage",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "apply_dre",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'qc_synvec_id' );

__PACKAGE__->has_many( 'test_results' => 'HTGTDB::QCTestResult' => 'qc_synvec_id' );

__PACKAGE__->belongs_to( 'design' => 'HTGTDB::Design' => 'design_id' );

sub bio_seq {
    my $self = shift;

    my $seq_io = Bio::SeqIO->new( -fh     => IO::String->new( $self->genbank ),
                                  -format => 'genbank' );
    
    return $seq_io->next_seq;
}

sub mgi_gene {
    my $self = shift;

    $self->design->projects_rs->first->mgi_gene;    
}

1;

__END__
