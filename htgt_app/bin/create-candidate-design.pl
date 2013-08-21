#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::EnsEMBL::Registry;
use Bio::Seq;
use Bio::SeqUtils;
use Getopt::Long;
use List::Util qw( sum min );
use List::MoreUtils qw( firstval lastval any all before after );
use Log::Log4perl ':easy';
use Pod::Usage;
use Readonly;
use HTGT::Utils::DesignFinder::OldHelpers qw( has_valid_intron_length
                                              has_valid_splicing
                                              butfirst
                                              butlast
                                              exon_3p_utr_length
                                              is_nmd_transcript );

use HTGT::Utils::DesignFinder::Constants qw( candidate_region_size );
use Try::Tiny;

Readonly my $SPECIES => 'mouse';

Readonly my $SCORE   => 0; # we don't calculate a score

Readonly my $MAX_CRITICAL_REGION_SIZE      => 3000;
Readonly my $DS_IN_UTR_THRESHOLD           => 2000;

Readonly my $DEFAULT_5P_SPACER             => 300;
Readonly my $MIN_5P_SPACER                 => 180;
Readonly my $FLEX_5P_SPACER                => $DEFAULT_5P_SPACER - $MIN_5P_SPACER;

Readonly my $DEFAULT_BLOCK                 => 120;
Readonly my $MIN_BLOCK                     => 65;
Readonly my $FLEX_BLOCK                    => $DEFAULT_BLOCK - $MIN_BLOCK;

Readonly my $DEFAULT_3P_SPACER             => 100;
Readonly my $MIN_3P_SPACER                 => 40;
Readonly my $FLEX_3P_SPACER                => $DEFAULT_3P_SPACER - $MIN_3P_SPACER;

Readonly my $DEFAULT_OFFSET                => 60;
Readonly my $MIN_OFFSET                    => 20;
Readonly my $FLEX_OFFSET                   => $DEFAULT_OFFSET - $MIN_OFFSET;

Readonly my $IDEAL_INTRON_SIZE             => candidate_region_size( $DEFAULT_5P_SPACER, $DEFAULT_BLOCK, $DEFAULT_OFFSET, $DEFAULT_3P_SPACER );
Readonly my $MIN_INTRON_SIZE               => candidate_region_size( $MIN_5P_SPACER, $MIN_BLOCK, $MIN_OFFSET, $MIN_3P_SPACER );
Readonly my $FLEX_INTRON_SIZE              => $IDEAL_INTRON_SIZE - $MIN_INTRON_SIZE;
Readonly my $MIN_5P_INTRON_SIZE            => $MIN_INTRON_SIZE;
Readonly my $MIN_3P_INTRON_SIZE            => $MIN_INTRON_SIZE;

Readonly my $MIN_3P_FLANK                  => 1500;
Readonly my $MAX_5P_PROTEIN_PCT            => 50;
Readonly my $MIN_POST_DEL_TRANSLATION_SIZE => 40;

Readonly my $MAX_ORIG_PROTEIN_PCT          => 50;

BEGIN {
    Bio::EnsEMBL::Registry->load_registry_from_db(
        #-host => 'ensembldb.ensembl.org',
        #-user => 'anonymous'
        -host => 'ens-livemirror.internal.sanger.ac.uk',
        -user => 'ensro'
    );
}

{
    my $log_level = $WARN;

    GetOptions(
        'help'      => sub { pod2usage( -verbose => 1 ) },
        'man'       => sub { pod2usage( -verbose => 2 ) },
        'debug'     => sub { $log_level = $DEBUG },
        'verbose'   => sub { $log_level = $INFO },
    ) or pod2usage(2);

    Log::Log4perl::easy_init(
        {
            level  => $log_level,
            layout => '%p %x %m%n'
        }
    );

    my @ensembl_gene_ids = @ARGV ? @ARGV : map { chomp; $_ } <STDIN>;                                                      
    
    my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor( $SPECIES, 'core', 'gene' );

    for my $ensembl_gene_id ( @ensembl_gene_ids ) {
        my $gene = $gene_adaptor->fetch_by_stable_id( $ensembl_gene_id );            
        unless ( $gene ) {
            ERROR( "failed to retrieve gene $ensembl_gene_id" );
            next;
        }
        Log::Log4perl::NDC->push( $gene->stable_id );
        try {
            create_design_for_gene( $gene );
        }
        catch {
            FATAL($_);
        };    
        Log::Log4perl::NDC->remove;
    }    
}

sub create_design_for_gene {
    my $gene = shift;

    INFO( "create_design_for_gene " );

    my @transcripts = grep {
        $_->biotype eq 'protein_coding'
            and has_valid_intron_length( $_ )
                and has_valid_splicing( $_ )
                    and !is_nmd_transcript( $_ )
                } @{ $gene->get_all_Transcripts };
    
    my $template_transcript = get_template_transcript( \@transcripts );
    unless ( $template_transcript ) {
        ERROR( "gene has no coding transcripts" );
        return;
    }
    INFO( "template transcript: " . $template_transcript->stable_id );
    Log::Log4perl::NDC->push( $template_transcript->stable_id );
    
    my $exons = $template_transcript->get_all_Exons;
    my $num_exons = @$exons;
    DEBUG( "template transcript has $num_exons exons" );
    
    unless ( $num_exons >= 2 ) {
        ERROR( "template transcript has < 2 exons" );
        return;
    }

    my $first_exon = $exons->[0];
    if ( $first_exon->coding_region_start( $template_transcript)
             and $first_exon->peptide( $template_transcript )->length >= $template_transcript->translation->length / 2 ) {
        ERROR( 'first exon codes for >50% of protein' );
        return;
    }
    
    my @candidate_critical_exons;
    init_errors();

 START_EXON:
    for my $candidate_start_ce_ix ( 1 .. $#{$exons} ) {
        INFO( exon_info( "considering candidate start exon", $exons, $candidate_start_ce_ix ) );
        check_5p_translation( $template_transcript, $exons, $exons->[$candidate_start_ce_ix] )
            or last;
        for my $candidate_end_ce_ix ( $candidate_start_ce_ix .. $#{$exons} ) {
            INFO( exon_info( "considering candidate end exon", $exons, $candidate_end_ce_ix ) );
            check_region_size( $template_transcript,
                               $exons->[$candidate_start_ce_ix],
                               $exons->[$candidate_end_ce_ix],
                               $candidate_end_ce_ix == $#{$exons} )
                or next START_EXON;       
            if ( is_critical_region( $gene, $template_transcript, $exons, $candidate_start_ce_ix, $candidate_end_ce_ix ) ) {
                INFO( sprintf( "exons %d to  %d of %d form a critical region",
                               $candidate_start_ce_ix + 1, $candidate_end_ce_ix + 1, $num_exons ) );
                push @candidate_critical_exons, [ $candidate_start_ce_ix, $candidate_end_ce_ix ];
            }
        }
    }

    unless ( @candidate_critical_exons ) {
        #my $reason = explain_failure( $gene, $template_transcript );
        ERROR( "found no candidate critical exons for template transcript: " . get_errors() );
        return;
    }

    INFO( "found " . @candidate_critical_exons . " candidate regions for template transcript" );
    
    my @other_transcripts = grep is_wanted_transcript( $gene, $template_transcript, $_ ), @transcripts;
    if ( @other_transcripts ) {
        DEBUG( "Other transcripts to consider: " . join( q{, }, map $_->stable_id, @other_transcripts ) );    
        @candidate_critical_exons = grep {
            is_suitable_for_all_transcripts( $gene, $template_transcript, $exons, \@other_transcripts, @$_ )
        } @candidate_critical_exons;
        unless ( @candidate_critical_exons ) {
            ERROR( "found no candidate critical exons suitable for all transcripts" );
            return;
        }
    }
    
    for ( @candidate_critical_exons ) {
        DEBUG( "Candidate region: " . join( q{ }, $gene->stable_id, map $exons->[$_]->stable_id, @$_ ) );
        my ( $first_ce_ix, $last_ce_ix ) = @$_;
        emit_candidate( $gene, $template_transcript, $exons->[ $first_ce_ix ], $exons->[ $last_ce_ix ], $last_ce_ix == $#{$exons} );
    }    
}

sub emit_candidate {
    my ( $gene, $transcript, $first_ce, $last_ce, $last_ce_is_last_exon ) = @_;

    my $insert_in_3p_utr = $last_ce_is_last_exon
        && region_size( $transcript, $first_ce, $last_ce ) > $DS_IN_UTR_THRESHOLD
            && exon_3p_utr_length( $last_ce, $transcript ) > $MIN_INTRON_SIZE;

    my ( $five_block,  $five_offset,  $five_flank  ) = get_5p_block_offset_flank( $gene, $transcript, $first_ce )
        or return;
    
    my ( $three_block, $three_offset, $three_flank ) = get_3p_block_offset_flank( $gene, $transcript, $last_ce, $last_ce_is_last_exon, $insert_in_3p_utr )
        or return;

    my ( $region_start, $region_end ) = get_critical_region_start_end( $gene, $first_ce, $last_ce );        
    
    print join( q{ }, $gene->stable_id, $first_ce->stable_id, $last_ce->stable_id,
                $gene->slice->seq_region_name, $region_start, $region_end,
                $five_block, $five_offset, $five_flank, $three_block, $three_offset, $three_flank, $SCORE ) . "\n";    
}

sub get_5p_block_offset_flank {
    my ( $gene, $transcript, $first_ce ) = @_;
    
    my $flank_5p_intron = get_5p_flanking_intron( $transcript, $first_ce );

    # This should never happen as it has already been checked by check_5p_flanking_intron,
    # but we definitely don't want to carry on here if we have no intron
    unless ( $flank_5p_intron ) {
        ERROR( "no 5' flanking intron" );
        return;
    }

    DEBUG( "5' intron size: " . $flank_5p_intron->length );
    my ( $fivep_spacer, $block, $offset, $threep_spacer ) = get_spacer_block_offset( $flank_5p_intron->length );

    return ( $block, $offset, $fivep_spacer );
}

sub get_3p_block_offset_flank {
    my ( $gene, $transcript, $last_ce, $last_ce_is_last_exon, $insert_in_3p_utr ) = @_;    

    my ( $fivep_spacer, $block, $offset, $threep_spacer );    
    
    if ( $insert_in_3p_utr ) {
        DEBUG( "Inserting D's in 3' UTR" );
        ( $fivep_spacer, $block, $offset, $threep_spacer ) = get_spacer_block_offset( exon_3p_utr_length( $last_ce, $transcript ) );
    }
    elsif ( $last_ce_is_last_exon ) {
        DEBUG( "Inserting D's 3' of gene" );
        ( $fivep_spacer, $block, $offset, $threep_spacer ) = ( $DEFAULT_5P_SPACER, $DEFAULT_BLOCK, $DEFAULT_OFFSET, $DEFAULT_3P_SPACER );
    }
    else {
        DEBUG( "Inserting D's in intron" );        
        my $flank_3p_intron = get_3p_flanking_intron( $transcript, $last_ce );
        unless ( $flank_3p_intron ) {
            ERROR( "no 3' flanking intron" );
            return;
        }
        DEBUG( "3' intron size: " . $flank_3p_intron->length );
        ( $fivep_spacer, $block, $offset, $threep_spacer ) = get_spacer_block_offset( $flank_3p_intron->length );
    }

    return ( $block, $offset, $threep_spacer );
}

sub get_spacer_block_offset {
    my $intron_size = shift;

    DEBUG( "get_spacer_block_offset: intron size: $intron_size" );
    
    my ( $fivep_spacer, $block, $offset, $threep_spacer ) = ( $DEFAULT_5P_SPACER, $DEFAULT_BLOCK, $DEFAULT_OFFSET, $DEFAULT_3P_SPACER );

    my $flex = candidate_region_size( $fivep_spacer, $block, $offset, $threep_spacer ) - $intron_size;
    if ( $flex > 0 ) {
        my $shrinkage = $flex / $FLEX_INTRON_SIZE;        
        DEBUG( sprintf( 'Candidate region is bigger than intron: shrinking %.3f', $shrinkage ) );
        $fivep_spacer  = int( $fivep_spacer  - ( $shrinkage * $FLEX_5P_SPACER ) );
        $block         = int( $block         - ( $shrinkage * $FLEX_BLOCK ) );
        $offset        = int( $offset        - ( $shrinkage * $FLEX_OFFSET ) );
        $threep_spacer = int( $threep_spacer - ( $shrinkage * $FLEX_3P_SPACER ) );
    }
    my $crs = candidate_region_size( $fivep_spacer, $block, $offset, $threep_spacer );
    DEBUG( "candidate region size: $crs" );    
    die "Failed to compute valid candidate region"
        if  $crs > $intron_size;

    return ( $fivep_spacer, $block, $offset, $threep_spacer );
}

sub get_critical_region_start_end {
    my ( $gene, $first_ce, $last_ce ) = @_;

    if ( $gene->strand == 1 ) {
        return ( $first_ce->start, $last_ce->end );
    }
    else {
        return ( $last_ce->start, $first_ce->end );
    }    
}

sub is_suitable_for_all_transcripts {
    my ( $gene, $template_transcript, $exons, $other_transcripts, $first_ce, $last_ce ) = @_;

    DEBUG( exon_info( "is_suitable_for_all_transcripts", $exons, $first_ce, $last_ce ) );
    
    my ( $cr_start, $cr_end ) = get_critical_region_start_end( $gene, $exons->[ $first_ce ], $exons->[ $last_ce ] );
    
    for ( @{ $other_transcripts } ) {
        Log::Log4perl::NDC->push( $_->stable_id );
        my $is_critical = is_critical_for_transcript( $gene, $_, $cr_start, $cr_end );
        Log::Log4perl::NDC->pop;
        return unless $is_critical;
    }

    return 1;
}

sub is_critical_for_transcript {
    my ( $gene, $transcript, $region_start, $region_end ) = @_;

    DEBUG( "is_critical_for_transcript" );

    my @floxed_exons = grep {
        $_->end >= $region_start and $_->start <= $region_end
    } @{ $transcript->get_all_Exons };

    unless ( @floxed_exons ) {
        INFO( "rejecting region: no exons floxed in transcript " . $transcript->stable_id );
        return;
    }

    # Alejo says this check is not needed for secondary transcripts
    #check_5p_translation( $transcript, $transcript->get_all_Exons, $floxed_exons[0] )
    #    or return;

    check_start_end_phase( $floxed_exons[0], $floxed_exons[-1] )
        or return;

    check_5p_flanking_intron( $transcript, $floxed_exons[0] )
        or return;

    check_3p_flanking_intron( $gene, $transcript, $floxed_exons[-1] )
        or return;

    check_translation_after_deletion( $transcript, $transcript->get_all_Exons, $floxed_exons[0], $floxed_exons[-1] )
        or return;

    INFO( "region $region_start - $region_end is critical for transcript" );
    return 1;
}

sub is_wanted_transcript {
    my ( $gene, $template_transcript, $transcript ) = @_;

    DEBUG( "is_wanted_transcript: " . $transcript->stable_id );
    
    # Don't want the template transcript
    return if $transcript->stable_id eq $template_transcript->stable_id;

    # Don't want non-coding transcripts
    DEBUG( "transcript biotype: " . $transcript->biotype );
    return unless $transcript->biotype eq 'protein_coding';

    DEBUG( $transcript->stable_id . " is coding" );
    
    # We exclude transcripts that start or end in the middle of an exon
    # in the template transcript; this is an attempt to prevent an incomplete
    # annotation from muddying the water

    my $first_exon = $transcript->get_all_Exons->[0];
    my $last_exon  = $transcript->get_all_Exons->[-1];
    
    my @template_transcript_exons = @{ $template_transcript->get_all_Exons };
    
    if ( $gene->strand == 1 ) {
        # First exon in transcript starts mid-exon
        return if any { $first_exon->start >= $_->start and $first_exon->end == $_->end } butfirst @template_transcript_exons;
        # Last exon in transcript starts mid-exon
        return if any { $last_exon->start == $_->start and $last_exon->end <= $_->end } butlast @template_transcript_exons;
    }
    else {
        # First exon in transcript starts mid-exon
        return if any { $first_exon->end <= $_->end and $first_exon->start == $_->start } butfirst @template_transcript_exons;        
        # Last exon in transcript starts mid-exon
        return if any { $last_exon->end == $_->end and $last_exon->start >= $_->start } butlast @template_transcript_exons;
    }    

    DEBUG( $transcript->stable_id . " is wanted" );

    return 1;
}

sub exon_info {
    my ( $mesg, $exons, $first_ix, $last_ix ) = @_;

    if ( defined $last_ix ) {
        sprintf( '%s %s - %s (%d - %d of %d',
                 $mesg, $exons->[$first_ix]->stable_id, $exons->[$last_ix]->stable_id,
                 $first_ix + 1, $last_ix + 1, scalar @{ $exons } );
    }
    else {
        sprintf( '%s %s (%d of %d)', $mesg, $exons->[$first_ix]->stable_id, $first_ix + 1, scalar @{$exons} );        
    }
}

sub is_critical_region {
    my ( $gene, $transcript, $exons, $first_ce_ix, $last_ce_ix ) = @_;

    check_start_end_phase( $exons->[$first_ce_ix], $exons->[$last_ce_ix] )
        or return;

    check_5p_flanking_intron( $transcript, $exons->[$first_ce_ix] )
        or return;

    check_3p_flanking_intron( $gene, $transcript, $exons->[$last_ce_ix] )
        or return;

    check_translation_after_deletion( $transcript, $exons, $exons->[$first_ce_ix], $exons->[$last_ce_ix] )
        or return;

    return 1;
}

sub check_start_end_phase {
    my ( $first_ce, $last_ce ) = @_;    
    
    my $start_phase = $first_ce->phase;
    my $end_phase   = $last_ce->end_phase;
    DEBUG( "start phase: $start_phase, end phase: $end_phase" );

    if ( $start_phase != -1 and $end_phase != -1 and $start_phase == $end_phase ) {
        INFO( "rejecting region: start and end are in phase" );
        add_error( 'symmetrical exons' );
        return;
    }

    return 1;
}

sub check_region_size {
    my ( $transcript, $first_ce, $last_ce, $consider_insert_in_utr ) = @_;
    
    my $region_size = region_size( $transcript, $first_ce, $last_ce, $consider_insert_in_utr );
        
    if ( $region_size > $MAX_CRITICAL_REGION_SIZE ) {
        INFO( "rejecting region: size $region_size > $MAX_CRITICAL_REGION_SIZE" );
        return;
    }

    return 1;
}

sub region_size {
    my ( $transcript, $first_ce, $last_ce, $consider_insert_in_utr ) = @_;
    
    my $region_size;
    if ( $first_ce->strand == 1 ) {
        $region_size = $last_ce->end - $first_ce->start + 1;
    }
    else {
        $region_size = $first_ce->end - $last_ce->start + 1;
    }
    DEBUG( "region size: $region_size" );

    if ( $consider_insert_in_utr ) {
        # We might put D's in 3' UTR, in which case the region size
        # could be shorter by as much as the 3' UTR
        my $utr_length = exon_3p_utr_length( $last_ce, $transcript );        
        $region_size -= $utr_length
            if $utr_length > $MIN_3P_INTRON_SIZE;
    }

    return $region_size;
}

sub check_5p_translation {
    my ( $transcript, $exons, $first_floxed_exon ) = @_;
    
    my $total_translation = $transcript->translation->length;
    my $five_p_translation = sum 0, map $_->peptide( $transcript )->length,
        before { $_->stable_id eq $first_floxed_exon->stable_id } @{ $exons };
    
    my $pct_five_p_translation = int( 100 * $five_p_translation / $total_translation );
    DEBUG( "$pct_five_p_translation\% 5' translation in transcript " . $transcript->stable_id );    

    if ( $pct_five_p_translation > $MAX_5P_PROTEIN_PCT ) {
        INFO( "rejecting region: $pct_five_p_translation\% 5' translation in transcript " . $transcript->stable_id );
        return;        
    }

    return 1;
}

sub get_5p_flanking_intron {
    my ( $transcript, $first_ce ) = @_;

    if ( $first_ce->strand == 1 ) {
        return lastval { $_->start < $first_ce->start } @{ $transcript->get_all_Introns };
    }
    else {
        return lastval { $_->start > $first_ce->start } @{ $transcript->get_all_Introns };        
    }
}       

sub check_5p_flanking_intron {
    my ( $transcript, $first_ce ) = @_;

    my $flanking_intron = get_5p_flanking_intron( $transcript, $first_ce );    
    
    # We never flox the first exon, so there should always be a 5' intron
    unless ( $flanking_intron ) {
        ERROR "failed to find a 5' flanking intron";
        return;
    }    

    my $size = $flanking_intron->length;
    DEBUG( "5' flanking intron has length $size" );
    
    if ( $size < $MIN_5P_INTRON_SIZE ) {
        INFO( "rejecting region: 5' intron size $size < $MIN_5P_INTRON_SIZE" );
        add_error( "5' intron too small" );        
        return;
    }

    return 1;
}

sub get_3p_flanking_intron {
    my ( $transcript, $last_ce ) = @_;

    if ( $last_ce->strand == 1 ) {
        return firstval { $_->start > $last_ce->start } @{ $transcript->get_all_Introns };
    }
    else {
        return firstval { $_->start < $last_ce->start } @{ $transcript->get_all_Introns };        
    }
}    

sub check_3p_flanking_intron {
    my ( $gene, $transcript, $last_ce ) = @_;

    my $flanking_intron = get_3p_flanking_intron( $transcript, $last_ce );

    # We might flox the last exon, in which case there will be no 3' intron,
    # and we will either insert the D's in 3' UTR, or in the 3' genomic region.
    unless ( $flanking_intron ) {
        DEBUG( "No 3' flanking intron" );
        return ( check_insert_in_3p_utr( $gene, $transcript, $last_ce )
                     or check_3p_flanking_gene( $gene, $transcript ) );
    }

    my $size = $flanking_intron->length;
    DEBUG( "3' flanking intron has length $size" );

    if ( $size < $MIN_3P_INTRON_SIZE ) {
        INFO( "rejecting region: 3' intron size $size < $MIN_3P_INTRON_SIZE" );
        add_error( "3' intron too small" );
        return;
    }

    return 1;
}

sub check_insert_in_3p_utr {
    my ( $gene, $transcript, $last_ce ) = @_;

    my $utr = exon_3p_utr_length( $last_ce, $transcript );
    
    unless ( $utr and $utr >= $MIN_3P_INTRON_SIZE ) {
        INFO( "rejecting region: 3' UTR ($utr bp) too small for insertion" );
        add_error( "3' UTR too small for insertion" );
        return;
    }

    return 1;
}

sub check_3p_flanking_gene {
    my ( $gene, $transcript ) = @_;

    my $genes_same_strand = get_genes_in_flank( $gene, $transcript, 1, $MIN_3P_FLANK );
    if ( @{ $genes_same_strand } ) {
        INFO( "rejecting region: found genes in ${MIN_3P_FLANK}bp flank on same strand" );
        add_error( "genes in 3' flank (same strand)" );
        return;
    }

    my $genes_opposite_strand = get_genes_in_flank( $gene, $transcript, -1, $MIN_INTRON_SIZE );
    if ( @{ $genes_opposite_strand } ) {
        INFO( "rejecting region: found genes in ${MIN_INTRON_SIZE}bp flank on opposite strand" );
        add_error( "genes in 3' flank (opposite strand)" );
        return;
    }

    return 1;
}

sub get_genes_in_flank {
    my ( $gene, $transcript, $strand, $flank_size ) = @_;

    my $slice_adaptor = Bio::EnsEMBL::Registry->get_adaptor( $SPECIES, 'core', 'slice' );

    my ( $start, $end );
    if ( $transcript->seq_region_strand == 1 ) {
        $start = $transcript->end + 1;
        $end   = $transcript->end + $flank_size;
    }
    else {
        $start = $transcript->start - $flank_size;
        $end   = $transcript->start - 1;
    }

    my $slice = $slice_adaptor->fetch_by_region( 'chromosome', $transcript->seq_region_name, $start, $end, $transcript->seq_region_strand );

    my $wanted_strand = $strand * $transcript->seq_region_strand;
    
    my @genes = grep $_->stable_id ne $gene->stable_id, grep $_->seq_region_strand == $wanted_strand, @{ $slice->get_all_Genes };
    DEBUG( @genes . " genes in ${flank_size}bp 3' flank, strand $strand" );

    return \@genes;
}

sub check_translation_after_deletion {
    my ( $transcript, $exons, $first_ce, $last_ce ) = @_;

    # Coding exons before the critical region
    my @lead_exons = grep $_->coding_region_start( $transcript ),
        before { $_->stable_id eq $first_ce->stable_id } @{ $exons };

    # This condition ensures we don't knock out the first coding exon; this is
    # a temporary measure to keep the code simple: we should implement a more
    # sophisticated algorithm to predict the re-initiation so we can handle knockout
    # of the first coding exon
    unless ( @lead_exons ) {
        DEBUG( "first critical exon is first coding exon" );
        return check_translation_after_deleting_first_coding_exon( $transcript, $exons, $first_ce, $last_ce );
    }

    my @tail_exons = after { $_->stable_id eq $last_ce->stable_id } @{ $exons };
    
    my @exons_after_deletion = ( @lead_exons, @tail_exons );
    DEBUG( "Exons after deletion: " . join q{, }, map $_->stable_id, @exons_after_deletion );    

    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, @exons_after_deletion );

    # If the first exon has UTR, truncate
    if ( my $utr = exon_3p_utr_length( $exons_after_deletion[0], $transcript ) ) {
        DEBUG( "first exon has UTR, truncating seq" );
        $seq = $seq->trunc( $utr + 1, $seq->length );        
    }

    DEBUG( "Sequence after deletion: " . $seq->seq );
    my $translated_seq = $seq->translate( -orf => 1 );
    DEBUG( "Translation after deletion: " . $translated_seq->seq );
    
    my $translation_length = $translated_seq->length;
    DEBUG( "Length of translation after deletion: $translation_length" );

    if ( $translation_length < $MIN_POST_DEL_TRANSLATION_SIZE ) {
        INFO( "rejecting region: post-deletion translation length $translation_length < $MIN_POST_DEL_TRANSLATION_SIZE" );
        add_error( "re-initiation" );
        return;
    }

    return 1;
}

sub check_translation_after_deleting_first_coding_exon {
    my ( $transcript, $exons, $first_ce, $last_ce ) = @_;

    my @head_exons = before { $_->stable_id eq $first_ce->stable_id } @{ $exons };
    my @tail_exons = after  { $_->stable_id eq $last_ce->stable_id  } @{ $exons };

    unless ( @tail_exons ) {
        DEBUG( "Design would delete all coding exons" );
        return 1;        
    }
    
    # Construct sequence of exons with critical region excised
    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, @head_exons, @tail_exons );

    # Compute frame for translation (so we translate the tail in its original frame)
    my $head_length = sum( map $_->length, @head_exons );
    my $frame = ( $head_length - $tail_exons[0]->phase ) % 3;
    
    # Truncate 3' utr
    if ( my $utr = exon_3p_utr_length( $tail_exons[-1], $transcript ) ) {
        $seq = $seq->trunc( 1, $seq->length - $utr - 1 );
    }

    # Compute new protein
    my $new_protein = $seq->translate( -frame => $frame )->seq;
    $new_protein =~ s/^.+\*//;  # Kill leading short sequences
    $new_protein =~ s/^[^M]+//; # Kill everything before the first start codon
    
    my $pct_orig_protein = pct_orig_protein( $transcript->translate->seq, $new_protein );
    DEBUG( "pct_orig_protein: $pct_orig_protein" );

    if ( $pct_orig_protein > $MAX_ORIG_PROTEIN_PCT ) {
        INFO( "rejecting region: $pct_orig_protein\% original protein produced after excision" );
        add_error( "more than $MAX_ORIG_PROTEIN_PCT\% of original protein produced" );
        return;        
    }    
    
    return 1;
}

sub pct_orig_protein {
    my ( $orig, $new ) = @_;

    my @orig_aa = split '', $orig;
    my @new_aa  = split '', $new;

    my $count = 0;    
    while ( @new_aa and @orig_aa and $new_aa[-1] eq $orig_aa[-1] ) {
        $count++;
        pop @new_aa;
        pop @orig_aa;
    }

    int( $count * 100 / length( $orig ) );    
}

sub get_template_transcript {
    my $transcripts = shift;

    DEBUG( "Considering transcripts : " . join q{, }, map $_->stable_id, @{ $transcripts } );    
    
    my @best_transcripts;
    my $longest_transcript_length = 0;
    my $longest_translation_length = 0;

    for my $transcript ( @{ $transcripts } ) {
        my $translation = $transcript->translation
            or next;
        if ( $translation->length > $longest_translation_length ) {
            @best_transcripts = ( $transcript );
            $longest_translation_length = $translation->length;
            $longest_transcript_length = $transcript->length;
        }
        elsif ( $translation->length == $longest_translation_length ) {
            if ( $transcript->length > $longest_transcript_length ) {
                @best_transcripts = ( $transcript );
                $longest_transcript_length = $transcript->length;
            }
            elsif ( $transcript->length == $longest_transcript_length ) {
                push @best_transcripts, $transcript;
            }
        }
    }

    return shift @best_transcripts;
}

{
    my %errors;

    sub init_errors {
        %errors = ();
    }

    sub add_error {
        $errors{$_[0]}++;
    }

    sub get_errors {
        join q{, }, keys %errors;
    }
}       

# sub explain_failure {
#     my ( $gene, $transcript ) = @_;

#     my $total_translation = $transcript->translation->length;
#     my $accum_translation = 0;
#     my @first_half_exons;
#     for my $exon ( @{ $transcript->get_all_Exons } ) {
#         push @first_half_exons, $exon;
#         $accum_translation += $exon->peptide( $transcript )->length;
#         last if $accum_translation > $total_translation / 2;
#     }

#     my @first_half_coding_exons = after { defined $_->coding_region_start( $transcript ) } @first_half_exons;
    
#     my @errors;

#     push @errors, 'first half symmetrical'
#         if all { is_symmetrical( $_ ) } @first_half_coding_exons;

#     # XXX Should this be different for the reverse strand?
#     my $first_protein_domain_start = min map $_->start, @{ $transcript->translation->get_all_DomainFeatures };

#     push @errors, 'first half codes for domains'
#         if $first_protein_domain_start <= $total_translation / 2;

#     # XXX Check for small introns
    
#     return join q{, }, @errors;
# }

# sub is_symmetrical {
#     my $exon = shift;

#     defined( $exon->phase )
#         and defined( $exon->end_phase )
#             and $exon->phase != -1
#                 and $exon->end_phase != -1
#                     and $exon->phase == $exon->end_phase;
# }

__END__

=pod

=head1 NAME

create-design.pl

=head1 SYNOPSIS

  create-design.pl ENSEMBL_GENE_ID

=cut

