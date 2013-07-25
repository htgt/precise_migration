package HTGT::Controller::API::QC;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

use Try::Tiny;
use HTGT::QC::Config;
use HTGT::QC::Run;
use HTGT::QC::Util::SubmitQCFarmJob::Vector;

sub submit_lims2_qc :Path('/api/submit_lims2_qc') {

    my ( $self, $c ) = @_;

    my $qc_data = $c->req->data;

    # user must authenticate and be on campus
    return unless $self->_authenticate_user( $c, $qc_data->{ username }, $qc_data->{ password } );

    # Attempt to validate input and launch QC job
    try {
        $self->_validate_params($qc_data);

        my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );

        #this is pointless as plate_map defaults to {} in run...
        $qc_data->{ plate_map } ||= {};

        my $run = HTGT::QC::Run->init(
            config              => $config,
            profile             => $qc_data->{ profile },
            template_plate      => $qc_data->{ template_plate },
            sequencing_projects => $qc_data->{ sequencing_projects },
            run_type            => 'vector',
            persist             => 1,
            plate_map           => $qc_data->{ plate_map },
            created_by          => $qc_data->{ created_by },
            species             => $qc_data->{ species },
        );

        #this only supports vector for the time being.

        my $submit_qc_farm_job = HTGT::QC::Util::SubmitQCFarmJob::Vector->new( { qc_run => $run } );
        $submit_qc_farm_job->run_qc_on_farm();
        my $run_id = $run->id or die "No QC run ID generated"; #this is pretty pointless; we always get one.
        
        $self->status_ok(
            $c,
            entity => { qc_run_id => $run_id, }
        );        
    }
    catch {
        print "$_\n";
        $self->status_bad_request(
            $c,
            message => UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_,
        );
    };
}

sub kill_lims2_qc :Path('/api/kill_lims2_qc') {
    my ( $self, $c ) = @_;
    
    my $qc_data = $c->req->data;

    #make sure the user has a valid login and is on campus
    return unless $self->_authenticate_user( $c, $qc_data->{ username }, $qc_data->{ password } );

    my $config = HTGT::QC::Config->new( { is_lims2 => 1 } );
    
    #vms have a separate qc.conf but they SHOULD be in sync

    try {
        die "You must provide a QC run id.\n" unless $qc_data->{ qc_run_id };

        my $config = HTGT::QC::Config->new( { is_lims2 => 1 } ); 
        my $kill_jobs = HTGT::QC::Util::KillQCFarmJobs->new(
            {
                qc_run_id => $qc_data->{ qc_run_id },
                config    => $config,
            } );

        my $jobs_killed = $kill_jobs->kill_unfinished_farm_jobs();
        $self->status_ok(
            $c,
            entity => { job_ids => $jobs_killed }, 
        );
    }
    catch {
        print "$_\n";
        $self->status_bad_request(
            $c,
            message => UNIVERSAL::isa( $_, 'Throwable::Error' ) ? $_->message : $_,
        );
    };
}

sub _authenticate_user {
    my ( $self, $c, $user, $pass ) = @_;

    # user must authenticate and be on campus
    my $authenticated = $c->authenticate( 
        { username => $user, password => $pass, },
        'qc'
    );
    
    unless ( $authenticated ) {
        $self->status_bad_request(
            $c,
            message => "Invalid username and password provided for QC job submission",
        );  
        return 0;
    }
    
    my $user_ip = $c->req->address;
    unless ( $user_ip =~ /^172\.17\./ ) {
        my $message = "Unauthorized IP address: $user_ip. "
                     ."QC submissions can only by made from internal Sanger IP addresses.";
        
        # This should be a status_forbidden but it throws error
        # Can't locate object method "status_forbidden" via package "HTGT::Controller::API::QC" 
        $self->status_bad_request( $c, message => $message, );
        return 0;
    }

    return 1;
}

sub _validate_params {
    my ( $self, $params ) = @_;

    die "You must provide a 'profile'\n"
        unless $params->{ profile } =~ /\w+/;

    die "You must provide a 'template_plate'\n"
        unless $params->{ template_plate } =~ /\w+/;

    die "You must provide one or more 'sequencing_projects'\n"
        unless $params->{ sequencing_projects } and ref $params->{ sequencing_projects } eq 'ARRAY';

    #if we are provided a plate_map (it's optional) make sure its a hash
    die "The plate_map must be a HashRef\n"
        if $params->{ plate_map } and ref $params->{ plate_map } ne 'HASH';

    return $params;
}

1;
