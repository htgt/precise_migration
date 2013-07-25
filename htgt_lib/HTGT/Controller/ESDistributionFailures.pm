package HTGT::Controller::ESDistributionFailures;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::MutagenesisPredictions - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 view

=cut

sub view :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( template => 'esdistributionfailures/view.tt' );
}



=head1 AUTHOR

Mark Quinton-Tulloch

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

