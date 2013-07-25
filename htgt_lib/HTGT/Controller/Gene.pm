package HTGT::Controller::Gene;

use strict;
use warnings;
use base 'Catalyst::Controller';
use HTGT::Utils::GeneIDs 'get_gene_ids';
use DateTime;
use JSON;
use Const::Fast;
use List::MoreUtils qw(any);

=pod

=head1 NAME

HTGT::Controller::Gene::Gene - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    
    $c->response->redirect( $c->uri_for('/gene'));
}

=head2

  retrieve gene comments

=cut


sub get_gene_comments : Local {
    my ( $self, $c ) = @_;
        
    my $gnm_gene_id = $c->stash->{gnm_gene_id};
    
    my $project = $c->stash->{project};
    my $mgi_gene_id = $project->mgi_gene_id;
    
    my @gene_comments = $c->model('HTGTDB::GeneComment')->search(mgi_gene_id=>$mgi_gene_id);
    
    $c->stash->{gene_comments} = \@gene_comments;
    $c->stash->{gnm_gene_id} = $gnm_gene_id;
   
    $c->stash->{project} = $project;
}

=head2

   retrieve all the designs for the given gene

=cut

sub get_gene_designs : Local {
    my ( $self, $c ) = @_;

    my $mgi_gene = $c->stash->{mgi_gene};
    my $project = $c->stash->{project};
    my $project_id = $project->project_id;
    my $gnm_gene_id = $c->stash->{gnm_gene_id};
    
    # find the design that attach to the project
    # should find gene id from mgi_sanger_gene table
    
    #Grabbing all mgi_sanger_genes linked to mgi_gene table gene
    my @mgi_sanger_genes = get_gene_ids($mgi_gene);
    
    my @design_ids; # store the design ids
    my @design_info_list; # store the design info
    
    foreach my $gene_id (@mgi_sanger_genes) {
        my $sql = "select distinct(design.design_id) from
               mig.gnm_gene_build_gene,
               mig.gnm_transcript,
               mig.gnm_exon,
               design
               where 
               gnm_gene_build_gene.ID = gnm_transcript.BUILD_GENE_ID
               and gnm_transcript.ID = gnm_exon.TRANSCRIPT_ID
               and gnm_exon.id = design.start_exon_id
               and gnm_gene_build_gene.primary_name = '".$gene_id."'";
        $c->log->debug("sql: ".$sql);
    
        my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
        $sth->execute();

        while ( my @result = $sth->fetchrow_array ) {
            push @design_ids, $result[0];
        }
    }
    
    foreach my $id (@design_ids) {
        my $design = $c->model('HTGTDB::Design')->find( { design_id => $id } );
        my $design_info;
        $design_info->{design_id} = $id;
        $design_info->{start_exon} = $design->start_exon->primary_name;
        $design_info->{end_exon} = $design->end_exon->primary_name;
        $design_info->{created_user} = $design->created_user;
        
        # check if the design is belong to the project
        if ($id == $project->design_id) {
            $design_info->{fulfills} = 1;
        }
        
        my $designComment = $design->design_user_comments->search({},{ order_by => { -desc => 'edited_date' } })->first;
        if ($designComment) {
              $design_info->{comment} = $designComment->design_comment;
        }
    
        my $status =$design->statuses->search(is_current=>1)->first;
        if($status){
            # check if need to display run button
            my $gene_build_id = $design->gene_build_id;
            my $design_status = $status->design_status_dict->description;
            
            if ($design_status eq "Created" && $gene_build_id == 26) {
               $design_info->{display_run_button} = 1;
            }
            
            eval { $design_info->{design_status} = $status->design_status_dict->description; };
        } 
        push @design_info_list, $design_info;
    }
   $c->stash->{design_info_list} = \@design_info_list;
   $c->stash->{project} = $project;
   $c->stash->{project_id} = $project_id;
   
}

sub get_project_status_list : Local {
    my ( $self, $c ) = @_;
    
    my $project_id = $c->req->params->{project_id};
    
    my @all_project_status = $c->model('HTGTDB::ProjectStatus')->all;
    
    my @project_status_list;

    # if there is other projects with the same gene's project status is further than 'Vector Complete -  Project Terminated'
    # then do not include this status in the project status list
    my $project = $c->model('HTGTDB::Project')->find({ project_id => $project_id });
    my @projects_with_same_gene = $c->model('HTGTDB::MGIGene')->find( { mgi_gene_id => $project->mgi_gene_id } )->projects;
    my $do_not_include = 0;
   
    if ( any { $c->model('HTGTDB::ProjectStatus')->find({project_status_id => $_->project_status_id})->order_by > 89 } @projects_with_same_gene ){
        $do_not_include = 1;    
    }
    
    foreach my $projectStatus (@all_project_status){
        if ( $do_not_include == 1 ){
           if( $projectStatus->project_status_id == 60 ){
               next;
           }
        }   
        push @project_status_list, $projectStatus->name;    
    }   

    $c->res->body( objToJson(\@project_status_list) );
}

sub get_program_list : Local {
    my ( $self, $c ) = @_;

    my @program_list = (
        "EUCOMM",  'EUCOMM-Tools', 'EUCOMM-Tools-Cre', "KOMP",
        "NORCOMM", "EUTRACC",      "SWITCH",           "TPP",
        "MGP-Bespoke"
    );

    $c->res->body( objToJson( \@program_list ) );
}

sub get_publicly_reported_list : Local {
    my ( $self, $c ) = @_;
    my @project_publicly_reported_list;
    
    my @publicly_reported = $c->model('HTGTDB::ProjectPubliclyReported')->all;
    
    map { push @project_publicly_reported_list, $_->description } @publicly_reported;
    
    $c->res->body( objToJson(\@project_publicly_reported_list) );
}

=head1 AUTHOR

Wanjuan Yang <wy1@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
