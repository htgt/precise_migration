package HTGT::Controller::QC::Submit;

use Moose;
use namespace::autoclean;
use List::MoreUtils qw( firstval uniq );
use HTGT::Utils::SubmitQC 'submit_qc_job';
use Exception::Class;
use JSON 'to_json';
use Try::Tiny;
use HTGT::Utils::ResetPlateParentageAndQC qw(reset_plate_parentage_and_qc validate_384_plate_for_well_parentage_reset);
use Smart::Comments;

BEGIN {
    extends 'Catalyst::Controller';
}

=head1 NAME

HTGT::Controller::QC::Submit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

Display the QC submission form.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles( 'edit' ) ) {
        $c->stash->{error_msg} = "You are not authorised to use this function";
        $c->detach( 'Root', 'welcome' );
    }

    $c->stash->{template} = 'qc/submit/index';
}

=head2 submit_form

Handle submission of QC jobs in form fields

=cut

sub submit_form :Local {
    my ( $self, $c ) = @_;

    #my $check_qc_run = 0; # Assume Javascript has dealt with this check
    my $ignore_previous_qc_results = 1 if $c->req->param( 'ignore_previous_qc_run_form' );
    
    $self->submit_qc( $c, 'parse_form_data', $ignore_previous_qc_results );
}

=head2 submit_file

Handle submission of QC jobs in file upload

=cut    

sub submit_file :Local {
    my ( $self, $c ) = @_;

    my $ignore_previous_qc_results = 1 if $c->req->param( 'ignore_previous_qc_run_file' );
    
    $self->submit_qc( $c, 'parse_file_data', $ignore_previous_qc_results );
}

=head2 submit_qc

Private method that handles the actual submission of the QC data

=cut

sub submit_qc :Private {
    my ( $self, $c, $parse, $ignore_previous_qc_results ) = @_;
    my $htgtdb_schema = $c->model('HTGTDB')->schema;
    unless ( $c->check_user_roles( 'edit' ) ) {
        $c->stash->{error_msg} = "You are not authorised to use this function";
        $c->detach( 'Root', 'welcome' );
    }

    my ( $data, $apply_cre, $force_rerun ) = $self->$parse( $c );
    my ( $todo, $errors ) = $self->validate_data( $c, $data, $ignore_previous_qc_results, $force_rerun );

    $self->error( $c, join '<br />', "Errors in form submission; QC job NOT submitted:", @{ $errors } )
        if @{ $errors };

    $self->error( $c, 'No jobs found in form upload' )
        unless @{ $todo };
    
    my $submitter = $c->user->id;
    my $options = {};
    $options->{apply_cre}   = 1 if $apply_cre;
    $options->{force_rerun} = 1 if $force_rerun;
    $c->log->info( "Applying cre to qc" ) if $apply_cre;
    $c->log->info( "Force Rerun qc" )     if $force_rerun;

    $htgtdb_schema->txn_do(
        sub {
            eval {
                for my $job ( @{ $todo } ) {
                    $c->log->info( "Running QC $job->{plate} against $job->{tsproj}" );
                    
                    if ( $job->{reset_qc} ) {
                       $c->log->info( "Resetting plate parentage and qc data for $job->{plate}" );
                       reset_plate_parentage_and_qc($job->{plate}, $job->{parent_plate}, $c->model('HTGTDB')->schema);
                    }
                    submit_qc_job( $job->{tsproj}, $job->{plate}, $submitter, $options );
                }
            };

            my $e;
            if ( $e = Exception::Class->caught( 'HTGT::Utils::SubmitQC::Exception' ) ) {
                $self->error( $c, "QC job submission failed: " . $e->message );
                $htgtdb_schema->txn_rollback;
            }
            elsif ( $e = Exception::Class->caught() ) {
                $self->error( $c, "QC job submission failed: $e" );
                $htgtdb_schema->txn_rollback;
            }
        }
    );

    $self->success( $c, "QC job submitted" );
}

=head2 parse_file_data

Private method to parse QC jobs from an uploaded file; return a reference to a list of pairs,
C<[ ts_proj, htgt_plate ]> on success. Set error_msg and detach to the index if there is
no uploaded file or we are unable to parse the file.

=cut
    
sub parse_file_data : Private {
    my ( $self, $c ) = @_;
    
    my $upload = $c->req->upload( 'datafile' );
    unless ( $upload and $upload->size ) {
        $self->error( $c, "No data file uploaded" );
    }
    
    my @data;

    my $uploaded_data = $upload->slurp;
    my @lines = split /\r\n|\r|\n/, $uploaded_data ;

    for ( @lines ) {
        s/^\s+//g;
        s/\s+$//g;
        my ( $tsproj, $htgt_plate ) = $_ =~ /^(\w+)\W+(\w+)$/
            or $self->error( $c, "Unable to parse input line: $_" );
        push @data, [ $tsproj, $htgt_plate ];
    }
    my $apply_cre   = $c->req->param( 'apply_cre_file' )   ? 1 : 0;
    my $force_rerun = $c->req->param( 'force_rerun_file' ) ? 1 : 0;
    return ( \@data, $apply_cre, $force_rerun );
}

=head2 parse_form_data
    
Private method to parse QC jobs from form data; return a reference to a list of pairs,
C<[ ts_proj, htgt_plate ]> on success.

=cut

sub parse_form_data :Private {
    my ( $self, $c ) = @_;

    my (@data, %projects, %plates);
    
    for my $row ( 1..10 ) {
        my $tsproj     = $c->req->param( 'project' . $row );
        my $htgt_plate = $c->req->param( 'plate' . $row );
        
        next unless $tsproj or $htgt_plate;
        $plates{$row}   = $htgt_plate;
        $projects{$row} = $tsproj;
        push @data, [ $tsproj, $htgt_plate ];        
    }
    my $apply_cre   = $c->req->param( 'apply_cre_form' )   ? 1 : 0;
    my $force_rerun = $c->req->param( 'force_rerun_form' ) ? 1 : 0;
    
    $c->stash->{plates}    = \%plates;
    $c->stash->{projects}  = \%projects;
    
    return ( \@data, $apply_cre, $force_rerun );
}

=head2 error

Signal an error by populating error_msg in the stash and detaching to the index page

=cut

sub error {
    my ( $self, $c, $error_msg ) = @_;

    $c->log->error( $error_msg );
    $c->stash->{error_msg} = $error_msg;
    $c->detach( 'index' );    
}

=head2 success

Signal success by populating status_msg in the stash and detaching to the index page.
Delete plates and projects from the stash to ensure we present the user with an empty
form on success.

=cut

sub success {
    my ( $self, $c, $success_msg ) = @_;

    $c->log->info( $success_msg );

    delete $c->stash->{plates};
    delete $c->stash->{projects};    
    $c->stash->{status_msg} = $success_msg;
    $c->detach( 'index' );
}

=head2 validate_data

Private method to validate uploaded data. Return a three-element list;
the first element is a list of QC jobs to be run, the second a list of
errors, and the third a list of warnings.

=cut    

sub validate_data :Private {
    my ( $self, $c, $input_data, $ignore_previous_qc_results, $force_rerun ) = @_;

    my ( @todo, @errors );    

    for my $datum ( @{ $input_data } ){
        my ( $tsproj, $plate_name ) = @{ $datum };
        
        if ( $plate_name and not $tsproj ) {
            push @errors, "No sequencing project given for plate $plate_name";
            next;
        }

        if ( $tsproj and not $plate_name ) {
            push @errors, "No plate given for sequencing project $tsproj";
            next;
        }
        
        my $plate = $c->model( 'HTGTDB::Plate' )->find( { name => $plate_name } );
        unless ( $plate ) {
            push @errors, "Invalid plate: $plate_name";
            next;
        }

        #We cant only check for existence of a project - online path is not going to be set any more
        unless ( $c->model( 'BadgerRepository' )->exists( $tsproj ) ) {
            push @errors, "Invalid sequencing project: $tsproj";
            next;
        }
        
        my $is_384 = $self->_is_384_well_plate( $c, $plate );
        my $parent_plate;
        
        if ( my $qc_run_data = $self->_has_qc_run( $c, $plate_name, $tsproj ) ) {
            unless ($ignore_previous_qc_results) {
                push @errors, "QC for $plate_name/$tsproj was run on $qc_run_data, need to select ignore previous qc results option if you want to rerun qc";
                next;
            }
                
            if ($is_384) {
                $parent_plate = $self->_384_plate_reparent_check( $c, $plate, \@errors, $force_rerun );
                next if @errors;
            }
        }

        my $job = { plate => $plate_name, tsproj => $tsproj, reset_qc => 0 };
        if ($parent_plate) {
            $job->{reset_qc}     = 1;
            $job->{parent_plate} = $parent_plate;
        }
        
        push @todo, $job;
    }

    return ( \@todo, \@errors );    
}

=head2 _384_plate_rerun_check

Return date of last qc run if any for a plate and trace project

=cut
sub _has_qc_run {
    my  ( $self, $c, $plate_name, $tsproj ) = @_;
    
    my @qc_runs = $c->model( 'ConstructQC' )->resultset( 'QctestRun' )->search(
        {
            design_plate => $plate_name, 
            clone_plate  => $tsproj
        },
        {
            order_by => { -desc => [ 'run_date' ] }
        }
    );
    
    if ( @qc_runs ) {
        my $latest_qc_run = shift @qc_runs;
        return $latest_qc_run->run_date;
    }

    return;
}


=head2 _384_plate_rerun_check

Return true if place it 384 well

=cut
sub _is_384_well_plate {
    my ( $self, $c, $plate ) = @_;
    
    my $is_384 = $plate->plate_data_value('is_384');
    
    if ( defined $is_384 and $is_384 eq 'yes' ) {
        return 1;
    }
    return;
}

=head2 _384_plate_rerun_check

Check if it it possible to rerun qc on this 384 well plate
If it is valid return the name of the parent plate we need to reset well parentage
before we can rerun qc on the 384 well plate

=cut
sub _384_plate_reparent_check {
    my ( $self, $c, $plate, $errors, $force_rerun ) = @_;

    #add check for force rerun option, if not set then error!
    unless ($force_rerun) {
        push @{$errors}, "To rerun qc for 384 well plate ($plate) you must check the force rerun option,"
                         . "WARNING this will reset the well parentage and qc data for all wells on this plate";
        return;
    }

    if ( my $parent_plate = validate_384_plate_for_well_parentage_reset( $plate, $errors, $c->model('HTGTDB')->schema ) ) {
        return $parent_plate;
    }

    return;
}



=head2 _suggest_trace_projects

Ajax autocompletion helper. Returns a list of matching trace projects in the Badger repository.

B<N.B. an empty list is returned unless the search string is more than 5 characters long>.

=cut
    
sub _suggest_trace_projects :Local {
    my ($self, $c) = @_;
    my ( $search_string ) = firstval {defined} map( $c->request->param("project$_") , 1 .. 10 );
    
    my $projects = [];
    if ( defined $search_string and length $search_string > 5 ) {
        $projects = $c->model('BadgerRepository')->search($search_string);
    }
    my $html_set = '<ul>' . join( '', map "<li>$_</li>", @{ $projects } ) . '</ul>';
    
    $c->res->body($html_set);
}

=head2 _suggest_plates

Ajax autocompletion helper. Returns a list of matching HTGT plates.

B<N.B. an empty list is returned unless the serach string is more than 4 characters long>.

=cut

sub _suggest_plates : Local {
    my ($self, $c) = @_;
    my ( $search_string ) = firstval {defined} map( $c->request->param("plate$_") , 1 .. 10 );
    
    my @plate_list;
    if ( defined $search_string and length $search_string > 4 ) {
        @plate_list = $c->model( 'HTGTDB::Plate' )->search(
            { name => { like => $search_string . '%' } },
            { order_by => { -asc => 'name' } }
        );
    }
    my $html_set = '<ul>'.join('', map { '<li>'.$_->name.'</li>'}  @plate_list ).'</ul>';
  
    $c->res->body($html_set);
}


=head1 AUTHOR

Ray Miller
Wendy Yang

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

