package HTGT::Controller::Tools::MutagenesisPrediction;
use Moose;
use namespace::autoclean;
use HTGT::Utils::MutagenesisPrediction::Design;
use Try::Tiny;
use JSON qw( to_json from_json );

BEGIN {
    extends 'Catalyst::Controller';
}

=head1 NAME

HTGT::Controller::Tools::MutagenesisPrediction - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub project :PathPart( 'tools/mutagenesis_prediction/project' ) :Chained( '/' ) :CaptureArgs(1) {
    my ( $self, $c, $project_id ) = @_;

    my $project = $c->model( 'HTGTDB::Project' )->find( { project_id => $project_id }, { prefetch => 'design' } )
        or $c->detach( 'error', [ "missing or invalid project id" ] );

    try {
        $c->stash( prediction => HTGT::Utils::MutagenesisPrediction::Design->new( design => $project->design ) );
    }
    catch {
        $c->detach( 'error', [ $_ ] );        
    };

}

sub summary :PathPart( 'summary' ) :Chained( 'project' ) :Args(0) {
    my ( $self, $c ) = @_;

    try {
        my $summary = $c->stash->{prediction}->summary;
        $c->response->content_type( 'application/json' );        
        $c->response->body( to_json( $summary ) );
    }
    catch {
        $c->detach( 'error', [ $_ ] );
    };    
}

sub detail :PathPart( 'detail' ) :Chained( 'project' ) :Args(0) {
    my ( $self, $c ) = @_;

    try {
        my $detail = $c->stash->{prediction}->detail;
        $c->response->content_type( 'application/json' );        
        $c->response->body( to_json( $detail ) );
    }
    catch {
        $c->detach( 'error', [ $_ ] );
    };    
}

sub transcript :PathPart( 'transcript' ) :Chained( 'project' ) :Args {
    my ( $self, $c, $transcript_id ) = @_;

    try {
        $transcript_id ||= $c->stash->{prediction}->template_transcript->stable_id;
        my $detail = [ 'No analysis available (invalid or non-coding transcript?)' ];
        if ( my $prediction = $c->stash->{prediction}->prediction_for( $transcript_id ) ) {
            $detail = $prediction->to_hash;
        }
        $c->response->content_type( 'application/json' );
        $c->response->body( to_json( $detail ) );
    }
    catch {
        $c->detach( 'error', [ $_ ] );
    };
}

sub error :Private {
    my ( $self, $c, $mesg ) = @_;

    $c->log->error( $mesg );    
    $c->response->content_type( 'application/json' );    
    $c->response->body( to_json( { error => $mesg } ) );
    $c->response->status( 500 );
}

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

