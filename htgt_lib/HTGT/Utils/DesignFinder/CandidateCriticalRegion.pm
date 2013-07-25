package HTGT::Utils::DesignFinder::CandidateCriticalRegion;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::CriticalRegionError;
use HTGT::Utils::DesignFinder::Constants qw(
  $MIN_5P_INTRON_SIZE
  $MIN_CLEAR_FLANK
  $OVERLAP_GENE_3P_FLANK
  $OVERLAP_GENE_5P_FLANK
  $MIN_POST_DEL_TRANSLATION_SIZE
  $MAX_REINITIATION_PROTEIN_SIZE
  $MAX_ORIG_PROTEIN_PCT
);
use HTGT::Utils::DesignFinder::Helpers qw( exon_3p_utr_length
  exon_5p_utr_length );
use List::Util qw( sum );
use List::MoreUtils qw( firstval lastval firstidx any );
use Bio::Seq;
use HTGT::Utils::EnsEMBL;
use HTGT::Utils::DesignFinder::PartExon;
use HTGT::Utils::DesignPhase qw( get_phase_from_transcript_id_and_U5_oligo
                                 create_U5_oligo_loc_from_cassette_coords );
use Bio::Location::Simple;

with
  qw( MooseX::Log::Log4perl HTGT::Role::EnsEMBL HTGT::Utils::DesignFinder::Stringify );

has gene => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Gene',
    required => 1,
    handles  => [qw( chromosome strand )]
);

has design_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has minimum_3p_intron_size => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has [qw( start end )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has insert_in_3p_utr => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1
);

has insert_in_3p_intergenomic => (
    is       => 'ro',
    isa      => 'Bool',
    required => 1,
);

has max_critical_region_size => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1
);

has length => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1
);

has error => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::CriticalRegionError',
    init_arg => undef,
    writer   => '_set_error',
);

has is_valid => (
    is        => 'ro',
    isa       => 'Bool',
    init_arg  => undef,
    traits    => ['Bool'],
    predicate => 'is_validated',
    handles   => {
        _set_valid   => 'set',
        _set_invalid => 'unset',
    }
);

has targeted_gene => (
    is     => 'ro',
    isa    => 'Bio::EnsEMBL::Gene',
    writer => '_set_targeted_gene',
);

has overlapping_transcript_status => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => '',
);

has start_phase => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1,
);

sub stringify {
    my $self = shift;

    sprintf( '%s:%d-%d,%d',
        $self->chromosome, $self->start, $self->end, $self->strand );
}

around is_valid => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig(@_)
      if $self->is_validated;

    confess("must call validate() before is_valid()");
};

sub add_error {
    my ( $self, $type, @args ) = @_;

    my $error = HTGT::Utils::DesignFinder::CriticalRegionError->new(
        type => $type,
        @args
    );
    $self->_set_error($error);
    $self->_set_invalid;

    return;
}

sub _build_length {
    my $self = shift;

    abs( $self->end - $self->start ) + 1;
}

sub _build_max_critical_region_size {
    my $self = shift;
    if ( $self->design_type eq 'Standard' ) {
        return 3200;
    }
    else {
        return 1750;
    }
}

sub _build_start_phase {
    my $self = shift;

    my $cass_border_left  = $self->gene->strand == 1 ? $self->start - 1 : $self->end;
    my $cass_border_right = $cass_border_left + 1;

    my $u5_oligo_loc = create_U5_oligo_loc_from_cassette_coords( $cass_border_left, $cass_border_right, $self->gene->strand );
    $self->log->debug( "$self CR: " . $self->start . "-" . $self->end . " U5 oligo: "
                           . $u5_oligo_loc->start . "-" . $u5_oligo_loc->end );

    return get_phase_from_transcript_id_and_U5_oligo( $self->gene->template_transcript, $u5_oligo_loc );
}

sub validate {
    my ( $self, @transcripts ) = @_;

    $self->check_size
      or return;

    my $main_transcript = $transcripts[0];

    my $targeted_gene =
      $self->gene_adaptor->fetch_by_transcript_stable_id(
        $main_transcript->stable_id )
      or confess "failed to retrieve gene for transcript "
      . $main_transcript->stable_id;

    $self->_set_targeted_gene($targeted_gene);

    $self->check_overlapping_genes
        or return;

    $self->check_5p_flanking_genes
        or return;

    $self->check_3p_flanking_genes
        or return;

    for my $transcript (@transcripts) {
        $self->check_start_end_in_utr_or_intron($transcript)
            or return;

        $self->check_floxed_exons($transcript)
            or return;

        if ( $self->design_type eq 'Standard' ){
            $self->check_5p_flanking_intron($transcript)
                or return;
        }

        $self->check_3p_flanking_intron($transcript)
            or return;

        $self->check_translation_after_deletion($transcript)
            or return;
    }

    return $self->_set_valid;
}

sub check_size {
    my ($self) = @_;

    if ( $self->length > $self->max_critical_region_size ) {
        return $self->add_error('MaxRegionSizeExceeded');
    }

    return 1;
}

sub check_start_end_in_utr_or_intron {
    my ( $self, $transcript ) = @_;

    for my $exon ( @{ $transcript->get_all_Exons } ) {
        my $exon_start = $exon->coding_region_start($transcript) or next;
        my $exon_end   = $exon->coding_region_end($transcript)   or next;
        unless ($self->design_type ne 'Standard'
            and $self->gene->strand == 1 )
        {
            if ( $self->start > $exon_start and $self->start < $exon_end ) {
                $self->add_error( 'StartInCodingRegion',
                    transcript => $transcript );
                return;
            }
        }
        unless ($self->design_type ne 'Standard'
            and $self->gene->strand == -1 )
        {
            if ( $self->end > $exon_start and $self->end < $exon_end ) {
                $self->add_error( 'EndInCodingRegion',
                    transcript => $transcript );
                return;
            }
        }
    }

    return 1;
}

sub check_overlapping_genes {
    my ($self) = @_;

    my ( $overlap_start, $overlap_end, $min_safe_start, $max_safe_end );

    # If an overlapping non-coding transcript has exons inside the
    # overlapping region, but their splicing is unaffected by the mutation,
    # we can accept this region. We consider the splicing to be unaffected if
    # the exons lie inside the "safe" region:
    #
    #               CE                 CE
    # ------------XXXXXX--------XXXXXXXXXX----->>>
    #      |< 200|                 |200 >|
    #
    # <<<--| OK if all overlapping |--------------
    #      | exons in this region  |
    #      ^                       ^
    #      $min_safe_start         $max_safe_end

    if ( $self->strand == 1 ) {
        $overlap_start  = $self->start - $OVERLAP_GENE_5P_FLANK;
        $overlap_end    = $self->end + $OVERLAP_GENE_3P_FLANK;
        $min_safe_start = $self->start - 200;
        $max_safe_end   = $self->end - 200;
    }
    else {
        $overlap_start  = $self->start - $OVERLAP_GENE_3P_FLANK;
        $overlap_end    = $self->end + $OVERLAP_GENE_5P_FLANK;
        $min_safe_start = $self->start + 200;
        $max_safe_end   = $self->end + 200;
    }

    my $slice = $self->slice_adaptor->fetch_by_region(
        'chromosome', $self->chromosome, $overlap_start,
        $overlap_end, $self->strand
    );
    unless ($slice){
        $self->add_error('UnableToRetrieveSlice');
        return;
    }

    # Find transcripts that belong to genes *other than* the targeted gene
    my @transcripts = grep {
        $self->gene_adaptor->fetch_by_transcript_stable_id( $_->stable_id )
          ->stable_id ne $self->targeted_gene->stable_id
    } @{ $slice->get_all_Transcripts };

    $self->log->debug( @transcripts . " transcripts in overlap" );

    # OK if there are no other transcripts in the overlap region
    return 1 unless @transcripts;

    foreach my $t (@transcripts) {

        # Fail if it's a coding transcript
        if ( $t->biotype eq 'protein_coding' and $t->coding_region_start ) {
            $self->overlapping_transcript_status( 'Region has overlapping coding transcript' );
            return 1;
        }

        # Fail if transcript is in same strand (this check guards against NMD rescue
        # of an overlapping transcript in the same strand; we could relax it and check
        # for NMD rescue explicitly instead)
        if ( $t->strand == $self->strand ) {
            $self->overlapping_transcript_status( 'Region has overlapping transcript in same
 strand' );
            return 1;
        }
        for my $e ( @{ $t->get_all_Exons } ) {
            next
              if $e->end < $overlap_start
                  or $e->start > $overlap_end;    # exon outside overlap region
            next
              if $e->start > $min_safe_start
                  and $e->end < $max_safe_end;    # exon inside "safe" region
            $self->overlapping_transcript_status( 'Region has overlapping exon whose splicing may be affected by mutation' );
            return 1;
        }
    }

    # OK if we get this far
    return 1;
}

sub check_5p_flanking_genes {
    my ($self) = @_;

    # This is to check there are no flanking genes on the same strand
    my $genes_same_strand = $self->genes_in_5p_flank( 1, $MIN_5P_INTRON_SIZE );
    if ( @{$genes_same_strand} ) {
        $self->log->debug( "Genes in 5' flank (same strand): "
              . join( q{, }, map $_->stable_id, @$genes_same_strand ) );
        return $self->add_error('GenesIn5pFlankSameStrand');
    }

# This check is to avoid interfering with the promoter of a gene in the opposite strand
    my $genes_opposite_strand =
      $self->genes_in_5p_flank( -1, $MIN_CLEAR_FLANK );
    if ( @{$genes_opposite_strand} ) {
        $self->log->debug( "Genes in 5' flank (opposite strand): "
              . join( q{, }, map $_->stable_id, @$genes_opposite_strand ) );
        return $self->add_error('GenesIn5pFlankOppositeStrand');
    }

    return 1;
}

sub check_3p_flanking_genes {
    my ($self) = @_;

# This check is to avoid interfering with the promoter of a gene in the same strand
    my $genes_same_strand = $self->genes_in_3p_flank( 1, $MIN_CLEAR_FLANK );
    if ( @{$genes_same_strand} ) {
        $self->log->debug( "Genes in 3' flank (same strand): "
              . join( q{, }, map $_->stable_id, @$genes_same_strand ) );
        return $self->add_error('GenesIn3pFlankSameStrand');
    }

# This check is to avoid interfering with genes in the opposite strand; we could be more
# conservative than this: $MIN_3P_INTRON_SIZE is really
    my $genes_opposite_strand =
      $self->genes_in_3p_flank( -1, $self->minimum_3p_intron_size );
    if ( @{$genes_opposite_strand} ) {
        $self->log->debug( "Genes in 3' flank (opposite strand): "
              . join( q{, }, map $_->stable_id, @$genes_opposite_strand ) );
        return $self->add_error('GenesIn3pFlankOppositeStrand');
    }

    return 1;
}

sub check_floxed_exons {
    my ( $self, $transcript ) = @_;

    my @floxed_exons = @{ $self->floxed_exons($transcript) };
    unless (@floxed_exons) {
        return $self->add_error( 'NoFloxedExons', transcript => $transcript );
    }

    unless ( grep $_->coding_region_start($transcript), @floxed_exons ) {
        return $self->add_error( 'NoCodingExons', transcript => $transcript );
    }

    $self->log->debug(
        "floxed exons: " . $self->floxed_exons_as_str($transcript) );
    my $end_phase   = $floxed_exons[-1]->end_phase;

    $self->log->debug("$self: start phase: " . $self->start_phase . ", end phase: $end_phase");

    if ( $self->design_type ne 'LargeFirstExon' ) {
        if (    $self->start_phase != -1
            and $end_phase != -1
            and $self->start_phase == $end_phase )
        {
            return $self->add_error( 'SymmetricalExons',
                transcript => $transcript );
        }
    }
    return 1;
}

sub check_5p_flanking_intron {
    my ( $self, $transcript ) = @_;

    my $flanking_intron = $self->fivep_intron($transcript);

    return $self->add_error( 'No5pFlankingIntron', transcript => $transcript )
        unless $flanking_intron;

    if ( $flanking_intron->length < $MIN_5P_INTRON_SIZE ) {
        return $self->add_error( 'Small5pFlankingIntron',
            transcript => $transcript );
    }

    return 1;
}

sub check_3p_flanking_intron {
    my ( $self, $transcript ) = @_;

    my $flanking_intron = $self->threep_intron($transcript);

    # There will be no 3' flanking intron if we flox the last exon in the
    # transcript
    if ( $flanking_intron and $flanking_intron->length < $self->minimum_3p_intron_size ) {
        return $self->add_error( 'Small3pFlankingIntron',
            transcript => $transcript );
    }

    return 1;
}

sub check_translation_after_deletion {
    my ( $self, $transcript ) = @_;

    my @exons        = @{ $transcript->get_all_Exons };
    my @floxed_exons = @{ $self->floxed_exons($transcript) };

    # Coding exons before the critical region
    my @lead_exons = grep $_->coding_region_start($transcript),
      List::MoreUtils::before { $_->stable_id eq $floxed_exons[0]->stable_id }
    @exons;

    my $first_exon_not_fully_deleted;
    if( $self->design_type eq 'FalseIntron' ){
        my $first_exon_half = $self->get_first_exon_half( $floxed_exons[0] );
        push @lead_exons, $first_exon_half;
        $first_exon_not_fully_deleted = $floxed_exons[0];
    }
    else{
        $first_exon_not_fully_deleted = $lead_exons[0];
    }

    unless (@lead_exons) {
        $self->log->debug("first critical exon is first coding exon");
        return $self->check_translation_after_deleting_first_coding_exon(
            $transcript);
    }

    my @tail_exons =
      List::MoreUtils::after { $_->stable_id eq $floxed_exons[-1]->stable_id }
    @exons;

    # No need to check for re-initiation if the knockout deletes the last coding exon
    return 1 unless any { $_->coding_region_start($transcript) } @tail_exons;

    my @exons_after_deletion = ( @lead_exons, @tail_exons );

    {
        my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
        Bio::SeqUtils->cat( $seq, map $_->seq, @exons_after_deletion );

        if ( my $utr =
            exon_5p_utr_length( $first_exon_not_fully_deleted, $transcript ) )
        {
            my $length_to_remove;
            if ( $utr > $exons_after_deletion[0]->length ){
                $length_to_remove = $exons_after_deletion[0]->length;
            }
            else{
                $length_to_remove = $utr;
            }
            $seq = $seq->trunc( $length_to_remove + 1, $seq->length );
        }
        $self->log->debug( "sequence after deletion: " . $seq->seq );

        my $translated_seq = $seq->translate( -orf => 1 );
        $self->log->debug(
            "translation after deletion: " . $translated_seq->seq );

        my $translation_length = $translated_seq->length;
        $self->log->debug(
            "length of translation after deletion: $translation_length");

        if ( $translation_length > $MIN_POST_DEL_TRANSLATION_SIZE ) {
            # No re-initiation
            return 1;
        }
    }

    {

        # Check for re-initiation in @tail_exons
        my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
        Bio::SeqUtils->cat( $seq, map $_->seq, @tail_exons );
        $self->log->debug(
            "sequence to consider for re-initiation: " . $seq->seq );
        my $translated_seq =
          $seq->translate( -offset => $tail_exons[0]->phase )->seq;
        $self->log->debug(
            "raw translation of re-initiation seq: " . $translated_seq );
        $translated_seq =~ s/^[^M]+//;

        #$translated_seq =~ s/\*.*$//;
        $self->log->debug("translation after re-initiation: $translated_seq");
        if ( length($translated_seq) < $MAX_REINITIATION_PROTEIN_SIZE ) {
            $self->log->debug(
                "re-initiation, but protein < $MAX_REINITIATION_PROTEIN_SIZE");
            return 1;
        }
    }

    return $self->add_error( 'Reinitiation', transcript => $transcript );
}

sub get_first_exon_half{
    my ( $self, $exon ) = @_;
    my ( $exon_half_start, $exon_half_end );
    if ( $self->gene->strand == 1 ){
        $exon_half_start = $exon->start;
        $exon_half_end = $self->start;
    }
    else{
        $exon_half_start = $self->end;
        $exon_half_end = $exon->end;
    }

    return HTGT::Utils::DesignFinder::PartExon->new(
        id        => $exon->stable_id . 'part',
        gene      => $self->gene,
        start     => $exon_half_start,
        end       => $exon_half_end,
    );
}

sub check_translation_after_deleting_first_coding_exon {
    my ( $self, $transcript ) = @_;

    my @exons        = @{ $transcript->get_all_Exons };
    my @floxed_exons = @{ $self->floxed_exons($transcript) };

    my @head_exons =
      List::MoreUtils::before { $_->stable_id eq $floxed_exons[0]->stable_id }
    @exons;
    my @tail_exons =
      List::MoreUtils::after { $_->stable_id eq $floxed_exons[-1]->stable_id }
    grep $_->coding_region_start($transcript), @exons;

    $self->log->debug( "head exons: " . join q{, },
        map $_->stable_id, @head_exons );
    $self->log->debug( "tail exons: " . join q{, },
        map $_->stable_id, @tail_exons );

    unless (@tail_exons) {
        $self->log->debug("design deletes all coding exons");
        return 1;
    }

    # Construct sequence of exons with critical region excised
    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, @head_exons, @tail_exons );
    $self->log->debug( "sequence after deletion: " . $seq->seq );

    # Compute frame for translation (so we translate the tail in its original frame)
    my $head_length = sum( map $_->length, @head_exons );
    unless( $head_length ){
        $head_length = 0;
    }
    my $frame = ( $head_length - $tail_exons[0]->phase ) % 3;
    $self->log->debug("translating in frame $frame");

    # Truncate 3' utr
    if ( my $utr = exon_3p_utr_length( $tail_exons[-1], $transcript ) ) {
        $seq = $seq->trunc( 1, $seq->length - $utr - 1 );
    }

    # Compute new protein
    my $new_protein = $seq->translate( -frame => $frame )->seq;
    $self->log->debug("raw translation: $new_protein");
    $new_protein =~ s/\*$//;      # Kill the last stop codon
    $new_protein =~ s/^.+\*//;    # Kill leading short sequences
    $new_protein =~ s/^[^M]+//;   # Kill everything before the first start codon
    $self->log->debug( "original protein: " . $transcript->translate->seq );
    $self->log->debug("new protein: $new_protein");

    my $pct_orig_protein =
      _pct_orig_protein( $transcript->translate->seq, $new_protein );
    $self->log->debug("pct_orig_protein: $pct_orig_protein");

    if ( $pct_orig_protein > $MAX_ORIG_PROTEIN_PCT ) {
        return $self->add_error( 'TooMuchProteinProduced',
            transcript => $transcript );
    }

    return 1;
}

sub _pct_orig_protein {
    my ( $orig, $new ) = @_;

    my @orig_aa = split '', $orig;
    my @new_aa  = split '', $new;

    my $count = 0;
    while ( @new_aa and @orig_aa and $new_aa[-1] eq $orig_aa[-1] ) {
        $count++;
        pop @new_aa;
        pop @orig_aa;
    }

    int( $count * 100 / length($orig) );
}

sub floxed_exons {
    my ( $self, $transcript ) = @_;

    [ grep { $_->end >= $self->start and $_->start <= $self->end }
          @{ $transcript->get_all_Exons } ];
}

sub floxed_exons_as_str {
    my ( $self, $transcript ) = @_;

    my @exons        = @{ $transcript->get_all_Exons };
    my @floxed_exons = @{ $self->floxed_exons($transcript) };

    return "No exons floxed in transcript " . $transcript->stable_id
      unless @floxed_exons;

    my $first_exon_ix =
      firstidx { $_->stable_id eq $floxed_exons[0]->stable_id } @exons;
    my $last_exon_ix =
      firstidx { $_->stable_id eq $floxed_exons[-1]->stable_id } @exons;

    sprintf(
        "Exons %s to %s (%d to %d of %d) in transcript %s",
        $floxed_exons[0]->stable_id,
        $floxed_exons[-1]->stable_id,
        $first_exon_ix + 1,
        $last_exon_ix + 1,
        scalar @exons,
        $transcript->stable_id
    );
}

sub fivep_intron {
    my ( $self, $transcript ) = @_;
    my @introns = @{ $transcript->get_all_Introns };

    if ( $self->strand == 1 ) {
        return lastval { $_->end <= $self->start }
        @introns;
    }
    else {
        return lastval { $_->start >= $self->end }
        @introns;
    }
}

sub threep_intron {
    my ( $self, $transcript ) = @_;

    if ( $self->strand == 1 ) {
        return firstval { $_->start >= $self->end }
        @{ $transcript->get_all_Introns };
    }
    else {
        return firstval { $_->end <= $self->start }
        @{ $transcript->get_all_Introns };
    }
}

sub genes_in_3p_flank {
    my ( $self, $strand, $flank_size ) = @_;

    my ( $start, $end );
    if ( $self->strand == 1 ) {
        $start = $self->end + 1;
        $end   = $self->end + $flank_size;
    }
    else {
        $start = $self->start - $flank_size;
        $end   = $self->start - 1;
    }

    $self->_genes_in_flank( $start, $end, $strand );
}

sub genes_in_5p_flank {
    my ( $self, $strand, $flank_size ) = @_;

    my ( $start, $end );
    if ( $self->strand == 1 ) {
        $start = $self->start - $flank_size;
        $end   = $self->start - 1;
    }
    else {
        $start = $self->end + 1;
        $end   = $self->end + $flank_size;
    }

    $self->_genes_in_flank( $start, $end, $strand );
}

sub _genes_in_flank {
    my ( $self, $start, $end, $strand ) = @_;

    my $wanted_strand = $self->strand * $strand;

    my $slice =
      $self->slice_adaptor->fetch_by_region( 'chromosome', $self->chromosome,
        $start, $end, $self->strand );

    my @genes_in_slice = map $_->transform('chromosome'),
      @{ $slice->get_all_Genes };

    my @genes_in_flank = grep {
              $_->stable_id ne $self->targeted_gene->stable_id
          and $_->seq_region_strand == $wanted_strand
          and ( $_->start > $self->end or $_->end < $self->start )
    } @genes_in_slice;

    return \@genes_in_flank;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
