package HTGT::Utils::SubmitQC;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/trunk/lib/HTGT/Utils/SubmitQC.pm $
# $LastChangedRevision: 5653 $
# $LastChangedDate: 2011-08-15 11:53:32 +0100 (Mon, 15 Aug 2011) $
# $LastChangedBy: sp12 $

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'submit_qc_job', 'list_qc_jobs' ] };
use Log::Log4perl ':easy';
use Carp 'confess';
use Config::Std;
use DateTime;
use Errno;
use File::Class;
use File::stat;
use File::Spec;
use IO::Dir;
use IO::File;
use IPC::Run;
use Readonly;

use Exception::Class (
    'HTGT::Utils::SubmitQC::Exception',
    'HTGT::Utils::SubmitQC::Exception::System' => { isa => 'HTGT::Utils::SubmitQC::Exception' },
    'HTGT::Utils::SubmitQC::Exception::Config' => { isa => 'HTGT::Utils::SubmitQC::Exception' },
);

Readonly my %ALLELE_QC_OPT => (
    B => '-tronly',
    Z => '-tponly',
    R => '-fponly',
);

Readonly my $DEFAULT_CONFIG_PATH => '/software/team87/brave_new_world/conf/submit_qc.conf';

# EPD0527_5.EPD00527_5_A.2010-04-28T09:19:05.out
Readonly my $OUT_FILE_RX => qr/
    ^
    ([^.]+)             # HTGT plate name
    \.
    ([^.]+)             # Sequencing project
    \.
    (\d{4}-\d{2}-\d{2}) # Submission date
    T
    (\d{2}:\d{2}:\d{2}) # Submission time
    \.out
    $
/x;

=pod

=head1 NAME

HTGT::Utils::SubmitQC

=head1 SYNOPSIS

    use HTGT::Utils::SubmitQC 'submit_qc_job';

    eval {
        submit_qc_job( 'EPD00511_1_A', 'EPD0511_1', 'wy1' )
    };
    if ( $@ ) {
        # Handle error
    }

    my $jobs = HTGT::Utils::SubmitQC::list_qc_jobs();
    print $_->{plate} . "\n" for @{$jobs};

=head1 DESCRIPTION

Utility module to submit a QC run.

=head1 METHODS

=cut    

=head2 set_config

Override the default configuration path.

=cut

=head2 get_config

Read the configuration file. The configuration is cached, and only re-read from disk
if the file modification time changes.

=cut

{
    my $config;
    my $config_stamp;
    my $config_path;

    sub set_config {
        $config_path = shift;
        undef $config_stamp;
    }    
    
    sub get_config {

        $config_path = $DEFAULT_CONFIG_PATH
            unless defined $config_path;
        
        my $sb = stat( $config_path )
            or HTGT::Utils::SubmitQC::Exception::System->throw( "stat $config_path: $!" );

        unless ( $config_stamp and $config_stamp >= $sb->mtime ) {
            DEBUG( "Reading config from $config_path" );
            undef $config;
            eval { read_config $config_path => $config };
            if ( $@ ) {
                HTGT::Utils::SubmitQC::Exception::Config->throw(
                    "Error parsing configuration file $config_path: $@"
                );
            }
            $config_stamp = $sb->mtime;
        }

        return $config;
    }
}

=head2 list_qc_jobs()

Returns a reference to a list of recently completed QC jobs. Each
element of the list is a hash of I<plate>, I<tsproj>, I<subdate> and
I<status>.

=cut

sub list_qc_jobs {

    my $job_path = get_config()->{''}{output_dir};
    
    my $dir = IO::Dir->new( $job_path )
        or confess "opendir $job_path: $!";
    
    my @jobs;
    while ( defined( my $filename = $dir->read ) ) {
        if ( my ( $htgt_plate, $tsproj, $subdate, $subtime ) = $filename =~ $OUT_FILE_RX ) {
            my $status = get_status( File::Spec->catfile( $job_path, $filename ) )
                or next;
            push @jobs, {
                plate   => $htgt_plate,
                tsproj  => $tsproj,
                subdate => $subdate . ' ' . $subtime,
                status  => $status,
            }
        }
    }

    return [ sort { $b->{subdate} cmp $a->{subdate} } @jobs ];
}

=head2 get_status( I<$filename> )

Examine the bsub output to find whether or not this job completed successfully.

=cut

sub get_status {
    my $filename = shift;

    my $fh = IO::File->new( $filename, O_RDONLY )
        or $!{ENOENT} and return
            or confess "open $filename: $!";

    while ( $_ = $fh->getline ) {
        next unless /^Sender: LSF System/;
        while ( $_ = $fh->getline ) {
            if ( /^Successfully completed\./ ) {
                return 'completed';
            }
            if ( /^Exited with exit code [1-9]\d*\./ ) {
                return 'failed';
            }
        }
    }

    return 'unknown';
}

=head2 submit_qc_job( I<$sequencing_project>, I<$htgt_plate>, I<$submitted_by>, I<$options> )

Submit a QC job to the LSF batch queue.

=cut

sub submit_qc_job {
    my ( $sequencing_project, $htgt_plate, $submitted_by, $options ) = @_;

    $submitted_by ||= 'team87';
    $options ||= {};

    INFO( "submit_qc_job: $sequencing_project, $htgt_plate, $submitted_by" );
    
    my $config = get_config();

    my @bsub = bsub_cmd( $config, $sequencing_project, $htgt_plate, $submitted_by, $options );

    check_bsub_group( $config->{bsub}{group}, $config->{bsub}{max_parallel} )
        if $config->{bsub}{group};
    
    run_cmd( @bsub );
}

=head2 bsub_cmd

Create the bsub command for this QC run.

=cut

sub bsub_cmd {
    my ( $config, $sequencing_project, $htgt_plate, $submitted_by, $options ) = @_;

    my $outfile = outfile( $config, "$htgt_plate.$sequencing_project", 'out' );
    my $errfile = outfile( $config, "$htgt_plate.$sequencing_project", 'err' );

    my @bsub_cmd = ( 'bsub', '-cwd', $config->{''}{output_dir},
                     '-o', $outfile, '-e', $errfile, '-u', $submitted_by, '-J', $sequencing_project );

    if ( $config->{bsub}->{queue} ) {
        push @bsub_cmd, '-q', $config->{bsub}->{queue};
    }
    if ( $config->{bsub}->{project} ) {
        push @bsub_cmd, '-P', $config->{bsub}->{project};
    }
    if ( my $memory = $config->{bsub}->{memory} ) {
        push @bsub_cmd, '-R', "select[mem>$memory] rusage[mem=$memory]", '-M', $memory * 1000;
    }
    if ( $config->{bsub}->{group} ) {
        push @bsub_cmd, '-g', $config->{bsub}->{group};
    }

    push @bsub_cmd,
      check_vector_mapping_cmd( $config, $sequencing_project, $htgt_plate, $options );
    
    return @bsub_cmd;
}

=head2 check_bsub_group

Ensure that the specfied bsub group exists and is configured with the correct
job limit.

=cut    

sub check_bsub_group {
    my ( $group, $max_parallel ) = @_;

    my $bjgroup = run_cmd( 'bjgroup', '-s', $group );

    if ( $bjgroup =~ /No job group found/ ) {
        run_cmd( 'bgadd', $group );
    }

    if ($max_parallel) {
        run_cmd( 'bgmod', '-L', $max_parallel, $group );
    }
}

=head2 run_cmd( I<@cmd> )

Run the command I<@cmd> and return its output. Throw an exception if the command fails.

=cut

sub run_cmd {
    my @cmd = @_;

    INFO( join( q{ }, 'run_cmd:', map { defined $_ ? $_ : '<undef>' } @cmd ) );

    return "Command not run in test mode"
        unless $ENV{HTGT_ENV} eq 'Live' or ( $ENV{HTGT_SUBMITQC_FORCE_RUN} || '' ) eq 'yes';

    my $output;
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        HTGT::Utils::SubmitQC::Exception::System->throw( "$cmd[0] failed: $err" );
    }        

    chomp $output;

    return $output;
}

=head2 outfile

Create an output filename made up of the plate name and current
timestamp. The output file will be written to the I<output_dir> specified
in the configuration file.

=cut

sub outfile {
    my ( $config, $name, $suffix ) = @_;

    my $now = DateTime->now;
    my $output_file = sprintf( '%s.%sT%s.%s', $name, $now->ymd, $now->hms, $suffix );

    File::Class->new( $config->{''}{output_dir} ) + $output_file;
}

=head2 check_vector_mapping_cmd

Return the command to run QC on the specified sequencing project and plate.

=cut    

sub check_vector_mapping_cmd {
    my ( $config, $tsproj, $htgt_plate, $options ) = @_;

    my ($prefix) = $htgt_plate =~ m/^([A-Z]+)/;

    my $type = $config->{prefix_map}->{$prefix}
        or HTGT::Utils::SubmitQC::Exception::Config->throw( "prefix_map for $prefix not configured" );

    HTGT::Utils::SubmitQC::Exception::Config->throw( "options for $type QC not correctly configured" )
            unless $config->{$type} and $config->{$type}{opt} and ref $config->{$type}{opt} eq 'ARRAY';
    
    my @cmd = ( $config->{''}{check_vector_mapping}, @{ $config->{$type}{opt} } );
    push @cmd, '-plate', $htgt_plate, '-tsproj', $tsproj;

    push @cmd, '-force-rerun' if $options->{force_rerun};
    push @cmd, '-applycre'    if $options->{apply_cre};

    if ( $type eq 'allele' ) {
        my ($suffix) = $tsproj =~ /(.)$/;
        push @cmd, $ALLELE_QC_OPT{$suffix}
            if defined $ALLELE_QC_OPT{$suffix};
    }

    return @cmd;
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__
