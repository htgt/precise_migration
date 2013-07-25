package HTGT::QC::Action::Misc::KillAndNotify;

use Moose;
use namespace::autoclean;
use IPC::Run ();

extends qw( HTGT::QC::Action );

override command_names => sub {
    'kill-and-notify'
};

override abstract => sub {
    'kills all bsub processes for a given run'
};

has qc_run_id => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    required => 1,
    cmd_flag => 'run-id',
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    #perhaps we should make sure we have config??

    #the run is being killed, so firstly mark it as failed.
    my $work_dir = $self->config->basedir->subdir( $self->qc_run_id );
    
    my $out_fh = $work_dir->file( 'failed.out' )->openw();
    $out_fh->print( "The run has failed because it was marked to be killed.\n" );

    #get all the run ids
    my @job_ids = $work_dir->file( "lsf.job_id" )->slurp( chomp => 1 );

    $out_fh->print( "\nKilling jobs [", join(",", @job_ids), "]\n" );

    if( $self->kill_everything( \@job_ids, $out_fh ) ) {
        #we have succeeded, so create ended.out to identify a run as no longer running
        $out_fh = $work_dir->file( 'ended.out' )->openw();
        $out_fh->print( "The run was killed successfully.\n" );
    }
    else {
        #this is going into the failed.out file
        $out_fh->print( "There was an error killing all the jobs.\n" );
    }
}

sub kill_everything {
    my ($self, $job_ids, $out_fh) = @_;

    #kill our bsub tests
    my $kill_output = $self->run_cmd(
        'bkill',
        @{ $job_ids },
    );

    #print $kill_output, "\n";

    #hash to hold all jobs that are still alive
    my %waiting = map { $_ => 1 } @{ $job_ids };

    $out_fh->print( "Waiting for jobs to finish.\n" );

    for ( 0..10 ) {
        #sleep first as it takes a bit of time for them to be killed
        sleep 60; 

        $self->check_if_done(\%waiting, $out_fh);
        
        #see if there's any jobs left in the hash
        if ( scalar keys %waiting ) {
            $out_fh->print( "Still some jobs left alive:\n", join("\n", keys %waiting), "\n" );
        }
        else { 
            $out_fh->print( "All jobs have been killed.\n" );
            return 1;
        }
    }

    #the loop finished so we did not succeed
    return 0;
}

sub check_if_done {
    my ( $self, $waiting, $out_fh ) = @_;

    my $test_output = $self->run_cmd(
        'bjobs',
        '-G', 'team87-grp',
        keys %$waiting
    );

    print $test_output, "\n";

    my @lines = split( /\n/, $test_output );
    shift @lines; #the top row is just field names, so disgard it

    #example of what we're dealing with here:
    #
    #JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
    #7219712 ds5     RUN   long       farm2-head1 bc-24-1-10  NA12843.sh Dec  4 12:17

    for ( @lines ) {
        #basically replicate awk to extract the job id and status
        my @values = split( /\s+/, $_ );
        my ( $job_id, $status ) = ( $values[0], $values[2] );

        #check the values are what we expect
        $out_fh->print( "Invalid job id: $job_id\nLine: $_\n" ) if $job_id !~ /^([0-9]+)$/;
        $out_fh->print( "Invalid status: $status\nLine: $_\n" ) if $status !~ /^([A-Z]+)$/;
        
        next unless $status; #make sure we got a status
        next unless defined $waiting->{ $job_id }; #has it already been deleted?

        #if the job has finished remove it from the hash
        if( $status eq "EXIT" or $status eq "DONE" ) {
            delete $waiting->{ $job_id };
        }
    }
}

#this should be added to Util::RunCmd
sub run_cmd {
    my ( $self, @cmd ) = @_;

    my $output;
    ## no critic (RequireCheckingReturnValueOfEval)
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        #dont die otherwise the notify will never happen
        print "Command returned non-zero:\n$err";
    }
    ## use critic

    chomp $output;
    return  $output;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
