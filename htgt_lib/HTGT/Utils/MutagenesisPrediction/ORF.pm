package HTGT::Utils::MutagenesisPrediction::ORF;

use Moose;
use namespace::autoclean;

has [ qw( cdna_coding_start cdna_coding_end ) ] => (
    is       => 'ro',
    isa      => 'Int',
    required => 1
);

has translation => (
    is       => 'ro',
    isa      => 'Bio::SeqI',
    required => 1
);

__PACKAGE__->meta->make_immutable;

1;

__END__
