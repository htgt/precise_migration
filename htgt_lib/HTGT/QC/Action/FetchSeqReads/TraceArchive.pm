package HTGT::QC::Action::FetchSeqReads::TraceArchive;

use Moose;
use MooseX::ClassAttribute;
use Bio::SeqIO;
use Log::Log4perl ':easy';
use Path::Class;
use HTGT::QC::Exception;
use HTGT::QC::Util::Which;
use namespace::autoclean;
use HTGT::QC::Util::CigarParser;

extends qw( HTGT::QC::Action::FetchSeqReads );

override command_names => sub {
    'fetch-seq-reads-archive'
};

override abstract => sub {
    'fetch reads for the specified sequencing projects from the trace archive'
};

class_has fetch_seq_reads_cmd => (
    is         => 'ro',
    isa        => 'Str',
    traits     => [ 'NoGetopt' ],
    lazy_build => 1
);

#allow ability to specify certain filters
has primer_filters => (
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    traits   => [ 'Getopt', 'Array' ],
    cmd_flag => 'primer-filter',
    default => sub { [] } 
); 

sub _build_fetch_seq_reads_cmd {
    which( 'fetch-seq-reads.sh' );
}

sub execute {
    my ( $self, $opts, $args ) = @_;
    
    for my $project_name ( @{$args} ) {        
        $self->fetch_reads_for_project( $project_name );
    }
}

sub fetch_reads_for_project {
    my ( $self, $project_name ) = @_;

    $self->log->debug( "Fetching sequence reads for $project_name" );

    open( my $seq_reads_fh, '-|', $self->fetch_seq_reads_cmd, $project_name )
        or HTGT::QC::Exception->throw( 'failed to run ' . $self->fetch_seq_reads_cmd );

    my $seq_in = Bio::SeqIO->new( -fh => $seq_reads_fh, -format => 'fasta' );

    my $num_reads = 0;

    my $primers = join "|", @{ $self->primer_filters };

    my $parser = HTGT::QC::Util::CigarParser->new( primers => [ '.*?' ] );
    
    while ( my $bio_seq = $seq_in->next_seq ) {
        next unless $bio_seq->length;
        $num_reads++;

        #if the user provided primers to filter by, skip any that dont match
        if ( $primers ) {
            #we should use another cigarparser instance for this, really.
            my ( $primer ) = $bio_seq->id =~ /^.+\.(?:[a-z]\d)k\d*[a-z]?($primers)[a-z]?$/;

            #if we didnt match whatever is in primers then skip this one.
            unless ( $primer ) {
                $self->log->debug("Skipping " . $bio_seq->id . ": primer not in $primers.");
                next;
            } 
        }

        # Exonerate won't eat sequences containing '-'
        ( my $seq = $bio_seq->seq ) =~ s/-/N/g;
        $bio_seq->seq( $seq );

        my $primer = $parser->parse_query_id( $bio_seq->id )->{ primer };

        if ( $self->profile->has_split_primers and $self->profile->split_primer_exists( $primer ) ) {
            my $original_id = $bio_seq->id; #store this so we can substitute each time

            #loop through the array ref of what to split this primer into.
            #split_primers is formatted like: { L1 => ['L1I', 'L1E'] }
            #so we want to duplicate the sequence for each renamed primer.
            for my $split_primer ( @{ $self->profile->get_split_primers( $primer ) } ) {
                ( my $new_id = $original_id ) =~  s/$primer([a-z]?)$/$split_primer$1/;
                $bio_seq->id( $new_id );
                $self->seq_out->write_seq( $bio_seq );
            }

            #we've written everything out so move on to the next sequence.
            next;
        }

        $self->seq_out->write_seq( $bio_seq );
    }

    if ( $num_reads == 0 ) {
        HTGT::QC::Exception->throw( "Failed to retrive sequence reads for $project_name" );
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
