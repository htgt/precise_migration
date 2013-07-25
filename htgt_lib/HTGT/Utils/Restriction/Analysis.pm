package HTGT::Utils::Restriction::Analysis;

use Moose;
use HTGT::Utils::Restriction::EnzymeCollection;
use Bio::Restriction::Analysis;
use namespace::autoclean;

has seq => (
    is       => 'ro',
    isa      => 'Bio::SeqI',
    required => 1
);

has enzymes => (
    is      => 'ro',
    isa     => 'Bio::Restriction::EnzymeCollection',
    default => sub { HTGT::Utils::Restriction::EnzymeCollection->instance->enzymes }
);

has ra => (
    isa        => 'Bio::Restriction::Analysis',
    init_arg   => undef,
    lazy_build => 1,
    handles    => [
        qw( cut multiple_digest positions fragments fragment_maps sizes
            cuts_by_enzyme cutters unique_cutters zero_cutters max_cuts )
    ]
);

sub _build_ra {
    my $self = shift;

    Bio::Restriction::Analysis->new(
        -seq     => $self->seq,
        -enzymes => $self->enzymes
    );    
}

around BUILDARGS => sub {    
    my $orig = shift;
    my $class = shift;
    
    if ( @_ == 1 && ref $_[0] ne 'HASH' ) {
        return $class->$orig( seq => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }
};

__PACKAGE__->meta->make_immutable;

1;

__END__
