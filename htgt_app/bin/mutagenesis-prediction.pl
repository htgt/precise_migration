#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::MutagenesisPrediction::Design;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Getopt::Long;
use Data::Dump 'dd';
use Path::Class 'file';

my $log_level = $WARN;

GetOptions (
    debug                 => sub { $log_level = $DEBUG },
    verbose               => sub { $log_level = $INFO },
    dump                  => \my $dump,
) or die "Usage: [OPTIONS]\n";

Log::Log4perl->easy_init( { level => $log_level, layout => '%m%n' } );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );
my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

while ( <STDIN> ){
    chomp ( my $design_id = $_ );

    eval {
        my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
            or die "failed to retrieve design $design_id\n";

        my %ens_gene_ids;
        my @projects = $design->projects;
        for my $project ( @projects ){
            my @mgi_gene_ids = map {$_->[0]} @{$dbh->selectall_arrayref( "SELECT mgi_gene_id FROM project WHERE project_id = " . $project->project_id )};

            for my $mgi_gene_id( @mgi_gene_ids ){
                my @ens_ids = map {$_->[0]} @{$dbh->selectall_arrayref( "SELECT ensembl_gene_id FROM mgi_gene WHERE mgi_gene_id = $mgi_gene_id" )};
                for my $ens_id( @ens_ids ){
                    unless ( defined $ens_id ){
                        ERROR( 'Design: ' . $design->design_id . "\nNo EnsEMBL genes linked to MGI gene ID $mgi_gene_id");
                        next;
                    }
                    $ens_gene_ids{ $ens_id }++;
                }
            }
        }

        my @unique_ens_ids = keys %ens_gene_ids;
        my $mps = get_mps( $design, \@unique_ens_ids );
        ERROR( "Design: $design_id\nNo potential target genes identified" ) if scalar @{$mps} == 0;

        for my $mp ( @{$mps} ){
            print "Design $design_id predicted to target gene " . $mp->target_gene->ensembl_gene_id . ":\n";

            for ( @{ $mp->summary } ) {
                print join( "\t", @$_ ) . "\n";
            }

            if ( $dump ) {
                dd $mp->detail;
            }
        }
    };
    if ( $@ ){
        warn "Design ID: $design_id\n";
        warn $@;
    };
}

sub get_mps{
    my ( $design, $ens_gene_ids ) = @_;

    my ( @matched_mp, @unmatched_mps );

    if ( scalar @{$ens_gene_ids} == 1 ){
        my $mp = HTGT::Utils::MutagenesisPrediction::Design->new(
            design          => $design,
            ensembl_gene_id => $ens_gene_ids->[0]
        );
        push( @unmatched_mps, $mp );
        return \@unmatched_mps;
    }

    my $design_transcript = $design->start_exon->transcript->primary_name;

    for my $ens_id( @{$ens_gene_ids} ){
        my $mp = HTGT::Utils::MutagenesisPrediction::Design->new(
            design          => $design,
            ensembl_gene_id => $ens_id
        );

        my $template_transcript;
        eval {
            $template_transcript = $mp->template_transcript;
        };
        next unless defined $template_transcript;
        if ( $design_transcript eq $template_transcript ){
            push( @matched_mp, $mp );
            return \@matched_mp;
        }
        else{
            push( @unmatched_mps, $mp );
        }
    }

    DEBUG( 'No design/project EnsEMBL transcript match for design ' . $design->design_id );
    return \@unmatched_mps;
}
