package HTGT::Controller::EUCOMM_Mouse::Update;

use strict;
use warnings;
use base 'Catalyst::Controller';
use DateTime;

=head1 NAME

HTGT::Controller::EUCOMM_Mouse::Update - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

Ajax methods for updating various attributes on the gene_info and well_data
tables related to whether a gene is of interest to eucomm mouse producers,
and whether the cell lines coming from that gene are being distributed.

=head1 METHODS

=cut

=head2 index 

Redirected to '/report/show_list'

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect('/report/show_list');
}

=head2 _gene_info_eucomm_mouse_update

Ajax method to update a gene_info record to switch the eucomm_mouse flag on and off.

=cut

sub _gene_info_eucomm_mouse_update : Local {
    my ( $self, $c ) = @_;

    unless ($c->check_user_roles("eucomm")||($c->check_user_roles("edit"))) {
      $c->log->debug("NOT AUTHORISED");
      $c->flash->{error_msg} = "You are not authorised to perform this function";
      $c->res->body( qq [ You are not authorised to edit this field ]);
    }

    foreach my $key ($c->req->params){
      $c->log->debug("$key :".$c->req->params->{$key});
    }

    my $field = $c->req->params->{field};
    my $field_id = $c->req->params->{id};
    my $new_value = $c->req->params->{value};

    unless (($new_value == 1) || ($new_value == 0) || ($new_value eq 'yes')){
      $c->log->debug("INVALID UPDATE");
      $c->flash->{error_msg} = qq[ Invalid update value (must be 1,0 or 'yes')];
      $c->res->body(qq[ Invalid update for the 'for_eucomm_mouse' property ]);
    }
    
    # If the field is at gene-level, retrieve / update gene-level object.
    # - otherwise add or update a well-data record.
    # If we have been asked to make a gene 'assigned' to a particular centre, then
    # we have to also flip over -as 'assigned' to the same centre- any ES-cells for that particular gene.
    if (
        ($field eq 'for_eucomm_mouse') ||
        ($field eq 'for_recovery') ||
        ($field eq 'recovery_comment') ||
        ($field eq 'for_eumodic') ||
        ($field eq 'eucomm_comment') ||
        ($field =~ /gene_(\S+_status)/)
    ){
      if($field =~ /gene_(\S+_status)/){
        $field = $1;
      }
      $c->log->debug("Field name:$field:");
      my $gene_info = $c->model('HTGTDB::GeneInfo')->find({ gene_id => $field_id } );
      $c->log->debug("got gene_info record: ".$gene_info->gene_info_id." with cnr_status ".$gene_info->cnr_status);
      if($field =~ /status/){
        
        $gene_info->update( {
          $field => (length($new_value)?$new_value:undef),
          status_edit_user => $c->user->id,
          status_edit_date=>$self->get_date_string()
        });
        
      }
      else{
        $gene_info->update({ $field => (length($new_value)?$new_value:undef) });
      }
    }
    else{
      my $mark_audit = 0;
      if(($field =~ /cell_(\S+_status)/) || ($field eq 'available')){
        $mark_audit = 1;
      }
      my $epd_well = $c->model('HTGTDB::Well')->find({ well_name => $field_id });
      my $well_data = 
        $c->model('HTGTDB::WellData')->find_or_create(
          { 
            well_id => $epd_well->well_id,
  	        data_type => $field,
          }
        );

      if($mark_audit){
        $well_data->update({ data_value=>$new_value, edit_user=>$c->user->id, edit_date=>$self->get_date_string()});
      }else{
        $well_data->update({ data_value=>$new_value });
      }
    }

    if($new_value){
      if($new_value == 1){
        $c->log->debug('returning a yes');
        $c->res->body('yes');
      }
      else{
        $c->res->body($new_value);
      }
    }
    else{
      $c->res->body(' ');
    }
}

sub get_date_string{
  my $self = shift;
  my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
  my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
  my $year = 1900 + $yearOffset;
  my $theDay = "$dayOfMonth-".$months[$month]."-${year}";
  # my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
  return $theDay;
}


=head1 AUTHOR

Vivek Iyer <vvi@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
