package HTGT::Controller::Tools::FPData;
use Moose;
use namespace::autoclean;
use HTGT::Utils::FPData qw ( get_fp_data );
use JSON qw( to_json );
use Try::Tiny;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::FPData - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Given a mgi_accession_id, retrieve EPD well data and data for child LOA and FP wells

=cut

sub index :Path :Args(1) {
    my ( $self, $c, $mgi_accession_id ) = @_;

    if ( $mgi_accession_id !~ /^MGI:\d+$/ ) {
        $c->detach( 'error', [ "Invalid MGI accession ID: '$mgi_accession_id'" ] );
    }

    try {
        my $fp_data = $c->model( 'HTGTDB' )->storage->dbh_do( sub { get_fp_data( $_[1], $mgi_accession_id ) } );
        $c->response->content_type( 'application/json' );
        $c->response->body( to_json( $fp_data ) );
    }
    catch {
        $c->log->error( "get_fp_data $mgi_accession_id failed: $_" );
        $c->detach( 'error', [ "Failed to retrieve FP plate data for $mgi_accession_id" ] );
    }        
}

sub error :Private {
    my ( $self, $c, $mesg ) = @_;

    $c->log->error( $mesg );
    $c->response->content_type( 'application/json' );
    $c->response->body( to_json( { error => $mesg } ) );
    $c->response->status( 400 );
}

=head1 AUTHOR

Mark Quinton-Tulloch

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

