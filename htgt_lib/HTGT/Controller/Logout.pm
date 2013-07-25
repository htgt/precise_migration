package HTGT::Controller::Logout;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Logout - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    my $redirect_to_sanger_logout = $c->user_in_realm( 'ssso' ) || $c->user_in_realm( 'ssso_fallback' );
    
    $c->logout;

    if ( $redirect_to_sanger_logout ) {
        $c->response->redirect( 'http://www.sanger.ac.uk/logout' );
    }
    else {
        $c->response->redirect( $c->uri_for( '/welcome' ) );            
    }
}


=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

