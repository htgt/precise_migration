package HTGT::QC::Action::Runner::Run;

use Moose;
use YAML::Any;
use Fcntl; # O_ constants
use IPC::System::Simple qw( systemx );
use sigtrap die => 'normal-signals';
use namespace::autoclean;

extends qw( HTGT::QC::Action );

override command_names => sub {
    'runner-run'
};

override abstract => sub {
    'run a QC job (usually invoked by the qc runner daemon)'
};

has qc_run_id => (
    is       => 'ro',
    isa      => 'Str',
    traits   => [ 'Getopt' ],
    cmd_flag => 'run-id',
    required => 1
);

has lock_file => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    traits     => [ 'NoGetopt' ],
    lazy_build => 1        
);

sub _build_lock_file {
    my $self = shift;
    $self->config->basedir->subdir( $self->qc_run_id )->file( 'lock' );
}

has have_lock => (
    is         => 'rw',
    isa        => 'Bool',
    traits     => [ 'NoGetopt' ],
    default    => 0
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    $self->get_exclusive_lock();
    
    my $params_file = $self->config->basedir->subdir( $self->qc_run_id )->file( 'params.yaml' );

    my $params = YAML::Any::LoadFile( $params_file );

    for my $required_param ( qw( profile template_plate ) ) {
        if ( ! defined $params->{$required_param} ) {            
            HTGT::QC::Exception->throw( "$required_param not specifed in $params_file" );
        }        
    }
    
    my $stage = $self->config->profile( $params->{profile} )->vector_stage;
   
    my @args = (
        'RUN_ID='         . $self->qc_run_id,
        'PROFILE='        . $params->{profile},
        'TEMPLATE_PLATE=' . $params->{template_plate},
        'USER='           . $params->{user},
        'PLATE_MAP='      . join( q{ }, map { $_ . '=' . $params->{plate_map}{$_} }
                                      keys %{ $params->{plate_map} } )
    );
    if ( $self->conffile ) {
        push @args, 'CONFIG=' . $self->conffile;
    }
    
    my $command;
    
    if ( $stage eq 'allele' ) {
        $command = 'run-escell-qc';
        ( my $epd_plate_name = $params->{sequencing_projects}[0] ) =~ s/_.+$//;
        push @args, 'EPD_PLATE_NAME=' . $epd_plate_name;
    }
    else {
        $command = 'run-vector-qc';
        push @args, 'SEQUENCING_PROJECTS=' . join( q{ }, @{ $params->{sequencing_projects} } );
        push @args, 'VECTOR_STAGE=' . $stage;
    }

    push @args, 'persist';

    $self->log->debug( join q{ }, 'Running', $command, @args );
    systemx( $command, @args );
}

sub get_exclusive_lock {
    my $self = shift;

    my $lock = $self->lock_file->open( O_CREAT|O_EXCL|O_WRONLY, oct(644) )
        or HTGT::QC::Exception->throw( "Failed to get exclusive lock on " . $self->lock_file . ": $!" );

    $lock->print( "$$\n" );
    $lock->close;

    $self->have_lock(1);    
}

sub DEMOLISH {
    my $self = shift;
    
    $self->lock_file->remove if $self->have_lock;
}
    
__PACKAGE__->meta->make_immutable;

1;

__END__
