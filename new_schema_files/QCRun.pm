package HTGTDB::QCRun;

use strict;
use warnings FATAL => 'all';

use base qw( DBIx::Class::Core );

use DateTime::Format::Oracle;

__PACKAGE__->table( 'qc_runs' );

#__PACKAGE__->add_columns(
#    qw( qc_run_id qc_run_date sequencing_project template_plate_id profile software_version plate_map )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "qc_run_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "sequencing_project",
  { data_type => "varchar2", is_nullable => 0, size => 512 },
  "profile",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "template_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "software_version",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "plate_map",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
);
# End of dbicdump add_columns data

__PACKAGE__->inflate_column(    
    qc_run_date => {
        inflate => sub {
            # The NLS_TIMESTAMP_FORMAT environment variable has no
            # effect on the value of qc_run_date returned by Oracle
            # (unless we wrap the select in TO_CHAR). We override the
            # value here to force DateTime::Format::Oracle to use the
            # default Oracle setting, ignoring the
            # NLS_TIMESTAMP_FORMAT set elsewhere.
            local $ENV{NLS_TIMESTAMP_FORMAT} = 'DD-MON-RR HH24.MI.SSXFF';
            DateTime::Format::Oracle->parse_timestamp(shift);            
        },
        deflate => sub {
            local $ENV{NLS_TIMESTAMP_FORMAT} = 'DD-MON-RR HH24.MI.SSXFF';
            DateTime::Format::Oracle->format_timestamp(shift);            
        }
    }
);

__PACKAGE__->set_primary_key( 'qc_run_id' );

__PACKAGE__->belongs_to( template_plate => 'HTGTDB::Plate', 'template_plate_id' );

__PACKAGE__->has_many( 'test_results' => 'HTGTDB::QCTestResult', 'qc_run_id' );

__PACKAGE__->has_many( 'qc_run_seq_reads' => 'HTGTDB::QCRunSeqRead', 'qc_run_id' );

__PACKAGE__->many_to_many( 'seq_reads' => 'qc_run_seq_reads', 'seq_read' );

sub count_designs {
    my $self = shift;

    $self->template_plate->search_related_rs(
        wells => {
            'me.design_instance_id' => { '!=', undef}
        },
        {
            join     => { 'design_instance' => 'design' },
            columns  => [ 'design.design_id' ],
            distinct => 1
        }
    )->count;
}

sub count_observed_designs {
    my $self = shift;

    $self->search_related_rs(
        test_results => {},
        {
            join     => 'synvec',
            columns  => [ 'synvec.design_id' ],
            distinct => 1
        }
    )->count;
}

sub count_valid_designs {
    my $self = shift;

    $self->search_related_rs(
        test_results => {
            'me.pass' => 1
        },
        {
            join     => 'synvec',
            columns  => [ 'synvec.design_id' ],
            distinct => 1
        }
    )->count;
}

sub primers {
    my $self = shift;

    map $_->primer_name,
        $self->search_related_rs(
            test_results => {}
        )->search_related_rs(
            test_result_alignment_maps => {}
        )->search_related_rs(
            alignment => {},
            { columns => [ 'primer_name' ], distinct => 1, order_by => { -asc => 'primer_name' } }
        )->all;
}

sub plates {
    my $self = shift;

    map $_->plate_name,
        $self->search_related_rs(
            test_results => {},
            { columns => [ 'plate_name' ], distinct => 1, order_by => { -asc => 'plate_name' } }
        )->all;
}

#attempt to get all seq reads related to this qc run for a given well and plate.
#it isnt very nice but it is twice as fast as dbix::class.
#returns a list of QCSeqRead objects, but they are not actual database objects.
sub get_seq_reads {
    my ( $self, $plate_name, $well_name ) = @_;

    my $query_sql = <<'QUERY';
SELECT seq_read.qc_seq_read_id, seq_read.description, seq_read.length, seq_read.seq 
FROM qc_run_seq_read me
JOIN qc_seq_reads seq_read ON seq_read.qc_seq_read_id = me.qc_seq_read_id 
WHERE me.qc_run_id = ? 
AND me.qc_seq_read_id LIKE ?
QUERY

    my @seq_reads;
    $self->result_source->schema->storage->dbh_do(
        sub {
            my $sth = $_[1]->prepare( $query_sql );
            #try ETPCS00281_C_1% and check the well name ourselves 
            $sth->execute( $self->qc_run_id, $plate_name . '%' ); 

            while( my $r = $sth->fetchrow_hashref ) {
                #disgard other wells
                next unless $r->{QC_SEQ_READ_ID} =~ /$well_name/i;

                #create a QCSeqRead object for the purpose of using the model functions
                #such as primer name ONLY. this should NOT be used to manipulate data.
                my $sr = $self->result_source->schema->resultset( 'QCSeqRead' )->new( {
                    qc_seq_read_id => $r->{QC_SEQ_READ_ID},
                    description    => $r->{DESCRIPTION},
                    length         => $r->{LENGTH},
                    seq            => $r->{SEQ},
                } );

                push @seq_reads, $sr;
            }
        }
    );

    return @seq_reads;
}

#get all the test result information required by NewQC::view_result. 
#it may also be useful elsewhere. It is not very nice but 3-4x faster than DBIx::Class.
#it returns a hash (which contains actual QCSeqRead objects as in the previous function)
sub get_test_results_for_well {
    my ( $self, $plate_name, $well_name ) = @_;

    #the parameters should be validated...

    my $query_sql = <<'QUERY';
SELECT me.score, me.pass, me.qc_synvec_id, me.qc_test_result_id, synvec.design_id as synvec_design_id, 
alignment.primer_name as alignment_primer_name,
alignment.pass as alignment_primer_pass,
alignment.score as alignment_score,
alignment.query_start as alignment_query_start,
alignment.query_end as alignment_query_end,
alignment.features as alignment_features,
alignment.qc_seq_read_id as alignment_qc_seq_read_id,
seq_read.length as seq_read_length,
seq_read.qc_seq_read_id as seq_read_qc_seq_read_id, 
seq_read.description as seq_read_description, 
seq_read.seq as seq_read_seq
FROM qc_test_results me 
LEFT JOIN qc_test_result_alignment_map alignment_map ON alignment_map.qc_test_result_id = me.qc_test_result_id 
LEFT JOIN qc_test_result_alignments alignment ON alignment.qc_test_result_alignment_id = alignment_map.qc_test_result_alignment_id 
LEFT JOIN qc_seq_reads seq_read ON seq_read.qc_seq_read_id = alignment.qc_seq_read_id  
JOIN qc_synvecs synvec ON synvec.qc_synvec_id = me.qc_synvec_id  
JOIN design design ON design.design_id = synvec.design_id 
WHERE ( ( ( plate_name = ? AND well_name = ? ) AND me.qc_run_id = ? ) )  
ORDER BY me.score DESC, alignment_map.qc_test_result_id
QUERY

    my @qc_results;
    $self->result_source->schema->storage->dbh_do(
        sub {
            my $sth = $_[1]->prepare( $query_sql );
            $sth->execute( $plate_name, $well_name, $self->qc_run_id );

            #get the initial row
            my $r = $sth->fetchrow_hashref;

            while( $r ) {
                my $result = {
                    score             => $r->{SCORE},
                    pass              => $r->{PASS},
                    qc_synvec_id      => $r->{QC_SYNVEC_ID},
                    qc_test_result_id => $r->{QC_TEST_RESULT_ID},
                    #this is the only value accessed from synvec, more can be added if necessary.
                    synvec            => { design_id => $r->{SYNVEC_DESIGN_ID} },
                };

                #we now need to iterate all the alignments for this test_result.
                #we do it like this for speed.
                #when we break out of this loop we are on the next result.
                while( $r and $r->{QC_TEST_RESULT_ID} == $result->{qc_test_result_id} ) {
                    my $alignment = {
                        primer_name    => $r->{ALIGNMENT_PRIMER_NAME},
                        pass           => $r->{ALIGNMENT_PRIMER_PASS},
                        score          => $r->{ALIGNMENT_SCORE},
                        align_length   => abs($r->{ALIGNMENT_QUERY_END} - $r->{ALIGNMENT_QUERY_START}),
                        features       => $r->{ALIGNMENT_FEATURES},
                        qc_seq_read_id => $r->{ALIGNMENT_QC_SEQ_READ_ID},
                    };

                    #make an actual seq read object instead of a hash, as code in NewQC::view_result sometimes
                    #needs the actual objects (for the methods they provide).

                    $alignment->{ seq_read } = $self->result_source->schema->resultset( 'QCSeqRead' )->new( {
                        qc_seq_read_id => $r->{SEQ_READ_QC_SEQ_READ_ID},
                        description    => $r->{SEQ_READ_DESCRIPTION},
                        length         => $r->{SEQ_READ_LENGTH},
                        seq            => $r->{SEQ_READ_SEQ},
                    } );

                    push @{ $result->{alignments} }, $alignment;

                    $r = $sth->fetchrow_hashref;
                }

                push @qc_results, $result;
            }
        }
    );

    return @qc_results;
}

1;

__END__
