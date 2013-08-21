#!/usr/bin/env perl
#
# This script takes the path to a list of design ids as its first and
# only argument, and runs in one of two modes:
#
# 1. If LSB_JOBINDEX is set, it retrieves the design id at that index from
#    its input file and invokes create_design.pl for that design
#
# 2. If LSB_JOBINDEX is not set, it issues a bsub command to create a
#    job array to run create_design.pl for each design in the input file.

use strict;
use warnings FATAL => 'all';
use Perl6::Slurp 'slurp';
use Path::Class;
use Time::HiRes 'gettimeofday';
use Const::Fast;

const my $DESIGN_HOME   => dir( '/lustre/scratch101/sanger/team87/designs' );
const my $CREATE_DESIGN => 'create_design.pl';

const my $PROJECT       => 'team87';
const my $QUEUE         => 'normal';
const my $MAX_PARALLEL  => 10;

{
    
    die "Usage: $0 ARG_FILE\n"
        unless @ARGV == 1;

    my $arg_file = shift @ARGV;

    my @args = slurp $arg_file, { chomp => 1 };

    if ( $ENV{LSB_JOBINDEX} ) {
        run_job_at_index( $ENV{LSB_JOBINDEX}, \@args );
                      
    }
    else {
        run_bsub( $arg_file, \@args );
    }
}

sub run_bsub {
    my ( $arg_file, $args ) = @_;

    my $job_name = sprintf( 'design[1-%d]%%%d', scalar @$args, $MAX_PARALLEL );
    
    my @bsub = ( 'bsub', '-J', $job_name, '-P', $PROJECT, '-q', $QUEUE,
                 '-o', $DESIGN_HOME->file( 'design.%J.%I.out' ),
                 '-e', $DESIGN_HOME->file( 'design.%J.%I.err' ),
                 $0, $arg_file );

    exec @bsub
        or die "failed to exec @bsub: $!";
}

sub run_job_at_index {
    my ( $job_index, $args ) = @_;

    die "LSB_JOBINDEX out of range\n"
        if $job_index > @$args;

    my $design_id = $args->[$job_index - 1];
    
    my $dirname = sprintf( 'd_%d.%d.%d.%d', $design_id, $$, Time::HiRes::gettimeofday() );
    my $design_home = $DESIGN_HOME->subdir( $dirname );
    
    my @cmd = ( $CREATE_DESIGN, '-design_home', $design_home, '-design_id', $design_id );

    exec @cmd
        or die "failed to exec @cmd: $!";
}
