package HTGT::Controller::Gene::Update;

use strict;
use warnings;
use base 'Catalyst::Controller';

use HTGT::Controller::Report;
use HTGT::Controller::Report::Gene_report_methods;
use HTGT::Controller::Gene;
use JSON;

=head1 NAME

HTGT::Controller::Gene::Update - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

Ajax methods called from gene page

=head1 METHODS

=cut


=head2 index 

=cut

=head2 auto

Perform authorisation - all Gene comment editor requires
 the 'edit or design' privelege

=cut

sub auto : Private {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles(q(edit)) || $c->check_user_roles(q(design)) ) {
        $c->flash->{error_msg} = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }
    return 1;
}


sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HTGT::Controller::Gene::Update in Gene::Update.');
}

sub _add_gene_user : Local {
    
    my ($self, $c) = @_;
    my $mgi_gene_id = $c->req->params->{mgi_gene_id};
    
    my $unspecified_user = $c->model('HTGTDB::ExtUser')->find({email_address=>'[User email address]'});
    
    my $new_gene_user_link;

    $c->model('HTGTDB')->schema->txn_do( sub {
        if(!$unspecified_user){
            $unspecified_user =
                $c->model('HTGTDB::ExtUser')->create({
                    email_address => '[User email address]',
                    edited_user => $c->user->id,
                });
        }
        
        $c->log->debug("unspecified user id: ".$unspecified_user->ext_user_id."\n");
        
        $new_gene_user_link = $c->model('HTGTDB::GeneUser')->create (
            {
               mgi_gene_id  =>  $mgi_gene_id,
               ext_user_id  => $unspecified_user->ext_user_id,
               edited_user  =>  $c->user->id,
               edited_date  =>  \'current_timestamp',
               priority_type => 'user_request',
            }
        );
    });
    
    my @gene_user_links = $c->model('HTGTDB::GeneUser')->search( { mgi_gene_id=>$mgi_gene_id } );
    # get the mgi_gene
    my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $mgi_gene_id } );
    $c->stash->{mgi_gene} = $mgi_gene;
    
    $c->stash->{timestamp}     = $c->req->params->{timestamp};
    
    $c->stash->{mgi_gene_id}  = $mgi_gene_id;
    
    $c->stash->{new_gene_user_id} = $new_gene_user_link->gene_user_id;
    $c->stash->{timestamp}      = $c->req->params->{timestamp};
    $c->stash->{template}       = 'gene/_gene_priority_table.tt';
    
}

sub _gene_users_update : Local {
    my ($self, $c) = @_;
    
    #my $mgi_gene_id = $c->req->params->{mgi_gene_id};
    
    my $gene_user = $c->model('HTGTDB::GeneUser')->find( { gene_user_id => $c->req->params->{id} });
    
    my $email;
    my $priority;
    
    if ($c->req->params->{field} eq 'gene_user'){
        $email = $c->req->params->{value};
        
        my $extUser = $c->model('HTGTDB::ExtUser')->find( { email_address => $email } );
        
        if ($extUser){
            # update the link
            $c->model('HTGTDB::GeneUser')->find( {
                gene_user_id => $c->req->params->{id}
            })->update( { ext_user_id => $extUser->ext_user_id } );
        }else{
            # create a user
            my $extUser = $c->model('HTGTDB::ExtUser')->create({
                        email_address => $email,
                        edited_user => $c->user->id,
                        edited_date  =>  \'current_timestamp',
                    });
            # update the link
            $c->model('HTGTDB::GeneUser')->find( {
                gene_user_id => $c->req->params->{id}
            })->update( { ext_user_id => $extUser->ext_user_id } );
        }

    }elsif ($c->req->params->{field} eq 'priority_type'){
        $priority =  $c->req->params->{value};
        # update gene_user
         $c->model('HTGTDB::GeneUser')->find( {
                gene_user_id => $c->req->params->{id}
            })->update( { priority_type => $priority } );        
    }
   
    $c->res->body($c->req->params->{value});
}

sub _delete_gene_user : Local {
    my ($self, $c) = @_;
    my $mgi_gene_id = $c->req->params->{mgi_gene_id};
    
    # look up gene user
    my $gene_user = $c->model('HTGTDB::GeneUser')->find(
      {
          gene_user_id => $c->req->params->{gene_user_id}
      }
    );
    
    # delete the comment
    if ($gene_user){
       $gene_user->delete();
    }
    
    # get the mgi_gene
    my $mgi_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $mgi_gene_id } );
    $c->stash->{mgi_gene}  = $mgi_gene;
    
    $c->stash->{timestamp}     = $c->req->params->{timestamp};
    $c->stash->{template}      = 'gene/_gene_priority_table.tt';
}

=head2 _gene_comment_update

Ajax method to update a given Gene_Comment record.

=cut

sub _gene_comment_update : Local {
    my ($self,$c) = @_;
  
    #find the edited user
    my $geneComment = $c->model('HTGTDB::GeneComment')->find( { gene_comment_id => $c->req->params->{id} } );

    my $edited_user = $geneComment->edited_user;
  
    unless ($edited_user eq $c->user->id) {
       $c->res->body(
            "<span style='color: red; font-weight: bold;'>You are not authorised to update other's comment. click 'refresh' button to go back.</span>"
       );
    }
    else {
        #Catch empty entries
        if ($self->trim($c->req->params->{value}) eq "") {
            $c->req->params->{value} = '<span style="color:red;">
               You cannot enter empty values here- use the delete button to remove entries
            </span>';         
        }
        else {
           if ($c->req->params->{field} eq "comment"){
               $c->model('HTGTDB::GeneComment')->find(
                   { gene_comment_id => $c->req->params->{id} }
                )->update(
                  {
                      gene_comment  =>  $c->req->params->{value},
                      edited_user   =>  $c->user->id,
                      edited_date   => \'current_timestamp',
                   }
                );
            }
            elsif ($c->req->params->{field} eq "visibility") {
                $c->model('HTGTDB::GeneComment')->find(
                    { gene_comment_id => $c->req->params->{id} }
                 )->update(
                   {
                       visibility   =>  $c->req->params->{value},
                       edited_user  =>  $c->user->id,
                       edited_date  =>  \'current_timestamp',
                   }
                 );                      
            }
            $c->res->body($c->req->params->{value});   
        }
    }    
}

=head2 _gene_comment_new

Ajax method to create a new entry into the GeneComments table
and return the new contents of GeneComments for a given gene.

=cut

sub _gene_comment_new : Local {
    my ($self, $c) = @_;
    
    # get the parameters
    my $project_id = $c->req->params->{project_id};
    my $mgi_gene_id = $c->model('HTGTDB::Project')->find( { project_id => $project_id } )->mgi_gene_id;
    
    # create a new comment
    my $new_comment = $c->model('HTGTDB::GeneComment')->create(
       {
           mgi_gene_id      =>  $mgi_gene_id,
           gene_comment =>  '[New Comment]',
           edited_user  =>  $c->user->id,
           edited_date  =>  \'current_timestamp',
           visibility   =>  'internal'
       }
    );
     
    # get the gene comment
    my @gene_comments = $c->model('HTGTDB::GeneComment')->search( { mgi_gene_id=>$mgi_gene_id } );
    $c->stash->{gene_comments} = \@gene_comments;
    $c->stash->{timestamp}     = $c->req->params->{timestamp};
    
    $c->stash->{project_id}  = $project_id;
    
    $c->stash->{new_comment_id} = $new_comment->gene_comment_id;
    $c->stash->{timestamp}      = $c->req->params->{timestamp};
    $c->stash->{template}       = 'gene/_gene_comment_table.tt';
}

=head2 _gene_comment_delete

Ajax method to delete an entry in the GeneComments table, it will
then return the new contents of GeneComments for a given gene.

=cut

sub _gene_comment_delete : Local {
    my ($self,$c) = @_;
    
    # get the parameters
    my $project_id = $c->req->params->{project_id};
    my $mgi_gene_id = $c->model('HTGTDB::Project')->find( { project_id => $project_id } )->mgi_gene_id;
    
    $c->log->debug("project id: ".$project_id."\n");
    
    # look up design comment
    my $gene_comment = $c->model('HTGTDB::GeneComment')->find(
      {
          gene_comment_id => $c->req->params->{gene_comment_id}
      }
    );
    
    # delete the comment
    $gene_comment->delete();
    
    # get the gene comment
    my @gene_comments = $c->model('HTGTDB::GeneComment')->search( { mgi_gene_id=>$mgi_gene_id } )->all;
    
    $c->stash->{project_id}  = $project_id;
    
    $c->stash->{gene_comments} = \@gene_comments;
    $c->stash->{timestamp}     = $c->req->params->{timestamp};
    $c->stash->{template}      = 'gene/_gene_comment_table.tt';
}


=head2 _design_fulfills_update

  called from gene page, used to update & point the design to the project

=cut

sub _design_fulfills_update : Local {
    my ($self, $c) = @_;

    # get the value
    my $design_id = $c->req->params->{id};  
    my $fulfills = $c->req->params->{value};  
    my $project_id = $c->req->params->{project_id};
   
    # find the project
    my $project = $c->model('HTGTDB::Project')->find({ project_id => $project_id } );
    
    # check if the design_id is in other project, if it is, not allow to update
    my $mgi_gene_id = $project->mgi_gene_id;
    my @all_projects = $c->model('HTGTDB::Project')->search( { mgi_gene_id => $mgi_gene_id } );
    foreach my $p (@all_projects) {
        if ($p->design_id == $design_id && $project->design_id != $design_id){
            $c->res->body(
               '<span style="color: red; font-weight: bold;">Warning: This design is assigned to other project. Please refresh the page to go back.</span>'
            );
            return;
        }
    }
       
    # check if there is design instance, if yes, not allow to update.
    if($project->design_instance_id){
        $c->res->body(
             '<span style="color: red; font-weight: bold;">Warning: The project has design instance, not allow to change design id. Please refresh the page to go back.</span>'
           );
        return;
    }
    
    # check if the project already has design id in the table,
    # if it is the case, later when update new design's d2dr fulfills request, also need to update the old design's d2dr, set it back to 0  
    my $original_design_id_in_the_table = $project->design_id;
    
    if($fulfills == 1) {
        
        # if the project has assigned for a design, give warning.
        if ($original_design_id_in_the_table) {
            $c->res->body(
               '<span style="color: red; font-weight: bold;">Warning:
                  There is a design assigned to the project already. Please unselect it before you assign antoher one.
                  Refresh the page to go back.</span>'
            );
            return;            
        } else {
            # update the project table
            $project->update(
               {
                   design_id          => $design_id,
                   project_status_id  => 10,
                   edit_date          => \'current_timestamp',
                   edit_user          => $c->user->id,
                   status_change_date => \'current_timestamp'
               }
            );
        }
    } elsif ($fulfills == ' '){
        # only update when user update the same design's fulfills request from 1 to 0, otherwise, ignore it.
        
        if ( $original_design_id_in_the_table == $design_id ) {
            # update the project table
            $project->update(
               {
                  design_id          => undef,
                  project_status_id  => 6,
                  edit_date          => \'current_timestamp',
                  edit_user          => $c->user->id,
                  status_change_date => \'current_timestamp',
               }
            );
        }
    }   
    
    $c->res->body($c->req->params->{value});   
}


=head2 _refreshdesign

  called from gene page after import otter gene, used to refresh the design list

=cut


sub _refreshdesign : Local {
    my ($self, $c) = @_;
   
    # get parameters
    my $project_id= $c->req->params()->{project_id};
    
    # get project object
    my $project = $c->model('HTGTDB::Project')->find( { project_id => $c->req->params->{project_id} });
    # get mgi_gene object
    my $mgi_gene = $project->mgi_gene;
    $c->stash->{timestamp}   = $c->req->params->{timestamp}; 
    $c->stash->{project}     = $project;
    $c->stash->{mgi_gene}    = $project->mgi_gene;
    $c->stash->{project_id}  = $project_id;
  
    HTGT::Controller::Gene::get_gene_designs( $self, $c );
    $c->stash->{template} = 'gene/_design_table.tt';
}


=head2 _runDesign

run the design, method called from gene page.

=cut


sub _runDesign : Local {
    my ($self,$c) = @_;
    
    my $param = $c->req->params(); 
    my $design_id   = $param->{design_id};
    
    my $designserver = HTGT::Utils::Design::DesignServer->new();
    $designserver->design_only($c,$design_id);
  
    # need to update previous status first
    $c->model('HTGTDB::DesignStatus')->search({design_id=>$design_id})->update(
      {
         is_current =>0                                                                        
      }
    );
 
    $c->model('HTGTDB::DesignStatus')->update_or_create(
       {
           design_id         =>  $design_id,
           design_status_id  =>  2,
           is_current        =>  1
       }
    );
    
    $c->stash->{timestamp} = $c->req->params->{timestamp}; 
     $self->_refreshdesign($c);
}


=head2

method for creating a new project based on the existing project info

=cut

sub duplicate_project : Local {
    my ($self, $c) = @_;
    
    # copy the information of the project, display in a new page
    # from an exsiting project(old project) id, get the project obj,
    # insert a new recorde(create), copy all the info but not the project id, not design/di/.. info

    my $project_id = $c->req->params->{project_id};
    unless ( $project_id ) {
        my $err_msg = "Create duplicate project failed: project_id not specified";
        $c->log->error( $err_msg );        
        $c->stash->{error_msg} = $err_msg;
        $c->detach( 'Root', 'welcome' );        
    }
    
    # get the info from the project, create a new project with the same info
    my $old_project = $c->model('HTGTDB::Project')->find({ project_id => $project_id });
    unless ( $old_project ) {
        my $err_msg = "Create duplicate project failed: project $project_id not found";
        $c->log->error( $err_msg );
        $c->stash->{error_msg} = $err_msg;        
        $c->detach( 'Root', 'welcome' );
    }
    
    # check if there is an available project which haven't been assigned design yet    
    my $available_projects = $c->model('HTGTDB::Project')
        ->search(
            {
                mgi_gene_id => $old_project->mgi_gene_id,
                is_trap     => undef,
                design_id   => undef,
            } );

    if ( $available_projects->count > 0 ) {
        my $err_msg = "Create duplicate project failed: there is a project available to assign design";
        $c->log->error( $err_msg );
        $c->stash->{error_msg} = $err_msg;        
        $c->detach( 'Root', 'welcome' );
    }
    
    my $new_project = $c->model('HTGTDB::Project')->create(
        {
            mgi_gene_id          => $old_project->mgi_gene_id,
            is_publicly_reported => $old_project->is_publicly_reported,
            project_status_id    => 6,
            is_norcomm           => $old_project->is_norcomm,
            is_komp_csd          => $old_project->is_komp_csd,
            is_komp_regeneron    => $old_project->is_komp_regeneron,
            is_eucomm            => $old_project->is_eucomm,
            is_eucomm_tools      => $old_project->is_eucomm_tools,
            is_eucomm_tools_cre  => $old_project->is_eucomm_tools_cre,
            is_switch            => $old_project->is_switch,
            is_mgp               => $old_project->is_mgp,
            is_tpp               => $old_project->is_tpp,
            is_mgp_bespoke       => $old_project->is_mgp_bespoke,
            edit_date            => \'current_timestamp',
            edit_user            => $c->user->id,
            status_change_date   => \'current_timestamp',
        }
    );
        
    $c->response->redirect( $c->uri_for( '/report/gene_report', { project_id => $new_project->project_id } ) );
}

=head2

method for updating project status from new gene page

=cut
sub update_project_status : Local {
    my ( $self, $c ) = @_;
    
    my $project_id = $c->req->params->{project_id};
    my $status     = $c->req->params->{name};
  
    my @projectStatus     = $c->model('HTGTDB::ProjectStatus')->search( { name => $status } );
    my $project_status_id = $projectStatus[0]->project_status_id;
   
    my $project = $c->model('HTGTDB::Project')->find({ project_id => $project_id });
    
    $project->update(
        {
            project_status_id  => $project_status_id,
            edit_date          => \'current_timestamp',
            edit_user          => $c->user->id,
            status_change_date => \'current_timestamp',
        }
    );
    $c->res->body( $c->req->params->{name} );
}


=head2

Method for updating a projects publicly reported flag via gene page

=cut
sub update_project_publicly_reported : Local {
    my ( $self, $c ) = @_;
    
    my $project_id        = $c->req->params->{project_id};
    my $publicly_reported = $c->req->params->{name};
    
    unless ( $project_id ) {
        my $err_msg = "Update project public reporting visibility failed: project_id not specified";
        $c->log->error( $err_msg );        
        $c->res->body( 'error: project_id not specified' );
        $c->detach();
    }
    my $project = $c->model('HTGTDB::Project')->find({ project_id => $project_id });
    
    unless ( $project ) {
        my $err_msg = "Update project public reporting visibility failed: project $project_id not found";
        $c->log->error( $err_msg );     
        $c->res->body( 'error: project_id not found' );
        $c->detach();
    }
    
    unless ( $publicly_reported ) {
        my $err_msg = "Update project public reporting visibility failed: publicly reported value not specified";
        $c->log->error( $err_msg );        
        $c->stash->{error_msg} = $err_msg;
        $c->res->body( 'error: publicly reported value empty' );
        $c->detach();     
    }

    my $projectPubliclyReported
        = $c->model('HTGTDB::ProjectPubliclyReported')->find( { description => $publicly_reported } );
        
    unless ( $projectPubliclyReported ) {
        my $err_msg = "Update project public reporting visibility failed: invalid publicly reported value specified";
        $c->log->error( $err_msg );        
        $c->res->body( 'error: publicly reported value invalid' );
        $c->detach();            
    }
    my $is_publicly_reported  = $projectPubliclyReported->is_publicly_reported;
    
    $project->update(
        {
            is_publicly_reported => $is_publicly_reported,
            edit_date            => \'current_timestamp',
            edit_user            => $c->user->id,
        }
    );
    $c->res->body( $c->req->params->{name} );
}

sub update_program : Local {
    my ( $self, $c ) = @_;
    
    my $project_id = $c->req->params->{project_id};
    my $program = $c->req->params->{name};
    
    my $project = $c->model('HTGTDB::Project')->find({ project_id => $project_id });
    
    # update the database
    if ( $program eq "EUCOMM" ) {
        $project->update(
            {
               is_eucomm => 1,
               is_eucomm_tools => 0,
               is_eucomm_tools_cre => 0,
               is_komp_csd => 0,
               is_norcomm => 0,
               is_eutracc => 0,
               is_switch  => 0,
               is_tpp => 0,
               is_mgp_bespoke => 0,
               edit_date => \'current_timestamp',
               edit_user => $c->user->id,
            }
        );
    } elsif ( $program eq "EUCOMM-Tools" ){
        $project->update(
           {
              is_eucomm_tools => 1,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_eutracc => 0,
              is_switch  => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id,
           }
        );        
    } elsif ( $program eq "KOMP" ){
        $project->update(
           {
              is_komp_csd => 1,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_eutracc => 0,
              is_switch  => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id,
           }
        );
    } elsif ( $program eq "NORCOMM" ) {
        $project->update(
           {
              is_norcomm => 1,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_eutracc => 0,
              is_switch  => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
        );
    } elsif ( $program eq "EUTRACC" ) {
        $project->update(
           {
              is_eutracc => 1,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_switch  => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
       ); 
    } elsif ( $program eq "SWITCH" ) {
        $project->update(
           {
              is_switch  => 1,
              is_eutracc => 0,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
       ); 
    } elsif ( $program eq "EUCOMM-Tools-Cre" ) {
        $project->update(
           {
              is_eucomm_tools_cre => 1,
              is_switch  => 0,
              is_eutracc => 0,
              is_eucomm_tools => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_tpp => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
       ); 
    } elsif ( $program eq "TPP" ) {
        $project->update(
           {
              is_tpp => 1,
              is_switch  => 0,
              is_eutracc => 0,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_mgp_bespoke => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
       ); 
    } elsif ( $program eq "MGP-Bespoke" ) {
        $project->update(
           {
              is_mgp_bespoke => 1,
              is_switch  => 0,
              is_eutracc => 0,
              is_eucomm_tools => 0,
              is_eucomm_tools_cre => 0,
              is_komp_csd => 0,
              is_eucomm => 0,
              is_norcomm => 0,
              is_tpp => 0,
              edit_date => \'current_timestamp',
              edit_user => $c->user->id
           }
       ); 
    }
    $c->res->body( $c->req->params->{name} );    
}

=head2 trim

Method for triming the space of form value

=cut

sub trim : Private {
    my ( $self, $string ) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}


=head1 AUTHOR

Wanjuan Yang <wy1@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;


