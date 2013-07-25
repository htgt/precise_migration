package HTGT::Utils::DesignFinder::FalseIntronDesign::SmallIntronDesign;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::DesignFinder::CandidateOligoRegion::FalseIntron;
use HTGT::Utils::DesignFinder::Constants qw(
    $INSERT_SITE_RX
    $MIN_START_CASS_DIST
);
use POSIX qw( floor );

extends 'HTGT::Utils::DesignFinder::FalseIntronDesign';

with 'MooseX::Log::Log4perl';

has '+design_type' => ( default => 'SmallIntron' );

sub find_cassette_insertion_points{
    my ( $self ) = @_;
    
    my $template_transcript = $self->gene->template_transcript;
    my $tt_coding_length = $self->transcript_coding_length;
    
    my @candidate_cassette_insertion_points;
    my $coding_count = 0;
    for my $exon( @{ $template_transcript->get_all_Exons } ){
        next if $exon->length < 2 * $MIN_START_CASS_DIST;
        my $exon_seq = $exon->seq->seq;
        while( $exon_seq =~ m/$INSERT_SITE_RX/g ){
            my $pos = pos( $exon_seq );
            my $utr_length = 0;
            if ( $exon->coding_region_end( $template_transcript ) ){
                if ( $self->gene->strand == 1 ){
                    $utr_length = $exon->coding_region_start( $template_transcript ) - $exon->start;
                }
                else{
                    $utr_length = $exon->end - $exon->coding_region_end( $template_transcript );
                }
            }

            last if $pos > $exon->length - $MIN_START_CASS_DIST;
            last if $pos - $utr_length  + $coding_count >= $tt_coding_length / 2;
            $coding_count += $exon->length - $utr_length;
            next unless $pos >= $MIN_START_CASS_DIST;
            next if ( $pos >= $utr_length and $pos <= $utr_length + $MIN_START_CASS_DIST );
            push @candidate_cassette_insertion_points,
                $self->transform_to_genomic( $exon, $pos );
        }
    }
    return @candidate_cassette_insertion_points;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
