#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::MutagenesisPrediction::Design;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Getopt::Long;
use Data::Dump 'dd';

my $log_level = $WARN;

GetOptions (
    debug   => sub { $log_level = $DEBUG },
    verbose => sub { $log_level = $INFO },
    dump    => \my $dump
) and @ARGV == 1 or die "Usage: [OPTIONS] DESIGN_ID\n";

my $design_id = shift @ARGV;

Log::Log4perl->easy_init( { level => $log_level, layount => '%m%n' } );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
    or die "failed to retrieve design $design_id\n";

my $p = HTGT::Utils::MutagenesisPrediction::Design->new( design => $design );

print "Design $design_id targets gene " . $p->target_gene->ensembl_gene_id . ":\n";

for ( @{ $p->summary } ) {
    print join( "\t", @$_ ) . "\n";
}

if ( $dump ) {
    dd $p->detail;
}

