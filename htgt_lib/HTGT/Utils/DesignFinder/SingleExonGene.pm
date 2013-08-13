package HTGT::Utils::DesignFinder::SingleExonGene;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-design/trunk/lib/HTGT/Utils/DesignFinder/SingleExonGene.pm $
# $LastChangedRevision: 6688 $
# $LastChangedBy: rm7 $
# $LastChangedDate: 2012-01-23 13:26:06 +0000 (Mon, 23 Jan 2012) $

use Moose;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::DesignFinder::Constants qw( $MIN_CONSTRAINED_ELEMENT_SCORE );
use HTGT::Utils::EnsEMBL;
use HTGT::Utils::Design::FindConstrainedElements qw( find_constrained_elements );
use Const::Fast;
use List::Util qw( max min );
use namespace::autoclean;

#================================================================================

const my $MINUS_STRAND => -1;

# Don't consider genes whose translation is < $MIN_AA aa (avoids
# potential pseudogenes)

const my $MIN_AA => 100;

# Try to insert at a junctionx AG|G or AG|A

my $INSERT_SITE_RX = qr/AG[GA]/;

# LoxP goes immediately after the stop codon; the distance between
# the cassette and LoxP must be <= $MAX_CASS_LOXP_DIST bp

const my $MAX_CASS_LOXP_DIST => 1750;

# Cassette must be at least $MIN_START_CASS_DIST bp into the exon

const my $MIN_START_CASS_DIST => 100;

# If LoxP is inserted in 3' UTR, it must go at least $MIN_3P_UTR_SPACER bp
# after the stop codon

const my $MIN_3P_UTR_SPACER => 50;

# If LoxP is inserted in 3' intergenic region, it must go at least
# $MIN_3P_GENOMIC_SPACER bp after the gene

const my $MIN_3P_GENOMIC_SPACER => 100;

# ...but it should be within $MAX_3P_GENOMIC_SPACER of the gene

const my $MAX_3P_GENOMIC_SPACER => 500;

# LoxP should be inserted between constrained elements; look for a
# space with at least $MIN_CE_SPACER bp either side.

const my $MIN_CE_SPACER => 25;

# Oligos are $OLIGO_SIZE bp

const my $OLIGO_SIZE => 50;

# The recombineering primers we compute

const my @RECOMBINEERING_PRIMERS => qw( U5 U3 D5 D3 );

#================================================================================

has ensembl_gene_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has max_designs => (
    is  => 'ro',
    isa => 'Int',
);

has gene => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignFinder::Gene',
    lazy_build => 1,
    handles    => [ 'template_transcript' ]
);

with qw( MooseX::Log::Log4perl HTGT::Role::EnsEMBL );

sub BUILD {
    my $self = shift;

    my @transcripts = $self->gene->all_transcripts;

    # Ensure the gene has only one transcript (this constraint might
    # be relaxed in the future, but the current version of the code
    # only checks that a candidate design is valid for the template
    # transcript

    if ( @transcripts > 1 ) {
        @transcripts = grep { $_->analysis->logic_name eq 'ensembl_havana_transcript' } @transcripts;
    }
    
    die "Gene has " . @transcripts . " transcripts\n"
        unless @transcripts == 1;

    # Ensure this is a single-exon gene
    for my $t (@transcripts) {
        my $num_exons = @{ $t->get_all_Exons };
        die "Transcript $t has $num_exons exons\n"
            unless $num_exons == 1;
    }

    # Ensure the main ORF translates to at least $MIN_AA
    my $translation = $self->template_transcript->translation;
    die "Transcript " . $self->template_transcript . " translation < ${MIN_AA}aa\n"
        unless $translation and $translation->length > $MIN_AA;

    return;
}

sub _build_gene {
    my $self = shift;

    return HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $self->ensembl_gene_id );
}

sub find_candidate_insertion_locations {
    my $self = shift;

    my $transcript = $self->template_transcript;
    my $exon = $transcript->get_all_Exons->[0];

    my $min_insert = $MIN_START_CASS_DIST;
    my $max_insert = $exon->cdna_coding_start($transcript)
        + int( ( $exon->cdna_coding_end($transcript) - $exon->cdna_coding_start($transcript) ) / 2 );

    die "Design not possible with current constraints\n"
        if $min_insert >= $max_insert;

    my $exon_seq = $exon->seq->seq;

    my @candidate_insertion_points;
    while ( $exon_seq =~ m/$INSERT_SITE_RX/g ) {
        my $pos = pos($exon_seq) - 1;
        next unless $pos >= $min_insert;
        last if $pos > $max_insert;
        push @candidate_insertion_points, $pos;
    }

    die "No candidate insertion points found for cassette\n"
        unless @candidate_insertion_points;

    $self->log->debug( "Found " . @candidate_insertion_points . " candidate cassette insertion points" );

    # LoxP position is constant, so we can compute that once and use
    # it for all the candidate designs we produce

    my ( $d5_start, $d5_end, $d5_seq, $d3_start, $d3_end, $d3_seq ) = $self->get_loxp_params;

    const my %DESIGN_PARAMS => (
        ensembl_gene_id       => $self->gene->stable_id,
        ensembl_transcript_id => $transcript->stable_id,
        ensembl_exon_id       => $exon->stable_id,
        exon_start            => $exon->seq_region_start,
        exon_end              => $exon->seq_region_end,
        exon_coding_start     => $exon->coding_region_start($transcript),
        exon_coding_end       => $exon->coding_region_end($transcript),
        chromosome            => $self->gene->chromosome,
        strand                => $self->gene->strand,
        D5_seq                => $d5_seq,
        D5_start              => $d5_start,
        D5_end                => $d5_end,
        D3_seq                => $d3_seq,
        D3_start              => $d3_start,
        D3_end                => $d3_end
    );

    my @candidate_designs;

    for my $pos (@candidate_insertion_points) {
        my %this_design_params = %DESIGN_PARAMS;
        $this_design_params{U5_seq} = substr( $exon_seq, $pos - $OLIGO_SIZE, $OLIGO_SIZE );
        $this_design_params{U3_seq} = substr( $exon_seq, $pos, $OLIGO_SIZE );
        $this_design_params{phase} = $self->compute_phase( $pos, $exon, $transcript );
        if ( $transcript->strand == $MINUS_STRAND ) {
            $this_design_params{U5_start} = $self->transform_to_genomic( $exon, $transcript, $pos );
            $this_design_params{U5_end}   = $self->transform_to_genomic( $exon, $transcript, $pos - $OLIGO_SIZE + 1 );
            $this_design_params{U3_start} = $self->transform_to_genomic( $exon, $transcript, $pos + $OLIGO_SIZE );
            $this_design_params{U3_end}   = $self->transform_to_genomic( $exon, $transcript, $pos + 1 );
            $this_design_params{cassette_loxp_dist} = $this_design_params{U5_start} - $this_design_params{D5_start};
        }
        else {
            $this_design_params{U5_start} = $self->transform_to_genomic( $exon, $transcript, $pos - $OLIGO_SIZE + 1 );
            $this_design_params{U5_end}   = $self->transform_to_genomic( $exon, $transcript, $pos );
            $this_design_params{U3_start} = $self->transform_to_genomic( $exon, $transcript, $pos + 1 );
            $this_design_params{U3_end}   = $self->transform_to_genomic( $exon, $transcript, $pos + $OLIGO_SIZE );
            $this_design_params{cassette_loxp_dist} = $this_design_params{D5_end} - $this_design_params{U5_end};
        }

        push @candidate_designs, \%this_design_params;
    }

    # Filter out candidates with too great a distance between Cassette and LoxP
    my @valid_designs = grep { $_->{cassette_loxp_dist} <= $MAX_CASS_LOXP_DIST } @candidate_designs;

    die "No candidate insertion points satisfying cassette/loxp distance constraint found\n"
        unless @valid_designs;

    $self->log->debug( "Found " . @valid_designs . " candidate designs" );

    while ( $self->max_designs and @valid_designs > $self->max_designs ) {
        pop @valid_designs;
    }

    return \@valid_designs;
}

# Compute candidate insertion point for the LoxP. It must go at
# least $MIN_3P_UTR_SPACER bp after the stop codon, and must avoid
# constrained elements. If there is no suitable insertion point in
# the 3' UTR, it must go in the 3' intergenic region.

sub get_loxp_params {
    my $self = shift;

    if ( $self->template_transcript->strand == 1 ) {
        return $self->get_loxp_params_plus;
    }
    else {
        return $self->get_loxp_params_minus;
    }
}

sub get_loxp_params_plus {
    my $self = shift;

    my $transcript = $self->template_transcript;

    my $utr_start = $transcript->coding_region_end;
    my $utr_end   = $transcript->seq_region_end;

    # Try to place the LoxP inside the 3' UTR
    my @candidate_loci = $self->avoid_constrained_elements( $transcript->seq_region_name,
        $utr_start + $MIN_3P_UTR_SPACER - $MIN_CE_SPACER, $utr_end );

    # If that fails, try to place the LoxP in the 3' intergenic region
    if ( @candidate_loci == 0 ) {
        @candidate_loci = $self->avoid_constrained_elements(
            $transcript->seq_region_name,
            $utr_end + $MIN_3P_GENOMIC_SPACER - $MIN_CE_SPACER,
            $utr_end + $MAX_3P_GENOMIC_SPACER - $MIN_CE_SPACER
        ) or die "failed to find suitable locus for LoxP insertion\n";
    }

    # Prefer the most 5' locus
    my $loxp_insert_pos = $candidate_loci[0][0] + $MIN_CE_SPACER;

    my $d5_genomic_start = $loxp_insert_pos - $OLIGO_SIZE;
    my $d5_genomic_end   = $loxp_insert_pos - 1;
    my $d3_genomic_start = $loxp_insert_pos;
    my $d3_genomic_end   = $loxp_insert_pos + $OLIGO_SIZE - 1;

    my $seq = HTGT::Utils::EnsEMBL->slice_adaptor->fetch_by_region( 'chromosome', $transcript->seq_region_name,
        $d5_genomic_start, $d3_genomic_end, 1 )->seq;

    return ( $d5_genomic_start, $d5_genomic_end, substr( $seq, 0, $OLIGO_SIZE ),
        $d3_genomic_start, $d3_genomic_end, substr( $seq, $OLIGO_SIZE, $OLIGO_SIZE ) );
}

sub get_loxp_params_minus {
    my $self = shift;

    my $transcript = $self->template_transcript;

    my $utr_start = $transcript->coding_region_start;
    my $utr_end   = $transcript->seq_region_start;

    # Try to place the LoxP inside the 3' UTR
    my @candidate_loci = $self->avoid_constrained_elements( $transcript->seq_region_name,
        $utr_start, $utr_end - $MIN_3P_UTR_SPACER + $MIN_CE_SPACER );

    # If that fails, try to place the LoxP in the 3' intergenic region
    if ( @candidate_loci == 0 ) {
        @candidate_loci = $self->avoid_constrained_elements(
            $transcript->seq_region_name,
            $utr_start - $MAX_3P_GENOMIC_SPACER + $MIN_CE_SPACER,
            $utr_start - $MIN_3P_GENOMIC_SPACER + $MIN_CE_SPACER
        ) or die "failed to find suitable locus for LoxP inesrtion\n";
    }

    # Prefer the most 5' locus (in the sense of the gene: this is the
    # last one in the list for a gene on the minus strand)
    my $loxp_insert_pos = $candidate_loci[-1][1] - $MIN_CE_SPACER;

    my $d5_genomic_start = $loxp_insert_pos;
    my $d5_genomic_end   = $loxp_insert_pos + $OLIGO_SIZE - 1;
    my $d3_genomic_start = $loxp_insert_pos - $OLIGO_SIZE;
    my $d3_genomic_end   = $loxp_insert_pos - 1;

    my $seq = HTGT::Utils::EnsEMBL->slice_adaptor->fetch_by_region( 'chromosome', $transcript->seq_region_name,
        $d3_genomic_start, $d5_genomic_end, $MINUS_STRAND )->seq;

    return ( $d5_genomic_start, $d5_genomic_end, substr( $seq, 0, $OLIGO_SIZE ),
        $d3_genomic_start, $d3_genomic_end, substr( $seq, $OLIGO_SIZE, $OLIGO_SIZE ) );
}

# The core of this algorithm is lifted from avoid_regions() in
# HTGT::Utils::DesignFinder::CandidateOligoRegion. Should refactor
# to avoid this near copy of code.

sub avoid_constrained_elements {
    my ( $self, $chromosome, $start, $end, $strand ) = @_;

    return if $end - $start < 2 * $MIN_CE_SPACER;

    $strand ||= 1;

    my @ce = grep { $_->score >= $MIN_CONSTRAINED_ELEMENT_SCORE }
        @{ find_constrained_elements( $chromosome, $start, $end, $strand ) };

    my ( @good, $lhs, $rhs );

    $lhs = $start;
    for my $m (@ce) {
        $rhs = min( $m->start, $end );
        if ( $rhs - $lhs > 2 * $MIN_CE_SPACER ) {
            push @good, [ $lhs, $rhs ];
        }
        $lhs = max( $start, $m->end );
    }
    $rhs = $end;
    if ( $rhs - $lhs > 2 * $MIN_CE_SPACER ) {
        push @good, [ $lhs, $rhs ];
    }

    return @good;
}

sub compute_phase {
    my ( $self, $pos, $exon, $transcript ) = @_;

    my $coding_region_start = $exon->cdna_coding_start($transcript);

    if ( $pos < $coding_region_start ) {
        return 'K';
    }

    my $length = $pos - $coding_region_start + 1;
    return $length % 3;
}

sub transform_to_genomic {
    my ( $self, $exon, $transcript, $pos ) = @_;

    die "transform_to_genomic only impleneted for single-exon genes\n"
        unless @{ $transcript->get_all_Exons } == 1;

    if ( $exon->strand == $MINUS_STRAND ) {
        return $exon->end - $pos + 1;
    }
    else {
        return $exon->start + $pos - 1;
    }
}

1;

__END__
