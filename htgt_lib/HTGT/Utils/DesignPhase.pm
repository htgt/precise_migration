package HTGT::Utils::DesignPhase;

use Sub::Exporter -setup => { exports => [qw( get_phase_from_transcript_id_and_U5_oligo
                                              get_phase_from_design_and_transcript
                                              compute_and_set_phase
                                              create_U5_oligo_loc_from_cassette_coords
                                              phase_warning_comment )] };
use HTGT::Utils::EnsEMBL;
use Data::Dump 'pp';
use Log::Log4perl ':easy';
use Carp 'confess';

sub compute_and_set_phase{
    my ( $design , $transcript_id ) = @_;

    defined( my $phase = get_phase_from_design_and_transcript( $design, $transcript_id ) )
        or confess "Failed to compute phase";

    my $existing_phase = defined $design->phase ? $design->phase : '<undef>';
    if ( $existing_phase eq $phase ) {
        INFO( "Design has phase $phase" );
        return;
    }

    WARN( "Existing phase $existing_phase, but computed phase is $phase" );

    $design->update( {
        phase       => $phase,
        edited_date => \'current_timestamp',
        edited_by   => $ENV{USER}
    } );

    return;
}

sub get_phase_from_design_and_transcript {
    my ( $design, $transcript_id ) = @_;
    my $features     = $design->validated_display_features;

    confess "No U5 oligo for design" unless defined $features->{U5};
    my $u5_oligo_loc = Bio::Location::Simple->new(
        -start  => $features->{U5}->feature_start,
        -end    => $features->{U5}->feature_end,
        -strand => $features->{U5}->feature_strand
    );

    my $transcript;
    if ($transcript_id) {
        $transcript = HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $transcript_id );
    }
    else {
        $transcript = $design->info->target_transcript;
        $transcript = $transcript->transform('chromosome');
    }

    return get_phase_from_transcript_id_and_U5_oligo( $transcript, $u5_oligo_loc );
}

sub get_phase_from_transcript_id_and_U5_oligo {
    my ( $transcript_or_id, $u5_oligo_loc ) = @_;

    my $transcript;
    if ( ref $transcript_or_id ) {
        $transcript = $transcript_or_id;
    }
    else {
        $transcript = HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $transcript_or_id );
    }

    confess "No transcript"
        unless defined $transcript;

    TRACE( sub { pp( _debug_data( $transcript, $first_floxed_exon, $upstream_exons, $u5_oligo_loc ) ) } );

    return design_phase( $transcript, $u5_oligo_loc );
}

sub design_phase {
    my ( $transcript, $u5_oligo_loc ) = @_;

    my $coding_bases = 0;
    if ( $transcript->strand == 1 ) {
        my $cs = $u5_oligo_loc->end + 1;
        if ( $transcript->coding_region_start > $cs or $transcript->coding_region_end < $cs ){
            return -1;
        }
        for my $e ( @{ $transcript->get_all_Exons } ){
            next unless $e->coding_region_start( $transcript );
            last if $e->seq_region_start > $cs;
            if ( $e->seq_region_end < $cs ){
                $coding_bases += $e->coding_region_end( $transcript ) - $e->coding_region_start( $transcript ) + 1;
            }
            else{
                $coding_bases += $cs - $e->coding_region_start( $transcript );
            }
        }
    }
    else{
        my $ce = $u5_oligo_loc->start -1;
        if ( $transcript->coding_region_start > $ce or $transcript->coding_region_end < $ce ){
            return -1;
        }
        for my $e ( @{ $transcript->get_all_Exons } ){
            next unless $e->coding_region_start( $transcript );
            last if $e->coding_region_end( $transcript ) < $ce;
            if ( $e->seq_region_start > $ce ){
                $coding_bases += $e->coding_region_end( $transcript ) - $e->coding_region_start( $transcript ) + 1;
            }
            else{
                $coding_bases += $e->coding_region_end( $transcript ) - $ce;
            }
        }
    }
    return $coding_bases %3;
}

sub phase_warning_comment {
    my ( $transcript ) = @_;

        $transcript = HTGT::Utils::EnsEMBL->transcript_adaptor->fetch_by_stable_id( $transcript );
        if (! has_valid_start_codon($transcript)){
            return 'Non-ATG start codon / Partial Translation';
        }
    return;
}

sub has_valid_start_codon {
    my ( $transcript ) = @_;

    if ( my $s = $transcript->cdna_coding_start ) {
        my $first_codon = $transcript->seq->subseq( $s, $s+2 );
        if ( $first_codon eq 'ATG' ) {
            return 1;
        }
    }

    return;
}

sub _debug_data {
    my ( $transcript, $first_floxed_exon, $upstream_exons, $u5_oligo_loc, $u3_oligo_loc ) = @_;

    my %data = (
        transcript_id                 => $transcript->stable_id,
        transcript_strand             => $transcript->strand,
        transcript_start              => $transcript->start,
        transcript_end                => $transcript->end,
        u5_start                      => $u5_oligo_loc->start,
        u5_end                        => $u5_oligo_loc->end,
    );

    return \%data;
}

sub create_U5_oligo_loc_from_cassette_coords{
    my ( $cassette_start, $cassette_end, $strand ) = @_;

    if ( $cassette_start > $cassette_end ){
        ( $cassette_start, $cassette_end ) = ( $cassette_end, $cassette_start );
    }

    my ( $u5_start, $u5_end );
    if ( $strand == 1 ){
        $u5_start = $cassette_start - 49;
        $u5_end = $cassette_start;
    }
    else{
        $u5_start = $cassette_end;
        $u5_end = $cassette_end + 49;
    }

    my $u5_oligo_loc = Bio::Location::Simple->new(
        -start => $u5_start,
        -end => $u5_end,
        -strand => $strand,
    );

    return $u5_oligo_loc;
}
1;
