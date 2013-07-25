package HTGT::Controller::QC::ListJobs;

use Moose;
use namespace::autoclean;
use HTGT::Utils::SubmitQC 'list_qc_jobs';

BEGIN {
    extends 'Catalyst::Controller';
}

=head1 NAME

HTGT::Controller::QC::ListJobs - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless( $c->check_user_roles('edit') ){
	$c->stash->{error_msg} = "You are not authorized to use this function!";
	$c->detach( 'Root', 'welcome' );
    }
    
    $c->stash->{submited_qc_jobs} = list_qc_jobs();    
}


=head1 AUTHOR

Wanjuan Yang

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
