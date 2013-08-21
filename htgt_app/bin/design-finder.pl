#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::EnsEMBL::Registry;
use Getopt::Long;
use HTGT::Utils::DesignFinder::StandardDesign;
use HTGT::Utils::DesignFinder::FalseIntronDesign::LargeFirstExonDesign;
use HTGT::Utils::DesignFinder::FalseIntronDesign::SmallIntronDesign;
use HTGT::Utils::DesignFinder::Gene;
use Log::Log4perl ':easy';
use Pod::Usage;
use Try::Tiny;
use YAML::Syck 'Dump';
use Const::Fast;

const my $MAX_DESIGNS => 10;

{
    my $log_level = $WARN;

    GetOptions(
        'help'      => sub { pod2usage( -verbose => 1 ) },
        'man'       => sub { pod2usage( -verbose => 2 ) },
        'debug'     => sub { $log_level = $DEBUG },
        'verbose'   => sub { $log_level = $INFO },
        'species=s' => \my $species,
    ) or pod2usage(2);

    Log::Log4perl::easy_init(
        {
            level  => $log_level,
            layout => '%p %x %m%n'
        }
    );

    $HTGT::Role::EnsEMBL::SPECIES = $species if defined $species;

    my @ensembl_gene_ids = @ARGV ? @ARGV : map { chomp; $_ } <STDIN>;
    
    for my $ensembl_gene_id ( @ensembl_gene_ids ) {
        Log::Log4perl::NDC->push( $ensembl_gene_id );
        try {
            my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $ensembl_gene_id );

            my $df;
            my ( @candidate_designs, @selected_designs );
            if ( is_valid_gene( $gene ) ){
                $df = get_design_finder( $gene );
                $df->find_candidate_critical_regions;
                if ( $df->has_candidate_oligo_regions ) {
                    WARN( $_ ) for $df->warnings;
                    for my $cor ( $df->candidate_oligo_regions ){
                        push @candidate_designs, get_design_parameters( $cor );
                    }
                }
                else {
                    ERROR( $_ ) for $df->errors;
                }
                @selected_designs = select_designs( \@candidate_designs );
            }
            print Dump( @selected_designs );
        }
        catch {
            FATAL($_);
        };
        Log::Log4perl::NDC->remove;
    }
}

sub is_valid_gene{
    my ( $gene ) = @_;

    unless ( $gene->has_valid_coding_transcripts ) {
        ERROR( 'Gene has no coding transcripts' );
        return;
    }

    if ( $gene->has_transcripts_starting_after_half_protein ) {
        ERROR( 'Valid transcript in second half of main protein' );
        return;
    }

    unless ( $gene->has_complete_transcripts ) {
        ERROR( 'Gene has no complete transcripts' );
        return;
    }

    if ( $gene->has_incomplete_transcripts ) {
        WARN( 'Ignoring incomplete transcripts: ' . join q{, }, map $_->stable_id, $gene->incomplete_transcripts );
    }
    return 1;
}


sub get_design_finder{
    my ( $gene ) = @_;

    if ( $gene->first_exon_codes_more_than_50pct_protein ){
        DEBUG( 'Attempting to create LargeFirstExon design' );
        return HTGT::Utils::DesignFinder::FalseIntronDesign::LargeFirstExonDesign->new( gene => $gene );
    }
    if ( $gene->has_small_introns || $gene->has_symmetrical_exons ){
        DEBUG( 'Attempting to create SmallIntron design' );
        return HTGT::Utils::DesignFinder::FalseIntronDesign::SmallIntronDesign->new( gene => $gene );
    }

    DEBUG( 'Attempting to create Standard design' );
    return HTGT::Utils::DesignFinder::StandardDesign->new( gene => $gene );
}

sub get_design_parameters{
    my ( $cor ) = @_;
    my $floxed_exons = $cor->critical_region->floxed_exons( $cor->gene->template_transcript );

    my %design_params = (
        ensembl_gene_id           => $cor->gene->stable_id,
        design_type               => $cor->critical_region->design_type,
        ensembl_transcript_id     => $cor->gene->template_transcript->stable_id,
        chromosome                => $cor->gene->chromosome,
        strand                    => $cor->gene->strand,
        first_critical_exon       => $floxed_exons->[0]->stable_id,
        last_critical_exon        => $floxed_exons->[-1]->stable_id,
        transcript_overlap_status => $cor->critical_region->overlapping_transcript_status,
        phase                     => $cor->critical_region->start_phase,
    );

    if ( $design_params{ design_type } eq 'Standard' ){
        add_standard_design_params( \%design_params, $cor );
    }
    else{
        add_false_intron_design_params( \%design_params, $cor );
    }

    return \%design_params;
}

sub add_standard_design_params{
    my ( $design_params, $cor ) = @_;

    ${ $design_params }{ min_fivep_spacer } = $cor->fivep_flank;
    ${ $design_params }{ min_threep_spacer } = $cor->threep_flank;
    ${ $design_params }{ fivep_block_size } = $cor->fivep_block_size;
    ${ $design_params }{ threep_block_size } = $cor->threep_block_size;
    ${ $design_params }{ fivep_offset } = $cor->fivep_offset;
    ${ $design_params }{ threep_offset } = $cor->threep_offset;
    ${ $design_params }{ target_start } = $cor->critical_region->start;
    ${ $design_params }{ target_end } = $cor->critical_region->end;

    return;
}

sub add_false_intron_design_params{
    my ( $design_params, $cor, $floxed_exons ) = @_;

    ${ $design_params }{ u5_start } = $cor->u5_start;
    ${ $design_params }{ u5_end } = $cor->u5_end;
    ${ $design_params }{ u3_start } = $cor->u3_start;
    ${ $design_params }{ u3_end } = $cor->u3_end;
    ${ $design_params }{ d5_start } = $cor->d5_start;
    ${ $design_params }{ d5_end } = $cor->d5_end;
    ${ $design_params }{ d3_start } = $cor->d3_start;
    ${ $design_params }{ d3_end } = $cor->d3_end;
    return;
}

sub select_designs{
    my ( $candidate_designs ) = @_;

    if ( @{ $candidate_designs } <= $MAX_DESIGNS ){
        return @{ $candidate_designs };
    }

    my ( $non_k_designs, $k_designs ) = separate_k_designs( $candidate_designs );

    my $ranked_non_k_designs;
    if ( @{ $non_k_designs } >= $MAX_DESIGNS ){
        $ranked_non_k_designs = sort_designs( $non_k_designs );
        return( @{ $ranked_non_k_designs }[ 0 .. $MAX_DESIGNS-1 ] );
    }

    my $ranked_k_designs = sort_designs( $k_designs );
    my $k_designs_required = $MAX_DESIGNS - @{ $non_k_designs };
    push @{ $non_k_designs }, @{ $ranked_k_designs }[ 0 .. $k_designs_required-1 ];

    return @{ $non_k_designs};
}

sub separate_k_designs{
    my ( $candidate_designs ) = @_;

    my ( @k_designs, @non_k_designs );
    for my $design( @{ $candidate_designs } ){
        if ( ${ $design }{ phase } and ${ $design }{ phase } == -1 ){
            push @k_designs, $design;
        }
        else{
            push @non_k_designs, $design;
        }
    }
    return ( \@non_k_designs, \@k_designs );
}

sub sort_designs{
    my ( $designs ) = @_;

    my @designs_to_sort = map{ [ get_u_pos_ranking( $_ ), get_cr_length( $_ ), $_ ] } @{ $designs };
    @designs_to_sort = sort{ $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @designs_to_sort;
    my @sorted_designs = map{ $_->[2] } @designs_to_sort;

    return \@sorted_designs;
}

sub get_cr_length{
    my ( $design ) = @_;

    my ( $start, $end );
    if( ${ $design }{ design_type } eq 'Standard' ){
        $start = ${ $design }{ target_start };
        $end = ${ $design }{ target_end };
    }
    else{
        $start = ${ $design }{ u5_start };
        $end = ${ $design }{ d5_start };
    }

    return ( abs( $end - $start ) + 1 );
}

sub get_u_pos_ranking{
    my ( $design ) = @_;

    my $u_to_start_length;
    if ( ${ $design }{ design_type } eq 'Standard' ){
        return 10000 - ${ $design }{ min_fivep_spacer };
    }
    else{
        if( ${ $design}{ strand } == 1 ){
            return ${ $design }{ u5_end };
        }
        else{
            return 1000000000000 - ${ $design }{ u5_end };
        }
    }
}


=pod

=head1 NAME

design-finder.pl

=head1 SYNOPSIS

  design-finder.pl [OPTIONS] [ENSEMBL_GENE_ID ...]

=cut
