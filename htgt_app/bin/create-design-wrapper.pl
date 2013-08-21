#!/usr/bin/env perl
#
# Wrapper to invoke create_design.pl when invoked as part of an LSF
# job array.
#
# Suggested invocation:
# 
# bsub -J 'designs[1-XXX]%10'-o %I.out -e %I.err -q normal -P team87 create-design-wrapper.pl \
#    /lustre/scratch103/sanger/vvi/vector_design/migp/global_home design_ids.txt
#
# where XXX is $(wc -l design_ids.txt)

use strict;
use warnings FATAL => 'all';

use IO::File;

die "Usage: $0 GLOBAL_HOME DESIGNS_FILE\n"
    unless @ARGV == 2;

my ( $global_home, $infile ) = @ARGV;

my $job_index = $ENV{LSB_JOBINDEX}
    or die "LSB_JOBINDEX not set";

my $design_id;

my $ifh = IO::File->new( $infile, O_RDONLY )
    or die "open $infile: $!";

while ( <$ifh> ) {
    if ( --$job_index == 0 ) {
        chomp( $design_id = $_ );
        last;
    }
}

$ifh->close;

die "Failed to determine design_id for $ENV{LSB_JOB_INDEX}"
    unless $design_id;

exec 'create_design.pl', '-global_home', $global_home, '-design_id', $design_id;
