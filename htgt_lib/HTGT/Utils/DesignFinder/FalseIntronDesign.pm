package HTGT::Utils::DesignFinder::FalseIntronDesign;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::DesignFinder::CandidateOligoRegion::FalseIntron;
use HTGT::Utils::DesignFinder::Constants qw(
    $INSERT_SITE_RX
    $MIN_START_CASS_DIST
    $MIN_3P_INTRON_SIZE
);

use POSIX qw( floor );

extends 'HTGT::Utils::DesignFinder';

with 'MooseX::Log::Log4perl';

has '+minimum_3p_intron_size' => (
    default => 340,
);

sub find_candidate_critical_regions {
    my ($self) = @_;

    $self->log->info(
        "Template transcript: " . $self->gene->template_transcript->stable_id );

    my @candidate_ce_starts = $self->find_cassette_insertion_points;

    unless (@candidate_ce_starts) {
        $self->add_error('No cassette insertion points found');
        return;
    }

    for my $candidate_ce_start (@candidate_ce_starts) {
        $self->create_candidate_critical_regions($candidate_ce_start);
    }

    my @valid_critical_regions = grep $_->is_valid,
      $self->candidate_critical_regions;
    for my $r (@valid_critical_regions) {
        $self->log->info( $r . " ("
              . $r->floxed_exons_as_str( $self->gene->template_transcript )
              . ") form a critical region" );
        $self->get_oligo_region($r, 'FalseIntron');
    }
    unless( grep $_->is_valid, $self->candidate_critical_regions ){
        $self->add_error( "No valid critical regions" );
        for my $cr( $self->candidate_critical_regions ){
            $self->add_critical_region_error( $cr );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
