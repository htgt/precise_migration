package HTGT::Controller::Design::ValidateDesign;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

HTGT::Controller::Design::List_Designs_for_validation - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HTGT::Controller::Design::List_Designs_for_validation in Design::ValidateDesign.');
}

sub auto : Private {
    my ( $self, $c ) = @_;
    unless ( $c->check_user_roles(q(design)) ) {
        $c->flash->{error_msg} = "You are not authorised to use this function";
        $c->response->redirect( $c->uri_for('/') );
        return 0;
    }
    return 1;
}

sub load_form : Local {
    my ($self, $c) = @_;

    $c->stash->{status_list} =  $self->all_project_status($c);
    $c->stash->{design_plates_list} = $self->all_design_plates($c);
    
    $c->stash->{template} = 'design/designs_for_validation.tt';
}

sub all_project_status : Private {
    my ($self, $c) = @_;
    
    my @project_status = $c->model('HTGTDB::ProjectStatus')->all();
    
    my @project_status_list;
    
    foreach my $status (@project_status){
        push @project_status_list, $status->name;
    }
    
    return \@project_status_list;
}

sub all_design_plates : Private {
    my ( $self, $c ) = @_;

    my $sth =
      $c->model('HTGTDB')
      ->schema->storage->dbh->prepare(
        "select distinct plate from design_instance");
    $sth->execute();
    my @plates;
    while ( my @result = $sth->fetchrow_array ) {
        push @plates, $result[0];
    }

    @plates = sort { $a <=> $b } @plates;

    return \@plates;
}

sub list_designs : Local {
  my ($self, $c) = @_;

  my $program = $c->request->param('program');
  my $priority = $c->request->param('priority');
  my @status = $c->request->param('status');  
  my $chromosome = $c->request->param('chromosome');
  my $plate = $c->request->param('plate');
  
  my $project_status_id = undef;
  my @project_status_ids;
  
  # get the project status id
  # if 'All' not selected, collect all the statuses selected
  if ( !(grep $_ eq "All", @status) ){
      foreach my $s (@status){	  
	  $project_status_id = $c->model('HTGTDB::ProjectStatus')->search( name => $s )->first()->project_status_id; 
	  push @project_status_ids, $project_status_id;
      }
  }
  
    my $sql = "
       select distinct
              design.design_id,
              project.project_id,
              project.IS_EUCOMM,
              project.is_eucomm_tools,
              project.is_eucomm_tools_cre,
              project.is_mgp_bespoke,
              project.is_tpp,
              project.is_trap, 
              project.is_komp_csd,
              project.is_switch,
              mgi_gene.MARKER_SYMBOL,
              mgi_gene.ENSEMBL_GENE_ID,
              mgi_gene.MGI_ACCESSION_ID,
              design.DESIGN_TYPE,
              project_status.name STATUS,
              project.project_status_id,
              project.targvec_plate_name,
              project.targvec_pass_level,
              mgi_gene.ENSEMBL_GENE_CHROMOSOME,
              mgi_gene.mgi_gene_id,
              gnm_locus.chr_start COORDINATE_START,
              gnm_exon_1.primary_name start_exon,
              gnm_exon_2.primary_name end_exon,
              gene_user.priority_type,
              (select count(*) from gene_user where gene_user.MGI_GENE_ID = mgi_gene.mgi_gene_id) priority_count
       from design, design_instance, project, project_status, mgi_gene, mig.GNM_LOCUS gnm_locus, mig.gnm_exon gnm_exon_1, mig.gnm_exon gnm_exon_2, gene_user
       where design.design_id = project.design_id
       and project.mgi_gene_id = mgi_gene.mgi_gene_id
       and design.locus_id = gnm_locus.id
       and design.design_id = design_instance.design_id
       and project.project_status_id = project_status.project_status_id
       and design.validated_by_annotation is null
       and project_status.order_by >= 75
       and design.start_exon_id = gnm_exon_1.id
       and design.end_exon_id = gnm_exon_2.id
       and gene_user.mgi_gene_id(+) = mgi_gene.mgi_gene_id
       and project.is_trap IS NULL
              ";
  
  # add program           
  if( $program eq "EUCOMM" ){
      $sql = $sql." and project.is_eucomm = 1";
  }elsif($program eq "KOMP"){
      $sql = $sql." and project.IS_KOMP_CSD =1";
  }elsif($program eq "EUCOMM-Tools"){
      $sql = $sql." and project.is_eucomm_tools =1";
  }elsif($program eq "EUCOMM-Tools-Cre"){
      $sql = $sql." and project.is_eucomm_tools_cre =1";
  }elsif($program eq "switch"){
      $sql = $sql." and project.is_switch =1"
  }elsif($program eq "MGP-Bespoke"){
      $sql = $sql." and project.is_mgp_bespoke =1"
  }elsif($program eq "TPP"){
      $sql = $sql." and project.is_tpp =1"
  }else{
      $sql = $sql." and ( project.is_eucomm = 1
                    or project.IS_KOMP_CSD =1
                    or project.is_eucomm_tools = 1
                    or project.is_eucomm_tools_cre = 1
                    or project.is_switch = 1
                    or project.is_tpp = 1
                    or project.is_mgp_bespoke = 1
                )";
  }
   
  # add chromosome
  if ($chromosome ne 'All'){
      $sql = $sql." and mgi_gene.ENSEMBL_GENE_CHROMOSOME = '".$chromosome."'";
  }
 
  # add project status id, only when not select 'All'.
  # construct the sql statement, first get the status ids except the last one
  my $last_id;
  my @ids;

  if (scalar(@project_status_ids)>0) {
      @ids = @project_status_ids;
      $last_id = pop @ids;
  
      $sql = $sql." and project.project_status_id in (";
      foreach my $id (@ids){
	  $sql = $sql.$id.",";
      }
      # finish with the last one
      $sql = $sql.$last_id.")";
  }
  
  # add plate
  if ($plate ne "All"){
      $sql = $sql." and design_instance.plate = '".$plate."'";
  }
  
  # add priority type
  if ($priority eq "User request"){
     $sql = $sql." and gene_user.priority_type = 'user_request'";
  }elsif($priority eq "Material ordered"){
     $sql = $sql." and gene_user.priority_type = 'material_ordered'"; 
  }
  
  $sql = $sql . " order by marker_symbol ";
   
  $c->log->debug("#### sql: ".$sql);
  my $sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($sql);
  $sth->execute();
  
  my %design;
  
  while(my $result = $sth->fetchrow_hashref()){ 
      if ( ( not exists $design{$result->{DESIGN_ID}} ) || (exists $design{$result->{DESIGN_ID}} and ($design{$result->{DESIGN_ID}}->{PROJECT_STATUS_ID} < $result->{PROJECT_STATUS_ID} ))) {   
               $design{$result->{DESIGN_ID}} = $result;
            
            if((defined $result->{IS_EUCOMM} and $result->{IS_EUCOMM} == 1) and (not defined $result->{IS_TRAP}) ){
                $design{$result->{DESIGN_ID}}->{PROGRAM} = "EUCOMM";
            }else{
                $design{$result->{DESIGN_ID}}->{PROGRAM} = "KOMP";
            }
            
            if($result->{DESIGN_TYPE} and $result->{DESIGN_TYPE} =~ /Del/){
                $design{$result->{DESIGN_ID}}->{DESIGN_TYPE} = "Deletion";
            }elsif($result->{DESIGN_TYPE} and $result->{DESIGN_TYPE} =~ /Ins/){
                $design{$result->{DESIGN_ID}}->{DESIGN_TYPE} = "Insertion";
            }else{
                $design{$result->{DESIGN_ID}}->{DESIGN_TYPE} = "Knockout first";
            }
            $design{$result->{DESIGN_ID}}->{TARGET_EXONS} = $result->{START_EXON}."-".$result->{END_EXON};
      } elsif(exists $design{$result->{DESIGN_ID}}
                and ($design{$result->{DESIGN_ID}}->{PROJECT_ID} == $result->{PROJECT_ID})
                and ($design{$result->{DESIGN_ID}}->{PRIORITY_TYPE} ne $result->{PRIORITY_TYPE}) ){
            
            $design{$result->{DESIGN_ID}}->{PRIORITY_TYPE} = $design{$result->{DESIGN_ID}}->{PRIORITY_TYPE}." , ".$result->{PRIORITY_TYPE};
      } else {
        next;
      }
  }

  # turn array status to hash
  my %status = map {$_ =>1 } @status;
  $c->stash->{status} = \%status;
    
  $c->stash->{number_of_rows} = keys %design;
  $c->stash->{designs}  = \%design;
  $c->stash->{priority} = $priority;
  $c->stash->{chromosome} = $chromosome;
  $c->stash->{plate} = $plate;
  $c->stash->{program} = $program;
  $c->stash->{status_list} =  $self->all_project_status($c);
  $c->stash->{design_plates_list} = $self->all_design_plates($c);
  $c->stash->{template} = 'design/designs_for_validation.tt';

}

sub update_validation : Local {
    my ($self, $c) = @_;
    
    my $design_id = $c->req->params->{id};
    my $validate = $c->req->params->{value};
    
    $validate = undef
        unless $validate eq 'yes' or $validate eq 'no' or $validate eq 'maybe';
            
    $c->model('HTGTDB::Design')->find( { design_id => $design_id } )->update(
        {
            validated_by_annotation => $validate,
            edited_date             => \'current_timestamp',
            edited_by               => $c->user->id
        }
    );

    $validate ||= 'not done'; # for display purposes
    $c->stash->{desgin_info} = {
        validated_by_annotation => $validate,
        design_id               => $design_id
    };    

    $c->res->body( $validate );
}


=head1 AUTHOR

Wanjuan Yang wy1@sanger.ac.uk

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
