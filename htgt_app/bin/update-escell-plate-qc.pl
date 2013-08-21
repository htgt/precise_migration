#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::QC::UpdateESCellQC qw ( update_ES_plate );
use Getopt::Long;
use Log::Log4perl ':easy';
use HTGT::DBFactory;

my $log_level = $WARN;

GetOptions(
    'debug'   => sub { $log_level = $DEBUG },
    'verbose' => sub { $log_level = $INFO },
    'orig-plate-name=s' => \my $orig_plate_name,
    'plate-name=s' => \my $plate_name,
    'qc-run-id=s' => \my $qc_run_id,
    'user-id=s' => \my $user_id
) or die "Usage: $0 [--debug|--verbose] --orig-plate-name=... --plate-name=... --qc-run-id=... user-id=... \n";

Log::Log4perl->easy_init(
    {
        layout => '%m%n',
        level  => $log_level
    }
);

my $schema = HTGT::DBFactory->connect( 'eucomm_vector' );

$schema->txn_do(
    sub{
        my $qc_run = $schema->resultset( 'QCRun' )->find( { qc_run_id => $qc_run_id } )
            or die "Failed to retrieve QCRun $qc_run_id";
        my $updated_plate = update_ES_plate( $schema, $orig_plate_name, $plate_name, $qc_run, $user_id );
        die "Well data not updated on plate $plate_name" unless defined $updated_plate;

        my $plate = $schema->resultset( 'Plate' )->find( { name => $plate_name } );
        for my $well ( $plate->wells ){
            DEBUG( "Updating 5'arm, 3'arm and loxP pass levels for $well" );
            for ( qw( three_arm_pass_level five_arm_pass_level loxP_pass_level ) ){
                $well->$_( 'recompute' );
            }
        }
    }
);

