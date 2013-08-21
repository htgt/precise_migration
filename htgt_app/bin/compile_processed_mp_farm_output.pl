#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Log::Log4perl ':easy';
use YAML::Any 'LoadFile';
use Path::Class 'file';

my $log_level = $WARN;

GetOptions (
    debug             => sub{ $log_level = $DEBUG },
    verbose           => sub{ $log_level = $INFO },
    'input-folder=s'  => \my $input_folder,
    'report-folder=s' => \my $report_folder,
    'files=i'         => \my $files
) or die "Usage: [--debug|--verbose] --input-folder=... --report-folder=... --files=...\n";

Log::Log4perl->easy_init( { level => $log_level, layout => '%m%n' } );

my ( $merged_design_data, $merged_transcript_data, $merged_project_data );
for my $file_id(1 .. $files){
    my $filename = $input_folder . '/po' . $file_id . '.yaml';
    remove_farm_logging( $filename );

    DEBUG( "Loading data from $filename" );
    my $data = LoadFile( $filename );

    my $design_data = $data->{designs};
    my $transcript_data = $data->{transcripts};
    my $project_data = $data->{projects};

    if ( $file_id == 1 ){
        $merged_design_data = $design_data;
        $merged_transcript_data = $transcript_data;
        $merged_project_data = $project_data;
        next;
    }

    for my $design_id( keys %{$design_data} ){
        $merged_design_data->{$design_id} = $design_data->{$design_id};
    }
    for my $transcript_id( keys %{$transcript_data} ){
        $merged_transcript_data->{$transcript_id} = $transcript_data->{$transcript_id};
    }
    for my $project_id( keys %{$project_data} ){
        $merged_project_data->{$project_id} = $project_data->{$project_id};
    }
}

generate_reports( $merged_design_data, $merged_transcript_data, $merged_project_data, $report_folder );

sub generate_reports{
    my ( $design_details, $transcript_details, $project_details, $report_folder ) = @_;

    DEBUG( 'Generating reports' );
    my ( $full_fh, $main_fail_fh, $pc_fail_fh, $any_fail_fh ) = get_filehandles( $report_folder );

    for my $fh( ( $full_fh, $main_fail_fh, $pc_fail_fh, $any_fail_fh ) ){
        $fh->print( "Project ID,Project Status,Design ID,Design Type,Design Sub-type,Marker Symbol,MGI Accession ID,EnsEMBL Gene ID,EnsEMBL Transcript ID,Main Transcript,Transcript Type,Mutagenesis Prediction\n" );
    }

    for my $design_id( keys %{$design_details} ){
        for my $project_id ( @{ $design_details->{$design_id}{projects} } ){
            for my $transcript_id ( @{ $design_details->{$design_id}{transcripts} } ){
                print_row( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $full_fh );

                next unless $transcript_details->{$transcript_id}{prediction} eq 'Target region does not overlap transcript';

                next unless $project_details->{$project_id}{status} eq 'ES Cells - Targeting Confirmed' or $project_details->{$project_id}{status} =~ /^Mice -/;

                print_row( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $main_fail_fh )
                    if defined $transcript_details->{$transcript_id}{is_main_transcript}
                        and $transcript_details->{$transcript_id}{is_main_transcript} == 1;

                print_row( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $pc_fail_fh )
                    if defined $transcript_details->{$transcript_id}{type}
                        and $transcript_details->{$transcript_id}{type} eq 'protein_coding';

                print_row( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $any_fail_fh );
            }
        }
    }

    return;
}

sub remove_farm_logging{
    my ( $filename ) = @_;

    DEBUG( "Removing farm logging data from $filename" );
    my $output_file = file( $filename );
    my @lines = $output_file->slurp(chomp => 1);
    $output_file->resolve;
    my $fh = file( $filename )->openw();

    for my $line( @lines ){
        last if $line eq '';
        $fh->print( $line . "\n" );
    }

    return;
}

sub get_filehandles{
    my ( $report_folder ) = @_;

    my $full_report_file      = file($report_folder . '/mp-report.csv');
    my $main_fail_report_file = file($report_folder . '/main-transcript-fails.csv');
    my $pc_fail_report_file   = file($report_folder . '/protein-coding-fails.csv');
    my $any_fail_report_file  = file($report_folder . '/transcript-fails.csv');

    my $full_fh      = $full_report_file->openw();
    my $main_fail_fh = $main_fail_report_file->openw();
    my $pc_fail_fh   = $pc_fail_report_file->openw();
    my $any_fail_fh  = $any_fail_report_file->openw();

    return ( $full_fh, $main_fail_fh, $pc_fail_fh, $any_fail_fh );
}

sub print_row{
    my ( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $fh ) = @_;

    my @columns = ( $project_id, $project_details->{$project_id}{status}, $design_id, $design_details->{$design_id}{type}, $design_details->{$design_id}{subtype}, $design_details->{$design_id}{marker_symbol}, $design_details->{$design_id}{mgi_accession_id}, $design_details->{$design_id}{gene}, $transcript_id, $transcript_details->{$transcript_id}{is_main_transcript}, $transcript_details->{$transcript_id}{type}, $transcript_details->{$transcript_id}{prediction} );

    for my $i( 0 .. scalar @columns -1 ){
        $columns[$i] = defined $columns[$i] ? $columns[$i] : '';
    }
    $fh->print( join( ',', @columns ) . "\n" );

    return;
}
