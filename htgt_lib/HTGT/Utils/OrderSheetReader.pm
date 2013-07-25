package HTGT::Tools::OrderSheetReader;
use strict;
use warnings;
use Spreadsheet::ParseExcel;


=head1 AUTHOR

Vivek Iyer

=cut


sub extractOligosFromSheet {
  my (
    $self, $c, $file, $plate, $worksheet_name, $row_index, 
    $col_index, $name_index, $seq_index, $container) = @_;

  my $excel = Spreadsheet::ParseExcel::Workbook->Parse($file);
  foreach my $sheet (@{$excel->{Worksheet}}) {
    unless ($sheet->{Name} eq $worksheet_name){ next; }
    foreach my $row ($sheet->{MinRow} .. $sheet->{MaxRow}){
      my $plate_row = $sheet->{Cells}[$row][$row_index];
      my $plate_col = $sheet->{Cells}[$row][$col_index];
      my $seq = $sheet->{Cells}[$row][$seq_index];
      my $name = $sheet->{Cells}[$row][$name_index];

      $c->log("received: $plate_row $plate_col $name $seq");
      unless($plate_row && $plate_col && $name && $seq){ next; }

      if(length($plate_col) <=1){
        $plate_col = "0$plate_col";
      }

      $name =~ /(\S+)_(\S+)_(\S+)_(\S+)/;
      my $random_name = $1;
      if(!$plate){
        $plate = $2;
      }
      my $well = $3;
      my $oligo_type = $4; 

      $c->log("Random: $random_name, plate: $plate, well $well, type $oligo_type");
      unless($random_name && $plate && $well && $oligo_type){ next; }
      
      if(!$well){
        $well = "$plate_row${plate_col}"
      }

      my $design_instance = 
        $c->model->('HTGTDB::DesignInstance')->search(
          plate=>$plate,
          well=>"$plate_row${plate_col}"
        )->first();

      $c->log(
        "got design_instance: ".$design_instance->design_instance_id.
        " for design: ".$design_instance->design_id
      );

      unless ($design_instance){ next; }

      $container->{$design_instance->design_id}->{$oligo_type} = $seq;
      
      $c->log("put sequence into design_container");
    }
  }
}

1;
