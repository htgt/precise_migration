#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::MutagenesisPrediction;
use HTGT::Utils::DesignFinder::Gene;
use Log::Log4perl ':easy';
use Data::Dump 'dd';

#Requires file with lines: ENS_GENE_ID ENS_TRANSCRIPT_ID TARGET_REGION_START TARGET_REGION_END

Log::Log4perl->easy_init( { level => $DEBUG, layout => '%m%n' } );
my @data;
while( <STDIN> ){
    chomp;
    my ( $gene_id, $transcript_id, $target_region_start, $target_region_end ) = split(/\s/, $_);

    if( $target_region_start > $target_region_end ){
        my $trs_temp = $target_region_start;
        $target_region_start = $target_region_end;
        $target_region_end = $trs_temp;
    }

    my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $gene_id );

    my $mp = HTGT::Utils::MutagenesisPrediction->new(
        target_gene         => $gene,
        transcript_id       => $transcript_id,
        target_region_start => $target_region_start,
        target_region_end   => $target_region_end,
    );

    #INFO( 'Original cdna_coding_region_start: ' . $mp->transcript->cdna_coding_start );
    push @data, $mp->to_hash;
}
dd @data;



