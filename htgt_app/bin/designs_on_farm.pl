#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Log::Log4perl ':easy';
use Getopt::Long;
use Path::Class 'file';
use File::Path 'make_path';
use POSIX 'ceil';
use IPC::Run ();

my $log_level = $WARN;

GetOptions (
    debug               => sub { $log_level = $DEBUG },
    verbose             => sub { $log_level = $INFO },
    'parallel=i'        => \my $parallel,
    'design-filename=s' => \my $design_filename,
    'input-dir=s'       => \my $input_dir,
    'output-dir=s'      => \my $output_dir,
    'error-dir=s'       => \my $error_dir,
    'report-dir=s'      => \my $report_dir
) or die "Usage: [--debug|--verbose] --parallel=... --design-file=... --input-dir=... --output-dir=... --error-dir=... --report-dir=...\n";

Log::Log4perl->easy_init( { level => $log_level, layout => '%m%n' } );

$parallel ||= 10;
$input_dir ||= 'input';
$output_dir ||= 'output';
$error_dir  ||= 'error';
$report_dir ||= 'reports';

create_folders( $input_dir, $output_dir, $error_dir, $report_dir );
create_input_files( $design_filename, $input_dir, $parallel );

my $mp_job_id = submit_mp_farm_job_array( $parallel, $input_dir, $output_dir, $error_dir );
my $po_job_id = submit_po_farm_job_array( $parallel, $output_dir, $error_dir, $mp_job_id );
my $cd_job_id = submit_cd_farm_job( $parallel, $output_dir, $error_dir, $report_dir, $po_job_id  );

sub create_folders{
    my @folders_to_create = @_;

    for my $folder( @folders_to_create ){
        make_path( $folder );
    }
    DEBUG( "Created required folders" );

    return;
}

sub create_input_files{
    my ( $design_filename, $input_dir, $parallel ) = @_;

    my $design_file = file( $design_filename );
    my @design_ids = $design_file->slurp(chomp => 1);
    my $per_file = ceil( scalar @design_ids / $parallel );
    DEBUG( "Creating $parallel input files, each with $per_file design IDs" );

    my $ix = 1;
    while (my @design_ids_slice = splice @design_ids, 0, $per_file ){
        my $fh = file( $input_dir . '/' . $ix . '.in' )->openw();
        for my $design_id ( @design_ids_slice ){
            $fh->print( $design_id . "\n" );
        }
        $ix++;
    };

    return;
}

sub submit_mp_farm_job_array{
    my ( $parallel, $input_dir, $output_dir, $error_dir ) = @_;
    my $mp_output = run_cmd(
        'bsub',
        '-q', 'normal',
        '-P', 'team87',
        '-J', 'mutpred[1-' . $parallel . ']',
        '-i', $input_dir . '/%I.in',
        '-o', $output_dir . '/mp%I.out',
        '-e', $error_dir . '/mp%I.err',
        '-M', '1000000',
        '-R', '"select[mem>1000] rusage[mem=1000]"',
        'mutagenesis-prediction.pl',
        '--dump'
    );
    DEBUG ( "Mutagenesis prediction farm submission: $mp_output" );
    my ($mp_job_id) = $mp_output =~ /^Job <(\d+)>/;

    return $mp_job_id;
}

sub submit_po_farm_job_array{
    my ( $parallel, $output_dir, $error_dir, $mp_job_id ) = @_;

    my $po_output = run_cmd(
        'bsub',
        '-w', 'done(' . $mp_job_id . ')',
        '-q', 'normal',
        '-P', 'team87',
        '-J', 'parse_mp_out[1-' . $parallel . ']',
        '-i', $output_dir . '/mp%I.out',
        '-o', $output_dir . '/po%I.yaml',
        '-e', $error_dir . '/po%I.err',
        '-M', '1000000',
        '-R', '"select[mem>1000] rusage[mem=1000]"',
        'process_mp_farm_output.pl'
    );
    DEBUG ( "Parse output farm submission: $po_output" );
    my ($po_job_id) = $po_output =~ /^Job <(\d+)>/;

    return $po_job_id;
}

sub submit_cd_farm_job{
    my ( $parallel, $output_dir, $error_dir, $report_dir, $po_job_id ) = @_;

    my $cd_output = run_cmd(
        'bsub',
        '-w', 'done(' . $po_job_id . ')',
        '-q', 'normal',
        '-P', 'team87',
        '-o', $output_dir . '/compile_data.out',
        '-e', $error_dir . '/compile_data.err',
        '-M', '1000000',
        '-R', '"select[mem>1000] rusage[mem=1000]"',
        'compile_processed_mp_farm_output.pl',
        "--input-folder=$output_dir",
        "--report-folder=$report_dir",
        "--files=$parallel"
    );
}

sub run_cmd {
    my @cmd = @_;

    my $output;
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        die "Command failed: $err";
    }

    chomp $output;
    return  $output;
}
