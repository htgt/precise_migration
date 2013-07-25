package HTGT::Utils::Design::Validation::Error;

use Moose;
use namespace::autoclean;
use Const::Fast;
use Moose::Util::TypeConstraints;

enum 'HTGT::Utils::Design::Validation::ErrorType'
    => [ qw(
             missing_feature
             invalid_feature
             feature_order
             floxed_exon
             constrained_element
             repeat_region
     ) ];

const my %IS_FATAL => map { $_ => 1 } qw( missing_feature invalid_feature feature_order floxed_exon );

has is_fatal => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

has type => (
    is       => 'ro',
    isa      => 'HTGT::Utils::Design::Validation::ErrorType',
    required => 1,
);

has mesg => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub _build_is_fatal {
    my $self = shift;

    exists $IS_FATAL{ $self->type };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
