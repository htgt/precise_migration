package HTGT::Controller::Plate::Archive;
use Moose;
use namespace::autoclean;
use HTGT::Utils::Plate::ArchiveLabelParser;
use HTGT::Utils::Plate::LoadPlateData;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Plate::Archive - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect( '/plate/archive/load_archive_plate_labels' );
}

=head2 load_archive_plate_labels

Load archive plate data into plate_data table
There are 4 96 well plates stored in one larger archive plate
quadrant describes position of 96 well plate

=cut

sub load_archive_plate_labels  : Local :Args(0) {
    my ( $self, $c ) = @_;
    my $htgtdb_schema = $c->model('HTGTDB')->schema;

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} =
            "You are not authorised to load archive plate labels";
        $c->detach( 'Root', 'welcome' );
    }

    return unless $c->req->param('load_archives');
    
    my $plate_data = $c->request->params->{plate_data};
    
    unless ( defined $plate_data ) {
        $c->stash->{error_msg} =
          "No Data Entered";
          return;
    }
    $c->stash->{plate_data} = $plate_data;
    
    my $parser = HTGT::Utils::Plate::ArchiveLabelParser->new( schema => $htgtdb_schema );
    $parser->parse( $plate_data );

    if ( $parser->has_errors ) {
        $self->_create_error_message( $c, $parser->errors );
        return;
    }
    
    my $loader = HTGT::Utils::Plate::LoadPlateData->new( parser => $parser, user => $c->user->id );
    
    $htgtdb_schema->txn_do(
        sub {
            $loader->load_data();
            if ( $loader->has_errors ) {
                $htgtdb_schema->txn_rollback;
                $self->_create_error_message( $c, $loader->errors );
            }
            else {
                delete $c->stash->{plate_data};
                $self->_create_update_message( $c, $loader->update_log );
            }
        }
    );    
}

=head2 _create_error_message


=cut

sub _create_error_message {
    my ( $self, $c, $errors ) = @_;
    my $error_message;

    foreach my $line ( sort keys %$errors ) {
        $error_message .= ( $line == 0 ? "" : "<br>Line $line:<br>" )
            . join( '<br>', @{ $errors->{$line} } ) . "<br>";
    }

    $c->stash->{error_msg} = $error_message;
    $error_message =~ s/<br>//g;
    $c->log->warn($error_message);
}

=head2 _create_update_message


=cut

sub _create_update_message {
    my ( $self, $c, $update_log ) = @_;
    my $update_message;

    foreach my $plate_name ( sort keys %$update_log ) {
        $update_message .= "<br>$plate_name<br>| ";
        foreach my $log ( @{ $update_log->{$plate_name} } ) {
            $update_message .= $log . "  |  ";
        }
        $update_message .="<br>";
    }
    $c->stash->{status_msg} = $update_message;
    
}


=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

__END__
