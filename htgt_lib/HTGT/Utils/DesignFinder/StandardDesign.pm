package HTGT::Utils::DesignFinder::StandardDesign;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::DesignFinder::CandidateOligoRegion::Standard;
use HTGT::Utils::DesignFinder::Constants qw( $MIN_3P_INTRON_SIZE );
use Const::Fast;

extends 'HTGT::Utils::DesignFinder';

with 'MooseX::Log::Log4perl';

has '+design_type' => ( default => 'Standard' );

has '+minimum_3p_intron_size' => (
    default => $MIN_3P_INTRON_SIZE,
);

sub find_candidate_critical_regions {
    my ($self) = @_;

    $self->log->info(
        "Template transcript: " . $self->gene->template_transcript->stable_id );

    my @candidate_ce_starts;

    for my $start_ce_ix ( 1 .. $self->gene->last_candidate_start_ce_index ) {
        my $candidate_ce_start;
        if ( $self->gene->strand == 1 ){
            $candidate_ce_start =
                $self->gene->get_template_exon($start_ce_ix)->start;
        }
        else{
            $candidate_ce_start = $self->gene->get_template_exon($start_ce_ix)->end;
        }
        $self->create_candidate_critical_regions($candidate_ce_start);
    }

    my @valid_critical_regions = grep $_->is_valid,
      $self->candidate_critical_regions;

    for my $r (@valid_critical_regions) {
        $self->log->info( $r . " ("
              . $r->floxed_exons_as_str( $self->gene->template_transcript )
              . ") form a critical region" );
        $self->get_oligo_region($r, 'Standard');
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
