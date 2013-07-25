package HTGT::Utils::DesignFinder::CriticalRegionError;

use Moose;
use namespace::autoclean;
use Moose::Util::TypeConstraints;
use Const::Fast;

extends 'Throwable::Error';

const my %MESSAGE_FOR => (
    MaxRegionSizeExceeded           => "Region size greater than max permitted region size",
    NoFloxedExons                   => "Region contains no exons",
    NoCodingExons                   => "Region contains no coding exons",
    SymmetricalExons                => "Start/end exons are symmetrical",
    No5pFlankingIntron              => "No flanking 5' intron",
    Small5pFlankingIntron           => "Flanking 5' intron too small for insertion",
    Small3pFlankingIntron           => "Flanking 3' intron too small for insertion",
    OverlappingCodingTranscript     => "Region has overlapping coding transcript",
    OverlappingTranscriptSameStrand => "Region has overlapping transcript in same strand",
    OverlappingExon                 => "Region has overlapping exon whose splicing may be affetced by mutation",
    GenesIn3pFlankSameStrand        => "Genes found in 3' flank (same strand)",
    GenesIn3pFlankOppositeStrand    => "Genes found in 3' flank (opposite strand)",
    GenesIn5pFlankSameStrand        => "Genes found in 5' flank (same strand)",
    GenesIn5pFlankOppositeStrand    => "Genes found in 5' flank (opposite strand)",
    Reinitiation                    => "Reinitiation after deletion likely",
    TooMuchProteinProduced          => "Too much of the original protein is produced after deletion",
    ConstrainedElements             => "Constrained elements prevent computation of candidate oligo region",
    StartInCodingRegion             => "Region start is in coding region of some transcript",
    EndInCodingRegion               => "Region end is in coding region of some transcript",
    UnableToRetrieveSlice           => "Unable to retrieve slice. Is gene on a chromosome?",
);    

enum 'HTGT::Utils::DesignFinder::CriticalRegionErrorType' => [ keys %MESSAGE_FOR ];

has type => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::CriticalRegionErrorType',
    required => 1
);

has '+message' => (
    lazy    => 1,
    builder => '_build_message'
);

has transcript => (
    is   => 'ro',
    isa  => 'Bio::EnsEMBL::Transcript'
);

sub _build_message {
    my $self = shift;

    my $msg = $MESSAGE_FOR{ $self->type };
    if ( $self->transcript ) {
        $msg .= " (transcript " . $self->transcript->stable_id . ")";
    }

    return $msg;
}

1;

__END__
