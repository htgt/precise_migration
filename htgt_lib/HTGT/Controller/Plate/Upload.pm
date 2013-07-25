package HTGT::Controller::Plate::Upload;
use Moose;
use namespace::autoclean;
use Readonly;
use Text::CSV_XS;
use HTGT::Utils::Plate::Create 'create_plate';

BEGIN {extends 'Catalyst::Controller'; }

use HTGT::Constants qw( %PLATE_TYPES );

=head1 NAME

HTGT::Controller::Plate::Upload - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles( 'edit' ) ) {
        $c->stash->{ error_msg } = "You are not authorised to create a plate";
        $c->detach( 'Root', 'welcome' );
    }

    $c->stash->{plate_types} = [ '-', grep{ $_ ne 'DESIGN' && $_ ne 'PG' && $_ ne 'PC' } sort keys %PLATE_TYPES ];
    
    return unless $c->req->param( 'create_plate' );

    my $plate_name  = $c->req->param( 'plate_name' ) || '';
    my $plate_type  = $c->req->param( 'plate_type' ) || '-';
    my $skip_header = $c->req->param( 'skip_header' );

    # Re-populate form fields in case we return an error
    $c->stash->{plate_name}  = $plate_name;
    $c->stash->{plate_type}  = $plate_type;
    $c->stash->{skip_header} = $skip_header;    
    
    unless ( $plate_type and $PLATE_TYPES{ $plate_type } ) {
        $c->stash->{error_msg} = 'Missing or invalid plate type';
        return;
    }

    # note:
    # if you are getting a plate with blank well data then it probably means the user
    # has uploaded a file with a trailing comma, which causes parse_plate_well to
    # break. Remove the commas and everything will be fine.
    my $data = eval { $self->parse_uploaded_data( $c, $plate_name, $skip_header ) };
    if ( $@ ) {
        $c->stash->{error_msg} = $@;
        return;
    }

    unless ( keys %{ $data } ) {
        $c->stash->{error_msg} = "No plates were specified for creation";
        return;
    }
    
    my @created;
    
    eval {
        $c->model( 'HTGTDB' )->txn_do(
            sub {
                for my $plate_name ( keys %{ $data } ) {
                    create_plate(
                        $c->model( 'HTGTDB' )->schema,
                        plate_name => $plate_name,
                        plate_type => $PLATE_TYPES{ $plate_type },
                        plate_data => $data->{ $plate_name },
                        created_by => $c->user->id,
                    );
                    push @created, $plate_name;
                }
            }
        )
    };    
    if ( $@ ) {
        $@ =~ s/^.*\QDBIx::Class::Schema::txn_do():\E\s+//;
        $c->stash->{error_msg} = "No plates were created: $@";
        return;
    }

    delete $c->stash->{plate_name};
    delete $c->stash->{plate_type};
    $c->stash->{status_msg} = sprintf( "Created plate%s %s",
                                       @created > 1 ? 's' : '',
                                       join( q{, }, map $self->linkify_plate( $c, $_ ), @created ) );    
}

sub linkify_plate {
    my ( $self, $c, $plate_name ) = @_;
    my $plate_uri = $c->uri_for( '/plate/view', { plate_name => $plate_name } );
    return "<a href=\"$plate_uri\">$plate_name</a>";
}

sub parse_uploaded_data {
    my ( $self, $c, $plate_name, $skip_header ) = @_;

    my $upload = $c->req->upload( 'datafile' );
    die "Missing or invalid data file\n"
        unless $upload and $upload->size;

    my $csv = Text::CSV_XS->new;

    my $uploaded_data = $upload->slurp;
    my @lines = split /\r\n|\r|\n/, $uploaded_data;
    
    shift @lines if $skip_header;

    my %data;
    
    while ( my $line = shift @lines ) {
        $line =~ s/\s+$//; # kill trailing whitespace
        $csv->parse( $line )
            or die "Parse error, line $. of input: " . $csv->error_input . "\n";
        my @f = $csv->fields;
        # Handle upload of [ plate, well, parent_spec, ... ]
        if ( @f >= 3 ) {
            $plate_name = shift @f;
            shift @f; # discard well_name
        }
        push @{ $data{ $plate_name } }, \@f;
    }

    return \%data;        
}


=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
