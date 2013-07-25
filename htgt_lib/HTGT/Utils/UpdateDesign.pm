package HTGT::Utils::UpdateDesign;

=head1 NAME

HTGT::Utils::UpdateDesign

=head1 DESCRIPTION

Update / fix a design that has been found to have a problem, by the design-check code.
This base class handles the common code needed to update a design.
The child classes deal with the specific issues that need to be fixed

=cut

use Moose;
use namespace::autoclean;

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has design => (
    is       => 'ro',
    isa      => 'HTGTDB::Design',
    required => 1
);

has human_annotation_notes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub{ [] },
    handles => {
        add_note    => 'push',
        note        => 'join',
        clear_notes => 'clear'
    }
);

__PACKAGE__->meta->make_immutable;

1;

__END__
