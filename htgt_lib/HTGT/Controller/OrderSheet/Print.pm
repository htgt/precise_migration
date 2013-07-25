package HTGT::Controller::OrderSheet::Print;

use strict;
use warnings;
use base 'Catalyst::Controller';
use HTGT::Utils::OrderSheetReader;

=head1 NAME

HTGT::Controller::OrderSheet::Print - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS


=head1 AUTHOR

Vivek Iyer

=cut


=head2 index 

=cut

sub index : Private {
  my ( $self, $c ) = @_;
  $c->response->body(
    'Matched HTGT::Controller::OrderSheet::Print in OrderSheet::Print.'
  );
}

sub show_print_pb_long_range_oligo_orders : Local {
  my ($self, $c) = @_;
  $c->stash->{template} = 'ordersheet/long_range_2.tt';
}

sub show_print_long_range_oligo_orders : Local {
  my ($self, $c) = @_;
  $c->stash->{template} = 'ordersheet/long_range.tt';
}

sub print_long_range_oligo_orders : Local {
  my ($self, $c) = @_;
  my $plate = $c->request->param('plate');
  my $use_pb = $c->request->param('pb_oligos');
  my @oligo_data;

  $c->log->debug("Fetching design instances for plate: $plate");
  my @design_instances = $c->model('HTGTDB::DesignInstance')->search(plate=>$plate);
  $c->log->debug("Fetched ".@design_instances." instances ");

  foreach my $design_instance(@design_instances){
    $c->log->debug("Got design instance ".$design_instance->design_instance_id." : ".$design_instance->well);
    my $design = $design_instance->design;

    # This hashref has all the values for a row.
    my $lr_oligos;
    my $plate = $design_instance->plate;
    my $well = $design_instance->well;
    my $random_name = $design_instance->design->random_name;
    $lr_oligos->{PLATE} = $plate;
    $lr_oligos->{WELL} = $well;
    $lr_oligos->{GF1_LABEL} = "${random_name}_${plate}_${well}_GF1";
    $lr_oligos->{GF2_LABEL} = "${random_name}_${plate}_${well}_GF2";
    $lr_oligos->{GF3_LABEL} = "${random_name}_${plate}_${well}_GF3";
    $lr_oligos->{GF4_LABEL} = "${random_name}_${plate}_${well}_GF4";
    $lr_oligos->{GR1_LABEL} = "${random_name}_${plate}_${well}_GR1";
    $lr_oligos->{GR2_LABEL} = "${random_name}_${plate}_${well}_GR2";
    $lr_oligos->{GR3_LABEL} = "${random_name}_${plate}_${well}_GR3";
    $lr_oligos->{GR4_LABEL} = "${random_name}_${plate}_${well}_GR4";
    $lr_oligos->{EX5_LABEL} = "${random_name}_${plate}_${well}_EX5";
    $lr_oligos->{EX3_LABEL} = "${random_name}_${plate}_${well}_EX3";
    $lr_oligos->{EX52_LABEL} = "${random_name}_${plate}_${well}_EX52";
    $lr_oligos->{EX32_LABEL} = "${random_name}_${plate}_${well}_EX32";

    my @oligos = $design->features;
    foreach my $oligo(@oligos){
      my $type = $oligo->feature_type->description;
      if(
        ($type eq 'GF1')||
        ($type eq 'GF2')||
        ($type eq 'GF3')||
        ($type eq 'GF4')||
        ($type eq 'EX3')||
        ($type eq 'EX5')||
        ($type eq 'EX32')||
        ($type eq 'EX52')||
        ($type eq 'GR1')||
        ($type eq 'GR2')||
        ($type eq 'GR3')||
        ($type eq 'GR4')
      ){
        my $seq;
        my @feature_data = $oligo->feature_data;
        foreach my $datum(@feature_data){
          if($datum->feature_data_type->description eq 'sequence'){
            $seq = $datum->data_item;
            $c->log->debug("for type $type, got sequence : $seq"); 
            last;
          }
        }
        $lr_oligos->{$oligo->feature_type->description} = $seq;
        $c->log->debug("for oligo $type: stuck in sequence : $seq\n");
      }
    }
    push @oligo_data, $lr_oligos;
    my @types = keys (%$lr_oligos);
    $c->log->debug("Got types @types"); 
  }

  my @new_oligo_data = sort {$a->{WELL} cmp $b->{WELL}} @oligo_data;
  foreach my $lr_ref(@new_oligo_data){
    $c->log->debug(" printing out well : ".$lr_ref->{WELL}." GF1 seq: ".$lr_ref->{GF1});
  }

  $c->stash->{oligo_data} = \@new_oligo_data; 
  $c->stash->{plate} = $plate; 
  if(!$use_pb){
    $c->stash->{template} = 'ordersheet/long_range.tt';
  }else{
    $c->stash->{template} = 'ordersheet/long_range_2.tt';
  }
}

1;
