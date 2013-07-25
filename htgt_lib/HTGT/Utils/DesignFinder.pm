package HTGT::Utils::DesignFinder;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::DesignFinder::CandidateCriticalRegion;
use HTGT::Utils::DesignFinder::CandidateOligoRegion::Standard;
use HTGT::Utils::DesignFinder::CandidateOligoRegion::FalseIntron;
use HTGT::Utils::DesignFinder::Helpers qw( exon_3p_utr_length );
use Const::Fast;

with 'MooseX::Log::Log4perl';

has gene => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Gene',
    required => 1,
);

has minimum_3p_intron_size => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => undef,
);

for (qw( error warning )) {
    has "_${_}s" => (
        isa      => 'ArrayRef[Str]',
        init_arg => undef,
        traits   => ['Array'],
        handles  => {
            "${_}s"     => 'elements',
            "add_${_}"  => 'push',
            "has_${_}s" => 'count',
        },
        default => sub { [] },
    );
}

has _candidate_critical_regions => (
    isa      => 'ArrayRef[HTGT::Utils::DesignFinder::CandidateCriticalRegion]',
    init_arg => undef,
    traits   => ['Array'],
    handles  => {
        candidate_critical_regions    => 'elements',
        add_candidate_critical_region => 'push',
    },
    default => sub { [] },
);

has _candidate_oligo_regions => (
    isa      => 'ArrayRef[HTGT::Utils::DesignFinder::CandidateOligoRegion]',
    init_arg => undef,
    traits   => ['Array'],
    handles  => {
        candidate_oligo_regions     => 'elements',
        add_candidate_oligo_region  => 'push',
        has_candidate_oligo_regions => 'count',
    },
    default => sub { [] },
);

has design_type => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
);

sub add_critical_region_error {
    my ( $self, $cr, $message ) = @_;

    $self->add_error(
        sprintf( '%s [%s]: %s',
            $cr,
            $cr->floxed_exons_as_str( $self->gene->template_transcript ),
            $message || $cr->error->message )
    );
    return;
}

sub create_candidate_critical_regions {
    my ( $self, $candidate_ce_start ) = @_;
    for my $candidate_end_ce_ix ( 0 .. ( $self->gene->num_template_exons - 1 ) )
    {
        my @cr =
          $self->get_candidate_critical_regions( $candidate_ce_start,
            $self->gene->get_template_exon($candidate_end_ce_ix) );

        for my $cr (@cr) {
            $self->log->debug( 'Considering candidate critical region ' . $cr );
            $cr->check_size or next;
            $self->add_candidate_critical_region($cr);
            $cr->validate( $self->gene->complete_transcripts );
            unless ( $cr->is_valid ) {
                $self->log->debug(
                    'Rejecting region ' . $cr . ': ' . $cr->error->message );
            }
        }
    }
    return;
}

sub get_candidate_critical_regions {
    my ( $self, $start_point, $last_ce ) = @_;

    my ( $start, $end );
    if ( $self->gene->strand == 1 ) {
        $start = $start_point;
        $end   = $last_ce->end;
    }
    else {
        $start = $last_ce->start;
        $end   = $start_point;
    }

    if ( $start > $end ) {
        return;
    }

    my @candidate_regions;
    my $candidate_region;
    my $insert_in_3p_intergenomic = 0;
    if ( $self->is_last_exon($last_ce) ) {
        $candidate_region =
          $self->get_cr_with_utr_insertion( $last_ce, $start, $end );
        if ($candidate_region) {
            push( @candidate_regions, $candidate_region );
        }
        $insert_in_3p_intergenomic = 1;
    }

    $candidate_region =
      HTGT::Utils::DesignFinder::CandidateCriticalRegion->new(
        gene                      => $self->gene,
        design_type               => $self->design_type,
        minimum_3p_intron_size    => $self->minimum_3p_intron_size,
        start                     => $start,
        end                       => $end,
        insert_in_3p_utr          => 0,
        insert_in_3p_intergenomic => $insert_in_3p_intergenomic
      );
    push( @candidate_regions, $candidate_region );

    for my $cr (@candidate_regions) {
        $self->floxed_exon_sanity_check( $cr,
            $self->gene->template_transcript );
    }

    return @candidate_regions;
}

sub get_cr_with_utr_insertion {
    my ( $self, $last_ce, $start, $end ) = @_;

    my $utr = exon_3p_utr_length( $last_ce, $self->gene->template_transcript );
    $utr--; # Ensures critical region still overlaps last exon (albeit just 1bp)
            # when last exon is entirely UTR
    if ( $utr < $self->minimum_3p_intron_size ) {
        return;
    }

    if ( $self->gene->strand == 1 ) {
        $end -= $utr;
    }
    else {
        $start += $utr;
    }

    return HTGT::Utils::DesignFinder::CandidateCriticalRegion->new(
        gene                      => $self->gene,
        design_type               => $self->design_type,
        minimum_3p_intron_size    => $self->minimum_3p_intron_size,
        start                     => $start,
        end                       => $end,
        insert_in_3p_utr          => 1,
        insert_in_3p_intergenomic => 0
    );
}

sub floxed_exon_sanity_check {
    my ( $self, $cr, $transcript ) = @_;

    my $floxed_exons = $cr->floxed_exons($transcript);
    my ( $cr_pos_first_fe, $cr_pos_last_fe );
    if ( $cr->gene->strand == 1 ) {
        $cr_pos_first_fe = $cr->start;
        $cr_pos_last_fe  = $cr->end;
    }
    else {
        $cr_pos_first_fe = $cr->end;
        $cr_pos_last_fe  = $cr->start;
    }
    unless ($floxed_exons->[0]->start <= $cr_pos_first_fe
        and $cr_pos_first_fe <= $floxed_exons->[0]->end )
    {
        confess "first floxed exon mismatch";
    }
    unless ($floxed_exons->[-1]->start <= $cr_pos_last_fe
        and $cr_pos_last_fe <= $floxed_exons->[-1]->end )
    {
        confess "last floxed exon mismatch";
    }
}

sub transcript_coding_length {
    my ($self) = @_;

    my $tt = $self->gene->template_transcript;
    return $tt->cdna_coding_end - $tt->cdna_coding_start + 1;
}

sub is_last_exon {
    my ( $self, $last_ce ) = @_;
    if ( $self->gene->get_template_exon(-1)->stable_id eq $last_ce->stable_id )
    {
        return 1;
    }
    return;
}

sub transform_to_genomic {

    my ( $self, $exon, $pos ) = @_;
    $self->log->debug( "Exon start: " . $exon->start . "Pos: $pos" );
    if ( $exon->strand == 1 ) {
        return $exon->start + $pos - 1;
    }
    else {
        return $exon->end - $pos + 1;
    }
}

sub get_oligo_region {
    my ( $self, $region, $gene_type ) = @_;
    my $oligo_region;
    my $cassette_insertion_point;
    if ( $self->gene->strand == 1 ) {
        $cassette_insertion_point = $region->start;
    }
    else {
        $cassette_insertion_point = $region->end;
    }
    if ( $gene_type eq 'Standard' ){
        $oligo_region =
            HTGT::Utils::DesignFinder::CandidateOligoRegion::Standard->new(
                gene            => $self->gene,
                critical_region => $region
            );
    }
    else{
        $oligo_region =
            HTGT::Utils::DesignFinder::CandidateOligoRegion::FalseIntron->new(
                gene                     => $self->gene,
                critical_region          => $region,
                cassette_insertion_point => $cassette_insertion_point,
            );
    }

    if ( $oligo_region->is_valid ) {
        $self->add_candidate_oligo_region($oligo_region);
        $self->log->debug("valid oligo regions computed");
    }
    else {
        $self->log->debug("failed to compute candidate oligo regions");
        $region->add_error('ConstrainedElements');
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
