package HTGT::Controller::OrderSheet::Upload;

use strict;
use warnings;
use base 'Catalyst::Controller';
use HTGT::Utils::OrderSheetReader;

=head1 NAME

HTGT::Controller::OrderSheet::Upload - Catalyst Controller

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
    'Matched HTGT::Controller::OrderSheet::Upload in OrderSheet::Upload.'
  );
}

sub insert_order_sheet : Local {
  my ($self, $c) = @_;
  my $designs = $c->session->{designs};

  my @feature_data_types = $c->model('HTGTDB::FeatureDataType')->all();
  my $fd_types;
  foreach my $feature_data_type(@feature_data_types){
    $fd_types->{$feature_data_type->description}=$feature_data_type->feature_data_type_id;
  }

  foreach my $design (@$designs){
    my $design_id = $design->{DESIGN_ID};
    foreach my $type('GF1','GF2','EX5','EX3','GR1','GR2'){
      $self->create_feature($c, $design_id, $type, $design->{$type}, $fd_types);
    }
  }
  $c->stash->{template} = 'ordersheet/upload.tt';
}

sub create_feature : Private {
  my ($self, $c, $design_id, $typedesc, $seq, $fd_types) = @_;
  my @types = $c->model('HTGTDB::FeatureType')->search(description=>$typedesc);
  my $type = $types[0];

  if(!$type){
    die "no type with description $typedesc";
  }

  my $found_type_id = $type->feature_type_id;

  $c->log->debug("creating feature of type $typedesc for design $design_id");

  my $feature =
    $c->model('HTGTDB::Feature')->create(
      {
        design_id=>$design_id,
        feature_type_id=>$found_type_id,
        feature_start=>-1,
        feature_end=>-1,
        chr_id=>1,
      }
    );

  $c->log->debug("created feature with id: ".$feature->feature_id);
  
  my $seq_data =
    $c->model("HTGTDB::FeatureData")->create(
      {
        feature_id=>$feature->feature_id,
        feature_data_type_id=>$fd_types->{'sequence'},
        data_item=>$seq
      }
    );

  $c->log->debug("created feature data with id: ".$seq_data->feature_data_id);
  
  my $validation_data =
    $c->model("HTGTDB::FeatureData")->create(
      {
        feature_id=>$feature->feature_id,
        feature_data_type_id=>$fd_types->{'validated'},
        data_item=>1
      }
    );

  $c->log->debug("created feature data with id: ".$validation_data->feature_data_id);
}

sub read_order_sheet : Local {
  my ($self, $c) = @_;
  my @file_names = @{$self->upload_order_sheet($c)};
  my $row_index = 1;
  my $col_index = 2;
  my $name_index = 3;
  my $seq_index = 5;
  my $container = {};

  # flush out any old sequences being held 
  $c->delete_session;

  $c->log->debug("processing uploaded files");
  foreach my $file_name(@file_names){
    $c->log->debug("processing file $file_name");
    $self->put_sequences_by_design_id_into_container(
      $c,
      $file_name,
      $row_index,
      $col_index,
      $name_index,
      $seq_index,
      $container
    );
  }

  $c->log->debug("found ".scalar(keys %$container)." designs with seqs ");

  foreach my $design_id(keys %$container){
    my $ex3seq = $container->{$design_id}->{EX3};
    my $ex5seq = $container->{$design_id}->{EX5};
    my $gf1seq = $container->{$design_id}->{GF1};
    my $gf2seq = $container->{$design_id}->{GF2};
    my $gr1seq = $container->{$design_id}->{GR1};
    my $gr2seq = $container->{$design_id}->{GR2};
    my $plate = $container->{$design_id}->{PLATE};
    my $well = $container->{$design_id}->{WELL};
    $c->log->debug("$design_id: $plate\t$well\tgf1\t$gf1seq\tgf2\t$gf2seq\tex5\t$ex5seq\tex3\t$ex3seq\tgr1\t$gr1seq\tgr2\t$gr2seq");
  }

  #my @design_array = values %$container;
  my @design_array = sort {$a->{WELL} cmp $b->{WELL}} values %$container;

  $c->session->{designs} = \@design_array;
  $c->stash->{designs} = \@design_array; 
  $c->stash->{template} = 'ordersheet/upload.tt';
}

sub put_sequences_by_design_id_into_container{
  my ($self, $c, $file_name, $row_index, $col_index, $name_index, $seq_index, $container) = @_; 
  $c->log->debug("Row index; $row_index, col index: $col_index , name index $name_index, seq index: $seq_index");
  my $excel = Spreadsheet::ParseExcel::Workbook->Parse($file_name);
  $c->log->debug("made excel sheet: number of worksheets: ".@{$excel->{Worksheet}});
  foreach my $sheet (@{$excel->{Worksheet}}) {
    $c->log->debug("Sheet: %s", $sheet->{Name});
    unless ($sheet->{Name} eq 'Plate Order Form'){ next };

    $sheet->{MaxRow} ||= $sheet->{MinRow};
    $c->log->debug("Found maxrow: ".$sheet->{MaxRow}." and minrow: ".$sheet->{MinRow});
    foreach my $row_count ($sheet->{MinRow} .. $sheet->{MaxRow}) {
      #$c->log->debug("Processing row: $row_count");
      my $min_col = $sheet->{MinCol};
      my $max_col = $sheet->{MaxCol};
      my $row;
      my $col;
      my $name;
      my $seq;
 
      if(($row_index >= $min_col) && ($row_index <= $max_col)){
        $row = $sheet->{Cells}[$row_count][$row_index]->{Val};
      }
      if(($col_index >= $min_col) && ($col_index <= $max_col)){
        $col = $sheet->{Cells}[$row_count][$col_index]->{Val};
      }
      if(($name_index >= $min_col) && ($name_index <= $max_col)){
        $name = $sheet->{Cells}[$row_count][$name_index]->{Val};
      }
      if(($seq_index >= $min_col) && ($seq_index <= $max_col)){
        $seq = $sheet->{Cells}[$row_count][$seq_index]->{Val};
      }

      #$c->log->debug("Got row: $row col: $col name: $name and seq: $seq");
      if(!$name){
        $c->log->debug(" cant get name for row $row_count ");
        next;
      }
      if(!$seq){
        $c->log->debug(" cant get seq for row $row_count ");
        next;
      }
      $name =~ /(\S+)_(\S+)_(\S+)_(\S+)/;

      my $random = $1;
      my $plate = $2;
      my $well = $3;
      my $type = $4;
      
      unless ($random && $plate && $well && $type){
        $c->log->debug("cant get full information from name: random $random: plate $plate: well $well: type $type");
        next;
      }

      my $design_instance = $c->model('HTGTDB::DesignInstance')->search({plate=>$plate,well=>$well})->first;
      if($design_instance){
        my $design_id = $design_instance->design_id;
        $c->log->debug("Got designid: $design_id for plate $plate and well $well"); 
        my $design_container = $container->{$design_id};
        $design_container->{WELL} = $well;
        $design_container->{PLATE} = $plate;
        $design_container->{DESIGN_ID} = $design_id;
        $design_container->{uc($type)} = $seq;
        $container->{$design_id} = $design_container;
        $c->log->debug("added seq $seq for type $type");
      }else{
        $c->log->debug("cant get design_instance for plate $plate and well $well");
      }
    }
  }
}

sub upload_order_sheet: Private {
  my ($self, $c) = @_;
  my $uploaded_file_names = [];
  $c->log->debug(" started upload ");
  if($c->request->parameters->{form_submit} eq 'yes' ) {
    $c->log->debug(" form-submit parameter was yes ");
    for my $field ( $c->req->upload ) {
      $c->log->debug("read field: $field");
      my $upload   = $c->req->upload($field);
      my $filename = $upload->filename;
      my $target   = "/tmp/upload/$filename";
      unless ( $upload->link_to($target) || $upload->copy_to($target) ) {
        die( "Failed to copy '$filename' to '$target': $!" );
      }
      push @$uploaded_file_names, $target;
      $c->log->debug("uploaded to $target");
    }
  }else{
    $c->log->debug(" form-submit parameter was NOT yes ");
  }
  return $uploaded_file_names;
}


1;
