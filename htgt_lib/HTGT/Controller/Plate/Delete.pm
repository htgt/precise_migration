package HTGT::Controller::Plate::Delete;

# $Id: Delete.pm,v 1.4 2009-09-08 11:55:53 rm7 Exp $

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

use HTGT::Utils::Plate::Delete;

sub go_to_plate_view {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->param( 'plate_id' ) } ) );
}

sub go_to_plate_list {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/list' ) );
}

sub delete_plate : Local {
    my ( $self, $c ) = @_;

    my $plate_id = $c->req->param( 'plate_id' );
    unless ( $plate_id and $plate_id =~ /^\d+$/ ) {
        $c->flash->{ error_msg } = 'Missing or invalid plate id';
        return $self->go_to_plate_list( $c );
    }
    
    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{ error_msg } = "You are not authorized to delete plates";
        return $self->go_to_plate_view( $c );
    }

    my $plate_name = eval {
        my $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $plate_id } )
            or die "No such plate: $plate_id\n";
        $c->audit_info( "Deleting plate $plate" );
        $c->model( 'HTGTDB' )->schema->txn_do( sub { HTGT::Utils::Plate::Delete::delete_plate( $plate, $c->user->id ) } );
    };
    if ( my $err = $@ ) {
        chomp( $err );
        $err =~ s/^\QDBIx::Class::Schema::txn_do(): \E//;
        $c->log->error( "Delete plate $plate_id failed: $err" );
        $c->flash->{ error_msg } = $err;
        return $self->go_to_plate_view( $c );
    }

    $c->audit_info( "Delete plate $plate_name COMMITTED" );
    $c->flash->{status_msg} = "Deleted plate $plate_name";
    $self->go_to_plate_list( $c );
}

1;

__END__
