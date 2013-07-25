package HTGT::Controller::Plate::Shipping;
use Moose;
use HTGT::Utils::Plate::ShippingDateParser;
use HTGT::Utils::Plate::LoadPlateData;
use DateTime::Format::DateParse;
use namespace::autoclean;
use Readonly; 

BEGIN {extends 'Catalyst::Controller'; }


Readonly my %SHIPPING_CENTERS => (
    csd   => 'CSD',                                                                                                
    hzm   => 'Helmholtz',
);
=head1 NAME

HTGT::Controller::Plate::Shipping - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->redirect('/plate/shipping/insert_plate_shipping_dates');
}

=head2 insert_plate_shipping_dates


=cut

sub insert_plate_shipping_dates : Local {
    my ( $self, $c ) = @_;
    my $htgtdb_schema = $c->model('HTGTDB')->schema;
    
    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} =
          "You are not authorised to insert plate shipping dates";
        $c->detach( 'Root', 'welcome' );
    }
    
    $c->stash->{shipping_centers} = [
        { name => '-', value => '-' },
        map { name => $SHIPPING_CENTERS{$_}, value => $_ }, sort keys %SHIPPING_CENTERS
    ];
    
    return unless $c->req->param( 'update_shipping' );
    
    my $plate_names     = $c->request->params->{shipping_plates};
    my $shipping_date   = $c->request->params->{shipping_date};
    my $shipping_center = $c->request->params->{shipping_center};

    $c->stash->{shipping_date}    = $shipping_date;
    $c->stash->{shipping_center}  = $shipping_center;
    $c->stash->{shipping_plates}  = $plate_names;
    
    unless ($shipping_center and exists $SHIPPING_CENTERS{$shipping_center} ) {
        $c->stash->{error_msg} =
          "No shipping center was selected";
          return;        
    }
    unless ($shipping_date) {
        $c->stash->{error_msg} =
          "No shipping date was entered";
          return;        
    }   
    unless ($plate_names ) {
        $c->stash->{error_msg} =
          "No plate names were entered";
          return;
    }
    
    my $parsed_shipping_date = DateTime::Format::DateParse->parse_datetime($shipping_date);
    unless ($parsed_shipping_date) {
         $c->stash->{error_msg} =
         "Invalid shipping date was entered ($shipping_date)";
         return;       
    }

    my $parser = HTGT::Utils::Plate::ShippingDateParser->new
        (
            schema          => $htgtdb_schema,
            shipping_center => $shipping_center,
            ship_date       => $parsed_shipping_date,
        );
    $parser->parse( $plate_names );

    if ( $parser->has_errors ) {
        $self->_create_error_message( $c, $parser->errors );
        return;
    }
 
    my $loader = HTGT::Utils::Plate::LoadPlateData->new
                 ( parser => $parser, user => $c->user->id );
    
    $htgtdb_schema->txn_do(
        sub {
            $loader->load_data();
            if ( $loader->has_errors ) {
                $htgtdb_schema->txn_rollback;
                $self->_create_error_message( $c, $loader->errors );
            }
            else {
                delete $c->stash->{shipping_date};
                delete $c->stash->{shipping_center};
                delete $c->stash->{shipping_plates};
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

    foreach my $line ( sort { $a <=> $b } keys %$errors ) {
        $error_message .= ( $line == 0 ? "" :  "<br>Line $line:<br>" )
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
        $update_message .= "<br>$plate_name<br>";
        foreach my $log ( @{ $update_log->{$plate_name} } ) {
            $update_message .= "$log";
        }
        $update_message .= "<br>";
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