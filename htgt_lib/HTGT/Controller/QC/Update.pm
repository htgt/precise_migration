package HTGT::Controller::QC::Update;

use strict;
use warnings;
use base 'Catalyst::Controller';
use HTGT::Utils::UploadQCResults::PIQ;
use HTGT::Utils::UploadQCResults::Simple;
use HTGT::Utils::UploadQCResults::DnaPlates;
use Try::Tiny;
use HTGT::Constants qw( %QC_RESULT_TYPES );

use JSON;

=head1 NAME

HTGT::Controller::QC::Update - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

Perform authorisation - all QC access that involves a database edit requires the 'edit' privelege

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles(q(edit)) ) {
        $c->flash->{error_msg} = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }
    return 1;
}

=head2 index

Redirected to '/qc/qc_runs'

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/qc/qc_runs') );
}

=head2 _qctest_run_is_public_update

Method to be called via an Ajax request to update an entry in the 
ConstructQC::QctestRun table as public or not

=cut

sub _qctest_run_is_public_update : Local {
    my ( $self, $c ) = @_;
    
    $c->model('ConstructQC::QctestRun')
        ->find({ qctest_run_id => $c->req->params->{id} })
        ->update({ is_public => $c->req->params->{value} });
    
    if ($c->req->params->{value} eq '0') {
        $c->res->body( '<img src="/icons/silk/stop.png" alt="not public" />' );
    } else {
        $c->res->body( '<img src="/icons/silk/accept.png" alt="public" />' );
    }
}

=head2 save_chosen_constructs

Method to be called via the form submit on '/qc/construct_list'.  This updates the 
'chosen_status', 'result_comment', and 'is_chosen_for_engseq_in_run' values for a 
given QCtestResult entry...

=cut

sub save_chosen_constructs : Local {
    my ( $self, $c ) = @_;
    my $updated_results = jsonToObj( $c->req->params->{construct_data} );
    
    foreach my $result_info ( @{$updated_results} ) {
        
        my $qctest_result = $c->model('ConstructQC::QctestResult')->find(
            { qctest_result_id => $result_info->{id} }
        );
        
        if ( $result_info->{chosen} =~ /(\d+)(\w\d+)_(.*)/ ) {
            #From the string 1.plate 2.well 3.design_id
            my $chosen_di = $c->model('HTGTDB::DesignInstance')->find( { plate => $1, well=> $2 } );
            
            if ( ! defined $chosen_di ) {
                $c->flash->{error_msg} .= "Failed to find the chosen design instance '".$result_info->{chosen}."' on clone '".$result_info->{clone}."'";
                $c->response->redirect( $c->uri_for('/qc/construct_list') . '?qcrun_id=' . $c->req->params->{qctest_run_id} );
            } else {
                if ( $qctest_result->matchedSyntheticVector->design_instance_id != $chosen_di->design_instance_id ) {
                    $c->flash->{error_msg} .= "The chosen design on clone '".$result_info->{clone}."' did not match the observed design";
                    $c->response->redirect( $c->uri_for('/qc/construct_list') . '?qcrun_id=' . $c->req->params->{qctest_run_id} );
                } else {
                    $qctest_result->update(
                        {
                            is_chosen_for_engseq_in_run => $qctest_result->engineered_seq_id,
                            chosen_status               => $result_info->{chosen_status},
                            result_comment              => $result_info->{comment}
                        }
                    );
                }
            }
        } else {
            $qctest_result->update(
                { chosen_status => $result_info->{chosen_status}, result_comment => $result_info->{comment} }
            );
        }
    }
    
    $c->flash->{status_msg} = "Construct list updated";
    $c->response->redirect( $c->uri_for('/qc/construct_list') . '?qcrun_id=' . $c->req->params->{qctest_run_id} );
}

=head2 update_qc_results

Upload qc result data from LOA (REPD) plates into well_data

=cut

sub update_qc_results : Local {
    my ( $self, $c ) = @_;
    my @qc_types = keys %QC_RESULT_TYPES;
    $c->stash->{qc_types} = [ '-' , keys %QC_RESULT_TYPES ] ;
    return unless $c->req->param('update_qc');
    
    my $htgtdb_schema  = $c->model('HTGTDB')->schema;
    my $upload         = $c->req->upload('datafile');
    my $qc_result_type = $c->req->param('qc_type');
    my $skip_header    = $c->req->param('skip_header');

    $c->stash->{qc_type}     = $qc_result_type;
    $c->stash->{skip_header} = $skip_header; 

    unless ($qc_result_type and exists $QC_RESULT_TYPES{$qc_result_type} ) {
        $c->stash->{error_msg} = "Must specify a QC Type";
        return;        
    }

    unless ( $upload ) {
        $c->stash->{error_msg} = "Missing or invalid upload data file";
        return;
    }
    my $skip = $skip_header ? 1 : 0;

    $htgtdb_schema->txn_do(
        sub {
            try {
                my $QC_Updater;
                if ( $qc_result_type =~ /piq/i ) {
                    $QC_Updater = HTGT::Utils::UploadQCResults::PIQ->new(
                        schema         => $htgtdb_schema,
                        user           => $c->user->id,
                        input          => $upload->fh,
                    );
                }
                elsif ( $qc_result_type =~ /SBDNA|QPCRDNA/i ) {
                    $QC_Updater = HTGT::Utils::UploadQCResults::DnaPlates->new(
                        schema         => $htgtdb_schema,
                        user           => $c->user->id,
                        input          => $upload->fh,
                        dna_plate_type => $qc_result_type,
                    );
                }
                else {
                    $QC_Updater = HTGT::Utils::UploadQCResults::Simple->new(
                        schema         => $htgtdb_schema,
                        user           => $c->user->id,
                        input          => $upload->fh,
                        qc_result_type => $qc_result_type,
                        skip_header    => $skip,
                    );
                }
                
                $QC_Updater->parse_csv;
                $QC_Updater->update_qc_results;
                if ( $QC_Updater->has_errors ) {
                    $htgtdb_schema->txn_rollback;
                    $self->_create_error_message( $c, $QC_Updater->errors );
                }
                else {
                    delete $c->stash->{input_data};
                    $self->_create_update_message( $c, $QC_Updater->update_log );
                }
            }
            catch {
                $htgtdb_schema->txn_rollback;
                $c->stash->{error_msg} = "Error uploading qc results: $_";
            };
        }
    );
}

=head2 _create_error_message

Builds up and displays error messages gathered by GetDesignPrimers as it parses the input

=cut
sub _create_error_message {
    my ( $self, $c, $errors ) = @_;
    my $error_message;

    foreach my $error ( @{$errors} ) {
        $error_message .= $error . "<br>";
    }

    $c->stash->{error_msg} = $error_message;
    $error_message =~ s/<br>//g;
    $c->log->warn($error_message);

    return;
}

=head2 _create_update_message

Builds up and displays update messages create by UpdateLoxpPrimerResult module

=cut
sub _create_update_message {
    my ( $self, $c, $update_log ) = @_;
    my $update_message;

    unless ( scalar(@{ $update_log }) ){
        $c->stash->{status_msg} = 'Nothing to change';
        return;
    }

    foreach my $message ( @{ $update_log } ) {
        $update_message .= $message . "<br>";
    }
    
    $c->stash->{status_msg} = $update_message;
}

=head1 AUTHOR

Darren Oakley
Sajith Perera

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
