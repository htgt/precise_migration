package HTGT::Controller::Plate::Rename;

# $Id: Rename.pm,v 1.2 2009-09-08 11:55:53 rm7 Exp $

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

sub go_to_plate_view {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/view', { plate_id => $c->req->param( 'plate_id' ) } ) );
}

sub go_to_plate_list {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/plate/list' ) );
}

sub rename_plate : Local {
    my ( $self, $c ) = @_;

    my $plate_id = $c->req->param( 'plate_id' );
    unless ( $plate_id and $plate_id =~ /^\d+$/ ) {
        $c->flash->{ error_msg } = 'Missing or invalid plate id';
        return $self->go_to_plate_list( $c );
    }
    
    my $new_plate_name = $c->req->param( 'new_plate_name' );
    unless ( $new_plate_name ) {
        $c->flash->{error_msg } = 'New plate name not specified';
        return $self->go_to_plate_view( $c );
    }
    
    # trim leading and trailing whitespace
    $new_plate_name =~ s/(^\s+|\s+$)//;
    
    unless ( $new_plate_name =~ /^\w+$/ ) {
        $c->flash->{error_msg} = "'$new_plate_name' is not a valid plate name";
        return $self->go_to_plate_view( $c );
    }
    
    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{ error_msg } = "You are not authorized to rename plates";
        return $self->go_to_plate_view( $c );
    }

    my $old_plate_name = eval {
        $c->model( 'HTGTDB' )->schema->txn_do( sub { $self->rename_plate_by_id( $c, $plate_id, $new_plate_name ) } );
    };
    if ( my $err = $@ ) {
        chomp( $err );
        $err =~ s/^\QDBIx::Class\E\S+:\s+//;
        $c->log->error( "Rename plate $plate_id failed: $err" );
        $c->flash->{ error_msg } = $err;
        return $self->go_to_plate_view( $c );
    }

    $c->audit_info( "Rename plate $old_plate_name to $new_plate_name COMMITTED" );
    $c->flash->{status_msg} = "Plate $old_plate_name renamed to $new_plate_name";
    $self->go_to_plate_view( $c );
}

sub rename_plate_by_id {
    my ( $self, $c, $plate_id, $new_plate_name ) = @_;
    
    $c->log->debug( "rename_plate_by_id: " . $plate_id );

    my $plate = $c->model( 'HTGTDB::Plate' )->find( { plate_id => $plate_id } )
        or die "Plate $plate_id not found\n";

    my $old_plate_name = $plate->name;

    {
        my ( $clone_name, $iter ) = $old_plate_name =~ /^(.+?)(?:_(\d+))?$/;
        $clone_name .= '_%';
        $clone_name .= "_$iter" if $iter; 
        my $clone_count = $c->model( 'HTGTDB::WellData' )->search(
            { 
                data_type  => 'clone_name',
                data_value => { like => $clone_name }
            }
        )->count;
        die "$clone_count clones named after this plate, cannot rename\n"
            if $clone_count > 0;
    }

    $c->audit_info( "Renaming plate $old_plate_name to $new_plate_name" );
    
    foreach my $well ( $plate->wells ) {
        ( my $new_well_name = $well->well_name ) =~ s/^\Q$old_plate_name\E/$new_plate_name/
            or next;
        $c->log->debug( "Renaming well " . $well->well_id . " from " . $well->well_name . " to $new_well_name" );
        $well->update( { well_name => $new_well_name,
                         edit_user => $c->user->id,
                         edit_date => \'current_timestamp',
                       } );
    }

    $c->log->debug( "Renaming plate $plate_id from $old_plate_name to $new_plate_name" );
    $plate->update( { name        => $new_plate_name, 
                      edited_user => $c->user->id,
                      edited_date => \'current_timestamp'
                    } );

    return $old_plate_name;
}

1;
