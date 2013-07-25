package HTGT::Utils::DesignFinder::CandidateOligoRegion;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Constants qw( :candidate_oligo_region );
use HTGT::Utils::DesignFinder::Helpers qw( exon_3p_utr_length butfirst );
use HTGT::Utils::Design::FindConstrainedElements qw( find_constrained_elements );
use HTGT::Utils::Design::FindRepeats qw( find_repeats );
use List::Util qw( min max );
use Bio::SeqFeature::Generic;

with qw( MooseX::Log::Log4perl );

has gene => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Gene',
    required => 1,
    handles  => [ 'strand', 'chromosome' ],
);

has critical_region => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::CandidateCriticalRegion',
    required => 1
);

has threep_oligo_region => (
    is         => 'ro',
    isa        => 'Bio::SeqFeature::Generic',
    lazy_build => 1,
);

has max_candidate_oligo_distance => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
);

has minimum_3p_spacer => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
);

has minimum_5p_spacer => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
);

has minimum_oligo_region => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
);

sub _build_threep_oligo_region {
    my $self = shift;

    if ( $self->critical_region->insert_in_3p_utr ) {
        $self->critical_region->log->debug("Inserting D's in 3' UTR");
        return $self->get_3p_utr_region;
    }
    elsif ( $self->critical_region->insert_in_3p_intergenomic ) {
        $self->critical_region->log->debug("Inserting D's 3' of gene");
        return $self->get_3p_genomic_region;
    }
    else {
        $self->critical_region->log->debug("Inserting D's in intron");
        return $self->get_3p_intronic_region;
    }
}

sub get_threep_oligo_region {
    my ( $self, $filter ) = @_;

    my @regions = $self->$filter( $self->threep_oligo_region )
      or return;

    # Prefer the region closest to the critical region
    if ( $self->strand == 1 ) {
        return shift @regions;
    }
    else {
        return pop @regions;
    }
}

sub check_oligo_distance {
    my ( $self, $fivep_oligo_region, $threep_oligo_region ) = @_;

    return unless $fivep_oligo_region and $threep_oligo_region;

    my $distance;
    if ( $self->strand == 1 ) {
        $distance = $threep_oligo_region->start - $fivep_oligo_region->end;
    }
    else {
        $distance = $fivep_oligo_region->start - $threep_oligo_region->end;
    }

    return $distance <= $self->max_candidate_oligo_distance;
}

sub avoid_repeats_and_constrained_elements {
    my ( $self, $region ) = @_;

    $self->critical_region->log->debug('Checking for constrained elements');
    my @ce = grep {
        $_->score >= $MIN_CONSTRAINED_ELEMENT_SCORE
          and $_->length >= $MAX_REPEAT_CE_OVERLAP
      } @{
        find_constrained_elements(
            $self->chromosome, $region->start,
            $region->end,      $region->strand
        )
      };

    $self->critical_region->log->debug('Checking for repeats');
    my @repeats = grep { $_->length >= 20 } @{
        find_repeats(
            $self->chromosome, $region->start,
            $region->end,      $region->strand
        )
      };

    my @to_avoid = sort { $a->start <=> $b->start } @ce, @repeats;

    $self->avoid_regions( $region, $MAX_REPEAT_CE_OVERLAP, @to_avoid );
}

sub avoid_constrained_elements {
    my ( $self, $region ) = @_;

    $self->critical_region->log->debug('Checking for constrained elements');
    my @to_avoid = sort { $a->start <=> $b->start }
      grep { $_->score >= $MIN_CONSTRAINED_ELEMENT_SCORE } @{
        find_constrained_elements(
            $self->chromosome, $region->start,
            $region->end,      $region->strand
        )
      };

    $self->avoid_regions( $region, $MAX_REPEAT_CE_OVERLAP, @to_avoid );
}

sub avoid_regions {
    my ( $self, $region, $max_overlap, @to_avoid ) = @_;

    my ( @good, $lhs, $rhs );

    $lhs = $region->start;
    for my $m (@to_avoid) {
        $rhs = min( $m->start + $max_overlap, $region->end );
        if ( $lhs < $rhs ) {
            push @good,
              Bio::SeqFeature::Generic->new(
                -start       => $lhs,
                -end         => $rhs,
                -strand      => $self->strand,
                -primary_tag => 'misc_feature'
              );
        }
        $lhs = max( $region->start, $m->end - $max_overlap );
    }
    $rhs = $region->end;
    if ( $rhs > $lhs ) {
        push @good,
          Bio::SeqFeature::Generic->new(
            -start       => $lhs,
            -end         => $rhs,
            -strand      => $self->strand,
            -primary_tag => 'misc_feature'
          );
    }

    return grep { $_->length >= $self->minimum_oligo_region } @good;
}

sub get_3p_utr_region {
    my $self = shift;

    my $transcript = $self->gene->template_transcript;
    my $last_ce    = $self->critical_region->floxed_exons($transcript)->[-1];

    my ( $start, $end );
    if ( $self->strand == 1 ) {
        $start = $last_ce->coding_region_end($transcript) || $last_ce->start;
        $end = $last_ce->end;
    }
    else {
        $start = $last_ce->start;
        $end = $last_ce->coding_region_start($transcript) || $last_ce->end;
    }

    return Bio::SeqFeature::Generic->new(
        -start       => $start,
        -end         => $end,
        -strand      => $self->strand,
        -primary_tag => 'misc_feature'
    );
}

sub get_3p_genomic_region {
    my $self = shift;

    my $last_ce =
      $self->critical_region->floxed_exons( $self->gene->template_transcript )
      ->[-1];

    my $region_size = $MIN_CLEAR_FLANK;
    while ( $region_size > $self->critical_region->minimum_3p_intron_size ) {

        # We only check for genes in the opposite strand, as the
        # candidate critical region has already been screened for genes
        # in the same strand inside $MIN_CLEAR_FLANK.
        my $overlapping_genes =
          $self->critical_region->genes_in_3p_flank( -1, $region_size );
        last unless @{$overlapping_genes};
        $region_size -= 10;
    }

    my ( $start, $end );
    if ( $self->strand == 1 ) {
        $start =
          $last_ce->end +
          $self->minimum_3p_spacer;    # XXX Do we need to leave flanking space here?
        $end = $last_ce->end + $region_size;
    }
    else {
        $start = $last_ce->start - $region_size;
        $end   = $last_ce->start - $self->minimum_3p_spacer;    # XXX flanking space?
    }

    return Bio::SeqFeature::Generic->new(
        -start       => $start,
        -end         => $end,
        -strand      => $self->strand,
        -primary_tag => 'misc_feature'
    );
}

sub get_3p_intronic_region {
    my $self = shift;

    my $transcript = $self->gene->template_transcript;

    my $flank_3p_intron = $self->critical_region->threep_intron($transcript)
      or confess "No 3' flanking intron";

    my ( $start_offset, $end_offset );
    if ( $self->strand == 1 ) {
        $start_offset = $self->minimum_3p_spacer;
        $end_offset   = $self->minimum_5p_spacer;
    }
    else {
        $start_offset = $self->minimum_5p_spacer;
        $end_offset   = $self->minimum_3p_spacer;
    }

    my $start = $flank_3p_intron->start + $start_offset;
    my $end = $flank_3p_intron->end - $end_offset;

    return Bio::SeqFeature::Generic->new(
        -start       => $flank_3p_intron->start + $start_offset,
        -end         => $flank_3p_intron->end - $end_offset,
        -strand      => $self->strand,
        -primary_tag => 'misc_feature'
    );
}

sub debug_region {
    my ( $self, $desc, $region ) = @_;

    if ($region) {
        $self->critical_region->log->debug( sprintf '%s: %d-%d, %d',
            $desc, $region->start, $region->end, $region->strand );
    }
    else {
        $self->critical_region->log->debug("$desc: <undef>");
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
