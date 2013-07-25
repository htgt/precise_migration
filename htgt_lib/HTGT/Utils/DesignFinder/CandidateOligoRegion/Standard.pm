package HTGT::Utils::DesignFinder::CandidateOligoRegion::Standard;

use Moose;
use namespace::autoclean;

with qw( MooseX::Log::Log4perl HTGT::Utils::DesignFinder::Stringify );

use HTGT::Utils::DesignFinder::Constants qw( :candidate_oligo_region );
use List::Util qw( max );
use List::MoreUtils qw( all );
use Const::Fast;

extends 'HTGT::Utils::DesignFinder::CandidateOligoRegion';

const my @REQUIRED_PARAMETERS => qw( fivep_block_size fivep_offset fivep_flank threep_block_size threep_offset threep_flank );

has parameters => (
    traits  => [ 'Hash' ],
    handles => {
        map { $_ => [ 'get', $_ ] } @REQUIRED_PARAMETERS
    },
    init_arg   => undef,
    lazy_build => 1,
);

has fivep_oligo_region => (
    is         => 'ro',
    isa        => 'Bio::SeqFeature::Generic',
    lazy_build => 1,
);

has '+max_candidate_oligo_distance' => (
    default => 3200,
);

has '+minimum_3p_spacer' => (
    default => $MIN_3P_SPACER,
);

has '+minimum_5p_spacer' => (
    default => $MIN_5P_SPACER,
);

has '+minimum_oligo_region' => (
    default => $MIN_OLIGO_REGION,
);


sub stringify {
    my $self = shift;

    my $floxed_exons = $self->critical_region->floxed_exons( $self->gene->template_transcript );
    
    join(  q{ },
           $self->gene->ensembl_gene_id,
           $floxed_exons->[0]->stable_id,
           $floxed_exons->[-1]->stable_id,
           $self->critical_region->chromosome,
           $self->critical_region->start,
           $self->critical_region->end,
           $self->fivep_block_size,
           $self->fivep_offset,
           $self->fivep_flank,
           $self->threep_block_size,
           $self->threep_offset,
           $self->threep_flank,
           0
       );
}

sub is_valid {
    my $self = shift;

    all {defined} map $self->$_, @REQUIRED_PARAMETERS;
}


sub _build_parameters {
    my $self = shift;

    $self->critical_region->log->debug( "Building candidate oligo region: " . $self->critical_region->floxed_exons_as_str( $self->gene->template_transcript ) );

    my ( $fivep_oligo_region, $threep_oligo_region ) = $self->get_oligo_regions
        or return {};

    my %parameters;

    @parameters{ qw( fivep_block_size fivep_offset fivep_flank ) } = $self->get_5p_block_offset_flank( $fivep_oligo_region )
        or return {};

    @parameters{ qw( threep_block_size threep_offset threep_flank ) } = $self->get_3p_block_offset_flank( $threep_oligo_region )
        or return {};

    return \%parameters;
}


sub get_oligo_regions {
    my $self = shift;

    # We try to avoid repeats and constrained elements, but if that's not possible fall back to
    # avoiding only constrained elements.

    my $fivep_best      = $self->get_fivep_oligo_region( 'avoid_repeats_and_constrained_elements' );
    my $threep_best     = $self->get_threep_oligo_region( 'avoid_repeats_and_constrained_elements' );
    my $fivep_fallback  = $self->get_fivep_oligo_region( 'avoid_constrained_elements' );
    my $threep_fallback = $self->get_threep_oligo_region( 'avoid_constrained_elements' );

    $self->debug_region( 'fivep_best', $fivep_best );
    $self->debug_region( 'threep_best', $threep_best );
    $self->debug_region( 'fivep_fallback', $fivep_fallback );
    $self->debug_region( 'threep_fallback', $threep_fallback );
    
    if ( $self->check_oligo_distance( $fivep_best, $threep_best ) ) {
        $self->critical_region->log->debug( "avoided repeats and constrained elements" );
        return ( $fivep_best, $threep_best ); 
    }

    if ( $self->check_oligo_distance( $fivep_best, $threep_fallback ) ) {
        $self->critical_region->log->warn( "unable to avoid repeats in 3' oligo region" );
        return ( $fivep_best, $threep_fallback );
    }

    if ( $self->check_oligo_distance( $fivep_fallback, $threep_best ) ) {
        $self->critical_region->log->warn( "unable to avoid repeats in 5' oligo region" );
        return ( $fivep_fallback, $threep_best );
    }

    if ( $self->check_oligo_distance( $fivep_fallback, $threep_fallback ) ) {
        $self->critical_region->log->warn( "unable to avoid repeats in 5' and 3' oligo regions" );
        return ( $fivep_fallback, $threep_fallback );
    }

    $self->critical_region->log->info( $self->critical_region . ": constrained elements prevent computation of valid oligo regions" );
    return;
}

sub get_fivep_oligo_region {
    my ( $self, $filter ) = @_;

    my @regions = $self->$filter( $self->fivep_oligo_region )
        or return;

    # Prefer the region closest to the critical region
    if ( $self->strand == 1 ) {
        return pop @regions;
    }
    else {
        return shift @regions;
    }    
}

sub _build_fivep_oligo_region {
    my $self = shift;
    
    my $flank_5p_intron = $self->critical_region->fivep_intron( $self->gene->template_transcript )
        or confess "no 5' flanking intron";

    my ( $start_offset, $end_offset );
    if ( $self->strand == 1 ) {
        $start_offset = $MIN_3P_SPACER;
        $end_offset   = $MIN_5P_SPACER;
    }
    else {
        $start_offset = $MIN_5P_SPACER;
        $end_offset   = $MIN_3P_SPACER;
    }

    return Bio::SeqFeature::Generic->new(
        -start       => $flank_5p_intron->start + $start_offset,
        -end         => $flank_5p_intron->end - $end_offset,
        -strand      => $flank_5p_intron->strand,
        -primary_tag => 'misc_feature',
    );    
}

sub get_5p_block_offset_flank {
    my ( $self, $oligo_region ) = @_;

    my $min_flank = $self->strand == 1 ? $self->critical_region->start - $oligo_region->end
                  :                      $oligo_region->start - $self->critical_region->end;

    
    $self->get_block_offset_flank( $oligo_region->length + $min_flank, $DEFAULT_5P_SPACER, $min_flank );
}

sub get_3p_block_offset_flank {
    my ( $self, $oligo_region ) = @_;

    my $min_flank =
        $self->strand == 1
      ? $oligo_region->start - $self->critical_region->end
      : $self->critical_region->start - $oligo_region->end;

    $self->get_block_offset_flank( $oligo_region->length + $min_flank,
        $DEFAULT_3P_SPACER, $min_flank );
}

sub get_block_offset_flank {
    my ( $self, $available_space, $default_flank, $min_flank ) = @_;

    my $block  = $DEFAULT_BLOCK;
    my $offset = $DEFAULT_OFFSET;
    my $flank  = max( $min_flank, $default_flank );

    my $flex_flank  = $flank - $min_flank;
    my $flex_block  = $block - $MIN_BLOCK;
    my $flex_offset = $offset - $MIN_OFFSET;

    my $candidate_region_size     = $flank + 2 * $block + $offset;
    my $min_candidate_region_size = $min_flank + 2 * $MIN_BLOCK + $MIN_OFFSET;

    confess "candidate oligo region too small for insertion"
      if $available_space < $min_candidate_region_size;

    my $flex = $candidate_region_size - $available_space;

    if ( $flex > 0 ) {
        my $shrinkage =
          $flex / ( $candidate_region_size - $min_candidate_region_size );
        $self->critical_region->log->debug(
            sprintf( 'Candidate region is bigger than intron: shrinking %.3f',
                $shrinkage )
        );
        $flank  = int( $flank -  ( $shrinkage * $flex_flank ) );
        $block  = int( $block -  ( $shrinkage * $flex_block ) );
        $offset = int( $offset - ( $shrinkage * $flex_offset ) );
    }

    confess "failed to compute valid candidate oligo region"
      if $flank + 2 * $block + $offset > $available_space;

    return ( $block, $offset, $flank );
}


__PACKAGE__->meta->make_immutable;

1;

__END__
