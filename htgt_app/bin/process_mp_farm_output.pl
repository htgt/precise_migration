#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Log::Log4perl ':easy';
use HTGT::DBFactory;
use YAML::Any 'Dump';

my $log_level = $WARN;

GetOptions (
    debug   => sub{ $log_level = $DEBUG },
    verbose => sub{ $log_level = $INFO }
) or die "Usage: [--debug|--verbose]\n";

Log::Log4perl->easy_init( { level => $log_level, layout => '%m%n' } );

my ( $design_id, $ens_gene_id, $transcript_id, $transcript_type,
     $is_main_transcript, $prediction,
     %design_details, %transcript_details, %project_details );
my $transcript_count = 0;

my $htgt = HTGT::DBFactory->connect('eucomm_vector');

while ( <STDIN> ){
    chomp( my $line = $_ );

    if ( $line =~ /^Design \d+ predicted to target/ ){
        $transcript_count = 0;
        ( $design_id, $ens_gene_id ) = $line =~ /^Design (\d+) predicted to target gene (ENSMUSG\d+):$/;
        my $design = $htgt->resultset( 'Design' )->find( {design_id => $design_id } )
            or die "Could not retrieve design $design_id";
        $design_details{$design_id} = {
            gene    => $ens_gene_id,
            type    => $design->design_type,
            subtype => $design->subtype
        };

        my @projects = $htgt->resultset( 'Project' )->search( { design_id => $design_id } )->all;
        next unless scalar @projects >= 1;

        my $mgi_details_added = 0;
        for my $project( @projects ){
            if ( $mgi_details_added == 0 ){
                my @mgi_genes = $htgt->resultset('MGIGene')->search( { mgi_gene_id => $project->mgi_gene_id } )->all;
                my $mgi_gene = $mgi_genes[0];
                $design_details{$design_id}{ mgi_accession_id } = $mgi_gene->mgi_accession_id;
                $design_details{$design_id}{ marker_symbol } = $mgi_gene->marker_symbol;
                $mgi_details_added = 1;
            }

            push @{ $design_details{$design_id}{projects} }, $project->project_id;
            $project_details{$project->project_id} = {
                status => $project->status->name
            };
        }
        next;
    }

    next unless $line =~ /^ENSMUST/;
    $transcript_count++;
    ( $transcript_id, $transcript_type, $prediction ) = $line =~ /^(ENSMUST\d+)\t(.+)\t(.+)$/;
    $is_main_transcript = $transcript_count == 1 ? 1 : 0;

    $transcript_details{ $transcript_id } = {
        is_main_transcript => $is_main_transcript,
        type               => $transcript_type,
        prediction         => $prediction
    };

    push @{ $design_details{$design_id}{transcripts} }, $transcript_id;
}

my $data = {
    designs     => \%design_details,
    transcripts => \%transcript_details,
    projects    => \%project_details
};

print Dump( $data );
