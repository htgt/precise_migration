#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Path::Class;

my ( $design_id, $ens_gene_id, $transcript_id, $transcript_type, $is_main_transcript, $prediction, %design_details, %transcript_details, %project_details );
my $transcript_count = 0;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

while( <> ){
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

generate_report( \%design_details, \%project_details, \%transcript_details );

sub get_filehandles{
    my $full_report_file      = file("plated-designs-mp-report.csv");
    my $main_fail_report_file = file("plated-designs-main-transcript-fails.csv");
    my $pc_fail_report_file   = file("plated-designs-protein-coding-fails.csv");
    my $any_fail_report_file  = file("plated-designs-transcript-fails.csv");

    my $full_fh      = $full_report_file->openw();
    my $main_fail_fh = $main_fail_report_file->openw();
    my $pc_fail_fh   = $pc_fail_report_file->openw();
    my $any_fail_fh  = $any_fail_report_file->openw();

    return ( $full_fh, $main_fail_fh, $pc_fail_fh, $any_fail_fh );
}

sub generate_report{
    my ( $design_details, $project_details, $transcript_details ) = @_;

    my ( $full_fh, $main_fail_fh, $pc_fail_fh, $any_fail_fh ) = get_filehandles();

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

sub print_row{
    my ( $design_id, $project_id, $transcript_id, $design_details, $project_details, $transcript_details, $fh ) = @_;

    my @columns = ( $project_id, $project_details->{$project_id}{status}, $design_id, $design_details->{$design_id}{type}, $design_details->{$design_id}{subtype}, $design_details->{$design_id}{marker_symbol}, $design_details->{$design_id}{mgi_accession_id}, $design_details->{$design_id}{gene}, $transcript_id, $transcript_details->{$transcript_id}{is_main_transcript}, $transcript_details->{$transcript_id}{type}, $transcript_details->{$transcript_id}{prediction} );

    for my $i( 0 .. scalar @columns -1 ){
        $columns[$i] = defined $columns[$i] ? $columns[$i] : '';
    }
    $fh->print( join( ',', @columns ) . "\n" );

    return;
}
