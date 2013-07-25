package HTGT::Utils::DesignFinder::CandidateOligoRegion::FalseIntron;

use Moose;
use namespace::autoclean;

with qw( MooseX::Log::Log4perl HTGT::Utils::DesignFinder::Stringify );

use HTGT::Utils::DesignFinder::Constants qw( :candidate_oligo_region );

use List::MoreUtils qw( all );
use Const::Fast;

extends 'HTGT::Utils::DesignFinder::CandidateOligoRegion';

const my @REQUIRED_PARAMETERS => qw( u5_start u5_end u3_start u3_end
                                     d5_start d5_end d3_start d3_end
                               );

has parameters => (
    traits  => [ 'Hash' ],
    handles => {
        map { $_ => [ 'get', $_ ] } @REQUIRED_PARAMETERS
    },
    init_arg   => undef,
    lazy_build => 1,
);

has cassette_insertion_point => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has '+max_candidate_oligo_distance' => (
    default => 1700,
);

has '+minimum_3p_spacer' => (
    default => $MIN_3P_SPACER,
);

has '+minimum_5p_spacer' => (
    default => $MIN_5P_SPACER,
);

has '+minimum_oligo_region' => (
    default => 100,
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
           $self->u5_start,
           $self->u5_end,
           $self->u3_start,
           $self->u3_end,
           $self->d5_start,
           $self->d5_end,
           $self->d3_start,
           $self->d3_end
       );
}

sub is_valid {
    my $self = shift;

    all {defined} map $self->$_, @REQUIRED_PARAMETERS;
}


sub _build_parameters {
    my $self = shift;

    $self->critical_region->log->debug( "Building candidate oligo region: " . $self->critical_region->floxed_exons_as_str( $self->gene->template_transcript ) );

    my ($threep_oligo_region ) = $self->get_oligo_region
        or return {};

    my %parameters;

    @parameters{ qw( u5_start u5_end u3_start u3_end phase ) } = $self->get_upstream_locations( $self->cassette_insertion_point )
        or return {};

    @parameters{ qw( d5_start d5_end d3_start d3_end ) } = $self->get_downstream_locations( $threep_oligo_region )
        or return {};

    return \%parameters;
}

sub get_oligo_region {
    my $self = shift;

    # We try to avoid repeats and constrained elements, but if that's not possible fall back to
    # avoiding only constrained elements.

    my $threep_best     = $self->get_threep_oligo_region( 'avoid_repeats_and_constrained_elements' );
    my $threep_fallback = $self->get_threep_oligo_region( 'avoid_constrained_elements' );

    $self->debug_region( 'threep_best', $threep_best );
    $self->debug_region( 'threep_fallback', $threep_fallback );

    my $cassette_insertion_region = Bio::SeqFeature::Generic->new(
        -start       => $self->cassette_insertion_point,
        -end         => $self->cassette_insertion_point,
        -strand      => $self->gene->strand,
        -primary_tag => 'misc_feature'
    );

    if ( $self->check_oligo_distance( $cassette_insertion_region, $threep_best ) ) {
        $self->log->debug( "avoided repeats and constrained elements in 3' oligo region" );
        return $threep_best;
    }

    if ( $self->check_oligo_distance( $cassette_insertion_region, $threep_fallback ) ) {
        $self->critical_region->log->warn( "unable to avoid repeats in 3' oligo region" );
        return $threep_fallback;
    }

    $self->critical_region->log->info( $self->critical_region . ": constrained elements prevent computation of valid oligo regions" );
    return;
}

sub get_upstream_locations{
    my ( $self, $cassette_insertion_point ) = @_;

    my ($u5_start, $u5_end, $u3_start, $u3_end );
    if ($self->gene->strand == 1 ){
        $u5_start = $cassette_insertion_point - $OLIGO_SIZE;
        $u5_end = $cassette_insertion_point - 1;
        $u3_start = $cassette_insertion_point;
        $u3_end = $cassette_insertion_point + $OLIGO_SIZE - 1;
    }
    else{
        $u5_start = $cassette_insertion_point + 1;
        $u5_end = $cassette_insertion_point + $OLIGO_SIZE;
        $u3_start = $cassette_insertion_point - $OLIGO_SIZE + 1;
        $u3_end = $cassette_insertion_point;
    }

    return ( $u5_start, $u5_end, $u3_start, $u3_end);
}

sub get_downstream_locations{
    my ( $self, $threep_oligo_region ) = @_;

    my $oligo_region_length = $threep_oligo_region->end - $threep_oligo_region->start + 1;
    my $midpoint = $threep_oligo_region->start + int( $oligo_region_length / 2 );

    my ( $d5_start, $d5_end, $d3_start, $d3_end );
    if ( $self->gene->strand == 1 ){
        $d5_start = $threep_oligo_region->start,
        $d5_end = $threep_oligo_region->start + $OLIGO_SIZE - 1;
        $d3_start = $threep_oligo_region->start + $OLIGO_SIZE;
        $d3_end = $threep_oligo_region->start + ( 2 * $OLIGO_SIZE ) - 1;
    }
    else{
        $d5_start = $threep_oligo_region->end - $OLIGO_SIZE + 1;
        $d5_end = $threep_oligo_region->end;
        $d3_start = $threep_oligo_region->end - ( 2 * $OLIGO_SIZE ) + 1;
        $d3_end = $threep_oligo_region->end - $OLIGO_SIZE;
    }

    return ( $d5_start, $d5_end, $d3_start, $d3_end );
}



__PACKAGE__->meta->make_immutable;

1;

__END__
