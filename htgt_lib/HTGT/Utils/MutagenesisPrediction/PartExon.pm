package HTGT::Utils::MutagenesisPrediction::PartExon;

use Moose;
use namespace::autoclean;
use Bio::Seq;
use Smart::Comments;

has stable_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has [qw( start end )] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has gene => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Gene',
    required => 1,
    handles  => [qw( chromosome strand )],
);

has full_exon => (
    is       => 'ro',
    isa      => 'Bio::EnsEMBL::Exon',
    required => 1,
);

has transcript => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Transcript',
    required => 1,
);

has length => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1,
);

has other_part_length => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

has seq => (
    is         => 'ro',
    isa        => 'Bio::PrimarySeq',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_stable_id{
    my $self = shift;

    return $self->full_exon->stable_id;
}

sub _build_length{
    my ( $self ) = @_;

    return $self->end - $self->start + 1;
}

sub _build_other_part_length{
    my ( $self ) = @_;

    return $self->full_exon->length - $self->length;
}

sub _build_seq{
    my $self = shift;
    my $exon_part_slice = HTGT::Utils::EnsEMBL->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chromosome,
        $self->start,
        $self->end,
        $self->strand
    );

    return Bio::PrimarySeq->new(
        -seq      => $exon_part_slice->seq,
        -alphabet => 'dna',
    );
}

sub coding_region_start{
    my ( $self, $transcript ) = @_;

    my $full_exon_coding_start = $self->full_exon->coding_region_start( $self->transcript );

    return unless defined $full_exon_coding_start;

    if ( $full_exon_coding_start > $self->start ){
        if ( $full_exon_coding_start > $self->end ){
            return;
        }
        return $full_exon_coding_start;
    }
    else{
        return $self->start;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
