package HTGT::QC::Action::Runner::Daemon;

use Moose;
use MooseX::Types::Path::Class;
use Proc::Daemon;
use POSIX qw( :sys_wait_h );
use IO::Pipe;
use namespace::autoclean;

extends 'HTGT::QC::Action';

override command_names => sub {
    'runner'
};

override abstract => sub {
    'control the daemon that runs QC jobs submitted by the web application'
};

has [ qw( start stop status ) ] => (
    is     => 'ro',
    isa    => 'Bool',
    traits => [ 'Getopt' ]
);

has basedir => (
    is         => 'ro',
    isa        => 'Path::Class::Dir',
    traits     => [ 'Getopt' ],
    coerce     => 1,    
    lazy_build => 1        
);

has max_parallel => (
    is          => 'ro',
    isa        => 'Int',
    traits     => [ 'Getopt' ],
    cmd_flag   => 'max-parallel',
    lazy_build => 1
);

has poll_interval => (
    is         => 'ro',
    isa        => 'Int',
    traits     => [ 'Getopt' ],
    cmd_flag   => 'poll-interval',
    lazy_build => 1
);

has log_file => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    traits    => [ 'Getopt' ],
    cmd_flag  => 'log-file',
    coerce    => 1,
    predicate => 'has_log_file'
);

has pid_file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    traits   => [ 'Getopt' ],
    cmd_flag => 'pid-file',
    coerce   => 1,
    required => 1
);

has jobs => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => [ 'NoGetopt', 'Hash' ],
    handles => {
        add_job  => 'set',
        rm_job   => 'delete',
        get_job  => 'get',
        num_jobs => 'count'
    }
);

sub _build_basedir {
    shift->config->runner_basedir;
}

sub _build_max_parallel {
    shift->config->runner_max_parallel || 10;
}

sub _build_poll_interval {
    shift->config->runner_poll_interval || 30;
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my %daemon_args = (
        pid_file => $self->pid_file
    );

    if ( $self->has_log_file ) {
        $daemon_args{child_STDOUT} = '>>' . $self->log_file;
        $daemon_args{child_STDERR} = '>>' . $self->log_file;
    }
    
    my $daemon = Proc::Daemon->new( %daemon_args );

    if ( $self->start ) {
        $self->do_start( $daemon );        
    }    
    elsif ( $self->stop ) {
        $self->do_stop( $daemon );
        
    }
    elsif ( $self->status ) {
        $self->do_status( $daemon );
    }    
    else {
        die "One of --start, --stop, or --status must be specified\n";
    }
}

sub do_start {
    my ( $self, $daemon ) = @_;

    my $pid = $daemon->Init;
    if ( $pid == 0 ) {
        $self->daemon_loop();
    }
    else {
        print "Started $0, process $pid\n";
    }        

    exit 0;
}

sub do_stop {
    my ( $self, $daemon ) = @_;

    my $pid = $daemon->Status;
    if ( ! $pid ) {
        die "$0 is not running\n";
    }
    
    for ( 0..2 ) {
        last unless $daemon->Status( $pid );                
        warn "Sending TERM signal\n";
        $daemon->Kill_Daemon( $pid, 'TERM' );
        warn "Sleeping...\n";
        sleep 2**$_;
    }

    if ( $daemon->Status( $pid ) ) {
        warn "Sending KILL signal\n";
        $daemon->Kill_Daemon( $pid, 'KILL' );
    }

    my $status = $daemon->Status($pid) ? 1 : 0;
    
    exit $status;    
}

sub do_status {
    my ( $self, $daemon ) = @_;

    if ( my $pid = $daemon->Status ) {
        print "$0 is running (process $pid)\n";
    }
    else {
        print "$0 is not running\n";
    }

    exit 0;
}

sub daemon_loop {
    my $self = shift;

    if ( $self->has_log_file ) {
        $self->init_log4perl( $self->log_file );
    }    
    
    $self->log->info( sprintf( 'Monitoring %s at interval %d, max parallel %d',
                               $self->basedir->subdir( 'new' ), $self->poll_interval, $self->max_parallel ) );
    
    $SIG{CHLD} = $self->REAPER( WNOHANG );
    
    my $next_poll = time() + $self->poll_interval;
    
    while ( 1 )  {
        my @todo =  map { $_->[1] } sort { $a->[0] <=> $b->[0] } map { [ $_->stat->mtime, $_ ] } $self->basedir->subdir( 'new' )->children;
        $self->process_todo_list( \@todo );
        if ( ( my $sleep = $next_poll - time() ) > 0 ) {
            sleep $sleep;
        }
        $next_poll = time() + $self->poll_interval;
    }
}

sub REAPER {
    my ( $self, $wait_opts ) = @_;

    $wait_opts = 0 unless defined $wait_opts;
    
    return sub {
        my $child;
        while ( ( $child = waitpid(-1, $wait_opts) ) > 0 ) {
            $self->done_child( $child, $?>>8 );
        }
        $SIG{CHLD} = $self->REAPER( $wait_opts );
    }
}

sub process_todo_list {
    my ( $self, $todo ) = @_;

    while ( @{$todo} ) {
        if ( $self->num_jobs < $self->max_parallel ) {
            $self->resume_job( shift @{$todo} );
        }
        else {
            # Wait for the SIGCHLD handler to reap a child (or more)
            sleep;
        }
    }
}

sub done_child {
    my ( $self, $pid, $rc ) = @_;

    my $run_id = $self->rm_job( $pid );
    unless ( $run_id ) {
        $self->log->error( "Reaped process $pid not in job list" );
        return;
    }    
    
    if ( $rc == 0 ) {
        $self->log->info( "Job $run_id completed OK" );
        $self->basedir->subdir( 'complete' )->file( $run_id )->touch;
    }
    else {
        $self->log->error( "Job $run_id exited $rc" );
        $self->basedir->subdir( 'fail' )->file( $run_id )->touch;
    }
}        
    
sub resume_job {
    my ( $self, $this_job ) = @_;
    
    if ( unlink( $this_job ) != 1 ) {
        # Job has been deleted from the queue from under us: do nothing
        return;
    }  

    my $run_id = $this_job->basename;
    $self->log->info( "Resuming job $run_id" );
    Log::Log4perl::NDC->push( $run_id );

    # The pipe is used for synchronising the parent and child, to
    # ensure that the parent runs first. Otherwise, if the child runs
    # and exits immediately, the SIGCHLD handler might fire before
    # we've added $pid to the job list.

    my $pipe = IO::Pipe->new; 
    
    my $pid = fork();

    if ( not defined $pid ) {
        $self->log->error( "Fork failed: $!" );
        return;
    }
        
    if ( $pid == 0 ) { # child process
        $pipe->reader;
        $SIG{TERM} = $SIG{CHLD} = 'DEFAULT';
        # Wait for the go-ahead from the parent process
        $pipe->getc; $pipe->close;
        my @cmd = ( 'qc', 'runner-run', '--run-id', $run_id );
        my $log_file = $self->config->basedir->subdir( $run_id )->file( 'log' );

        #
        #this code isnt even used any more and i got sick of the perlcritic warning
        #
        
        ## no critic
        open( STDOUT, '>'.$log_file )
            or die "Can't redirect STDOUT: $!"; 
        ## use critic
        open( STDERR, '>&STDOUT' )
            or die "Can't dup STDERR: $!";
        exec( @cmd )
            or die "exec @cmd failed: $!";                
    }

    $pipe->writer;
    $self->add_job( $pid, $run_id );

    # Prod the child process, which is currently sitting in a blocked read
    $pipe->print( 0 ); $pipe->close;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
