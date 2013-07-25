package Kermits::CSV;

use Moose;

extends "Kermits";

use FileHandle;

has name => ( isa => 'Str', is => 'rw', required => 1 );
has file => ( isa => 'FileHandle', is => 'ro', lazy => 1, builder => '_build_file' );

sub _build_file {
  my $self = shift;
  my $fh = new FileHandle $self->name, "w" || die "Unable to open file " . $self->name . "\n";
  return $fh;
}

sub centre_mi_data {
  my ( $self, $params ) = @_;
  
  my $dataset_ah_ref = $self->microinjections_detailed( { project => $params->{project}, centre => $params->{centre} } );
  
  
  my $headings_a_ref = [ keys %{ $dataset_ah_ref->[0] } ];
  
  my $formatted_data = '';
  
  # Write the header...
  for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
    $formatted_data .= '"' . $headings_a_ref->[$col] . '"';
    unless ( $col == ( scalar( @{$headings_a_ref} ) - 1 ) ) { $formatted_data .= ','; }
  }
  $formatted_data .= "\n";

  # Now the data...
  for ( my $row = 0 ; $row < scalar( @{$dataset_ah_ref} ) ; $row++ ) {
    for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
      if ( $dataset_ah_ref->[$row]->{ $headings_a_ref->[$col] } ) {
        if ( $headings_a_ref->[$col] =~ /date/i ) {
          $formatted_data .= '"' . $dataset_ah_ref->[$row]->{ $headings_a_ref->[$col] }->ymd . '"';
        }
        else {
          $formatted_data .= '"' . $dataset_ah_ref->[$row]->{ $headings_a_ref->[$col] } . '"';
        }
      }
      else {
        $formatted_data .= '""';
      }
      unless ( $col == ( scalar( @{$headings_a_ref} ) - 1 ) ) { $formatted_data .= ','; }
    }
    $formatted_data .= "\n";
  }
  
  return $formatted_data;
}

sub write_centre_mi_data {
  my ( $self, $params ) = @_;

  my $csv_data = $self->centre_mi_data( { project => $params->{project}, centre => $params->{centre} } );
  $self->file->print($csv_data);
  $self->file->close();
}

no Moose;
1;
