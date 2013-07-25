package HTGT::Utils::DesignFinder::PartExon;

use Moose;
use namespace::autoclean;
use HTGT::Utils::EnsEMBL;
use Bio::Seq;

has id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
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

has seq => (
    is         => 'ro',
    isa        => 'Bio::PrimarySeq',
    init_arg   => undef,
    lazy_build => 1,
);

has length => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1,
);

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

sub _build_length{
    my $self = shift;

    return $self->end - $self->start + 1;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
