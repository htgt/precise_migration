package HTGT::Utils::DesignFinder::FalseIntronDesign::LargeFirstExonDesign;

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

has '+design_type' => ( default => 'LargeFirstExon' );

sub find_cassette_insertion_points {
    my ($self) = @_;

    my $template_transcript = $self->gene->template_transcript;
    my $tt_coding_length    = $self->transcript_coding_length;

    my $tt_first_exon;
    $tt_first_exon = $template_transcript->get_all_Exons->[0];

    my $min_insert = $MIN_START_CASS_DIST;
    my $max_insert =
      floor( $tt_first_exon->cdna_coding_start($template_transcript) +
          ( $tt_coding_length / 2 ) );
    return if $min_insert >= $max_insert;

    my $tt_first_exon_seq = $tt_first_exon->seq->seq;
    my @candidate_cassette_insertion_points;
    while ( $tt_first_exon_seq =~ m/$INSERT_SITE_RX/g ) {
        my $pos = pos($tt_first_exon_seq);
        last if $pos > $max_insert;
        next unless $pos >= $min_insert;
        next if ( $pos >= $tt_first_exon->cdna_coding_start( $template_transcript )
                      and $pos <= $tt_first_exon->cdna_coding_start( $template_transcript )
                          + $MIN_START_CASS_DIST );
        push @candidate_cassette_insertion_points,
          $self->transform_to_genomic( $tt_first_exon, $pos );
    }
    return @candidate_cassette_insertion_points;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
