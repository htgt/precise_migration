package HTGT::Controller::Gene::Redesign;
use Moose;
use Const::Fast;
use Try::Tiny;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Gene::Redesign - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 is_valid_pipeline


=head2 valid_pipelines


=cut

const my %IS_VALID_PIPELINE => map { $_ => 1 } qw( EUCOMM KOMP EUCOMM-Tools );

has _is_valid_pipeline => (
    traits  => [ 'Hash' ],
    handles => {
        is_valid_pipeline => 'exists',
        valid_pipelines   => 'keys'
    },
    default => sub { \%IS_VALID_PIPELINE }
);

=head2 auto

Users must have 'edit' role to access functions in this controller.

=cut

sub auto :Private {
    my ( $self, $c ) = @_;
    
    unless ( $c->check_user_roles( 'edit' ) ) {
        $c->flash->{error_msg} = 'You are not authorised to reset status for a gene to redesign requested';
        return $c->response->redirect( $c->uri_for( '/' ) );
    }    
}

=head2 reset_status_redesign_requested

=cut  
    
sub reset_status_redesign_requested :Local {
    my ( $self, $c ) = @_;

    my $project_id = $c->request->param( 'project_id' ) || '';
    unless ( $project_id =~ /^\d+$/ ) {
        return $self->error_redirect( $c, 'missing or invalid project id' );
    }

    my $project = $c->model( 'HTGTDB::Project' )->find( { project_id => $project_id } );
    unless ( $project ) {
        return $self->error_redirect( $c, "no such project $project_id" );
    }

    my $return_to = $c->uri_for( '/report/gene_report', { mgi_accession_id => $project->mgi_gene->mgi_accession_id } );    
    
    my $pipeline = $project->sponsor;
    $pipeline =~ s/:MGP//;

    unless ( $pipeline and $self->is_valid_pipeline( $pipeline ) ) {
        return $self->error_redirect( $c, 'only ' . join(', ', keys %IS_VALID_PIPELINE) . ' projects can be reset to redesign requested',
                                      $return_to );                                      
    }
    
    my $error;
    try {
        $c->model( 'HTGTDB' )->schema->txn_do(
            sub {    
                $c->audit_info( "Resetting " . $project->mgi_gene->marker_symbol . " $pipeline status to redesign requested" );
                $project->mgi_gene->reset_status_to_redesign_requested( $pipeline, $c->user->id );
            }
        );
    } catch {
        $c->audit_error( "Failed to reset $pipeline gene status to redesign requested: $_" );
        $error = "update failed";
    };

    if ( $error ) {
        return $self->error_redirect( $error, $return_to );
    }
   
    $c->flash->{status_msg} = "Reset $pipeline status for " . $project->mgi_gene->marker_symbol . " to 'redesign requested'";        
    return $c->response->redirect( $return_to );
}

sub error_redirect {
    my ( $self, $c, $mesg, $goto ) = @_;

    $goto ||= $c->uri_for( '/' );
    
    $c->flash->{error_msg} = "Failed to reset gene status to 'redesign requested': $mesg";
    $c->response->redirect( $goto );
}

=head2 bulk_reset_status_redesign_requested

=cut
    
sub bulk_reset_status_redesign_requested :Local {
    my ( $self, $c ) = @_;

    my $pipeline = $c->request->param( 'pipeline' ) || '';
    
    $c->stash->{pipelines} = { map { $_ => $pipeline eq $_ } $self->valid_pipelines };
    $c->stash->{markers} = $c->request->param( 'markers' ) || '';

    unless ( $c->request->param( 'reset_gene_status' ) ) {
        # The form has not been submitted        
        return;
    }

    unless ( $pipeline and $self->is_valid_pipeline( $pipeline ) ) {
        $c->stash->{error_msg} = "Please select a pipeline from the list below";
        return;
    }

    my @marker_symbols = ( $c->request->param( 'markers' ) || '' ) =~ m/[\w-]+/g;
    unless ( @marker_symbols ) {
        $c->stash->{error_msg} = "Please enter at least one marker symbol in the form below";
        return;
    }
    
    my ( $mgi_genes, $not_found ) = $self->get_mgi_genes( $c, \@marker_symbols );    
    unless ( @{$not_found} == 0 ) {
        $c->stash->{error_msg} = "The following genes were not found: " . join( q{, }, @{$not_found} ) . ". Please check your data and retry the update";
        return;
    }

    my $edit_user = $c->user->id;
    my $error;
    try {
        $c->model( 'HTGTDB' )->schema->txn_do(
            sub {
                for my $mgi_gene ( @{ $mgi_genes } ) {
                    $c->audit_info( "Resetting " . $mgi_gene->marker_symbol . " $pipeline status to redesign requested" );
                    $mgi_gene->reset_status_to_redesign_requested( $pipeline, $edit_user );
                }                    
            }
        );
    } catch {
        $c->audit_error( "Failed to reset $pipeline status to redesign requested: $_" );
        $error = "Failed to reset $pipeline status to redesign requested, update aborted";        
    };

    if ( $error ) {
        $c->stash->{error_msg} = $error;        
    }
    else {
        $c->stash->{status_msg} = "Reset $pipeline status to redesign requested for " . join( q{, }, @marker_symbols );        
        $c->stash->{pipelines} = { map { $_ => 0 } $self->valid_pipelines };        
        delete $c->stash->{markers};
    }
}

sub get_mgi_genes {
    my ( $self, $c, $marker_symbols ) = @_;

    my ( @mgi_genes, @not_found );

    for my $marker ( @{ $marker_symbols } ) {
        my $mgi_gene = $c->model( 'HTGTDB::MGIGene' )->find( { 'LOWER(me.marker_symbol)' => lc($marker) } );
        if ( $mgi_gene ) {
            push @mgi_genes, $mgi_gene;
        }
        else {
            push @not_found, $marker;            
        }
    }

    return ( \@mgi_genes, \@not_found );
}        

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

