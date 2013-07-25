package HTGT::Controller::Design::CRUD;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

HTGT::Controller::Design::CRUD - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

=head1 AUTHOR

Vivek Iyer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->body('Matched HTGT::Controller::Design::CRUD');
}

sub delete : Local {
  my ($self, $c) = @_;

  my $design_id = $c->request->param('design_id');
  $c->log->debug("Deleting design...".$design_id);
  if(!$design_id){
    die "programming error - delete called without design_id"; 
  }

  my $design = $c->model('HTGTDB::Design')->search(design_id=>$design_id)->first;

  if(!$design){
    die "programming error - could not retrieve design with id: design_id"; 
  }

  my $design_info = $c->controller('DesignEdit')->create_design_info_from_stored_design($c,$design);
  
  if(!$design){
    $c->log->debug("Cant find the design to refresh!");
    return;
  }

  if(!$design_info){
    die "programming error - cannot retrieve information about the design to be deleted"; 
  }
  $design_info->{message} = "";

  # TODO: The below needs to be replaced - we shouldn't be storing the user name in the session/stash any more as we can use the sanger user object...
  #my $user_name = $c->session->{user_name};
  my $user_name = $c->user->id;
  $c->log->debug("user name: ".$user_name);
  my $created_user = $design->created_user;
  # Better to implement this with actual exception handling
  if(!$user_name){
    $c->log->debug("checking user name...");
    $c->stash->{template} = 'design/edit.tt';
    $design_info->{message} = "User must be logged in to delete a design";
    return;
  }

  if(!($created_user eq $user_name)){
    $c->log->debug("checking created user ...");
    $c->stash->{template} = 'design/edit.tt';
    $design_info->{message} = "To delete a design, the designs created user must be the same as the user logged in";
    return;
  }

  my @design_intances = $c->model('HTGTDB::DesignInstance')->search(design_id=>$design_id);
  $c->log->debug("checking design instance ...");
  if(scalar(@design_intances) > 0){
    $c->log->debug("Design is linked to one or more design instances - not allow to delete.");
    $c->stash->{template} = 'design/edit.tt';
    $c->stash->{error_msg} = "Design is linked to one or more design instances - not deleting\n";
    return;
  }
   
  # add another check: when the design has been assigned for a project, then should not be deleted
  my @projects = $c->model('HTGTDB::Project')->search(design_id=>$design_id);
  $c->log->debug("checking project ...");
  if (scalar(@projects) > 0) {
    $c->log->debug("Design is linked to a project - not deleting");
    $c->stash->{template} = 'design/list.tt';
    $c->stash->{error_msg} = "Warning: This design is linked to one or more projects - not allow to delete, please check the associated projects first!\n";
    return;
  }
   
   
  $c->log->debug("pass checking ...");
  if($design){
    my $locus_id = $design->locus;
    $c->log->debug("deleting design: $design_id with locus: $locus_id");

    my $feature_data_select =
      " select feature_data_id from feature_data, feature ".
      " where feature.design_id = $design_id and feature_data.feature_id = feature.feature_id";

    my $feature_data_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($feature_data_select);
    $feature_data_sth->execute();

    while(my @result = $feature_data_sth->fetchrow_array){
      my ($feature_data_id) = @result;
      $c->log->debug("deleting feature_data $feature_data_id");
      my $feature_data_delete = "delete from feature_data where feature_data_id = ?";
      my $feature_data_delete_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($feature_data_delete);
      $feature_data_delete_sth->execute($feature_data_id);
    }

    my $disp_feature_select =
      " select feature.feature_id from display_feature, feature ".
      " where feature.design_id = $design_id and display_feature.feature_id = feature.feature_id";
    my $disp_feature_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($disp_feature_select);
    $disp_feature_sth->execute();
    while(my @result = $disp_feature_sth->fetchrow_array){
      my ($feature_id) = @result;
      $c->log->debug("deleting display_features for feature_id $feature_id");
      my $disp_delete = "delete from display_feature where feature_id = ?";
      my $disp_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($disp_delete);
      $disp_sth->execute($feature_id);
      $c->log->debug("deleted display features for $feature_id");
    }

    $c->log->debug("deleting features linked to design $design_id");
    my $feature_sql = "delete from feature where design_id = ?";
    my $feature_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($feature_sql);
    $feature_sth->execute($design_id);

    $c->log->debug("deleting design-bac links for design $design_id");
    my $bac_sql = "delete from design_bac where design_id = ?";
    my $bac_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($bac_sql);
    $bac_sth->execute($design_id);

    $c->log->debug("deleting design_status for design $design_id");
    my $status_delete = "delete from design_status where design_id = ?";
    my $status_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($status_delete);
    $status_sth->execute($design_id);
    $c->log->debug("deleted design statuses");

    $c->log->debug("deleting design_notes for design $design_id");
    my $note_delete = "delete from design_note where design_id = ?";
    my $note_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($note_delete);
    $note_sth->execute($design_id);
    $c->log->debug("deleted design notes for $design_id");

    #delete from any linked design-groups
    my $design_group_sql = "delete from design_design_group where design_id = ?";
    my $design_group_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($design_group_sql);
    $design_group_sth->execute($design_id);
    $c->log->debug("deleted links to design groups for $design_id");
    
    #delete from design_user_comments
    my $design_user_comments_sql = "delete from design_user_comments where design_id = ?";
    my $design_user_comments_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($design_user_comments_sql);
    $design_user_comments_sth->execute($design_id);
    $c->log->debug("deleted design user comments for $design_id");

    #Finally delete design ...
    my $design_sql = "delete from design where design_id = ?";
    my $design_sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($design_sql);
    $design_sth->execute($design_id);
    $c->log->debug("deleted design $design_id");

  }else{
    die "Couldnt find design with id: $design_id";
  }
  $c->stash->{template} = 'design/list.tt';
}


1;
