package Kermits::XLS;

use Moose;

extends "Kermits";

use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Utility;
use DateTime;
use DateTime::Format::Excel;
use Math::Round qw(:all);

has name                   => ( is => 'rw' );
has file                   => ( is => 'rw' );
has workbook               => ( is => 'ro', lazy => 1, builder => '_build_workbook' );
has format_title           => ( is => 'ro', lazy => 1, builder => '_build_format_title' );
has format_subtitle        => ( is => 'ro', lazy => 1, builder => '_build_format_subtitle' );
has format_bold            => ( is => 'ro', lazy => 1, builder => '_build_format_bold' );
has format_date            => ( is => 'ro', lazy => 1, builder => '_build_format_date' );
has format_table           => ( is => 'ro', lazy => 1, builder => '_build_format_table' );
has format_table_bold      => ( is => 'ro', lazy => 1, builder => '_build_format_table_bold' );
has format_table_date      => ( is => 'ro', lazy => 1, builder => '_build_format_table_date' );
has format_table_header    => ( is => 'ro', lazy => 1, builder => '_build_format_table_header' );
has format_table_highlight => ( is => 'ro', lazy => 1, builder => '_build_format_table_highlight' );

##
## Builders
##

sub _build_workbook {
  my $self = shift;
  my $workbook;

  if ( $self->name ) {
    $workbook = Spreadsheet::WriteExcel->new( $self->name );
  }
  elsif ( $self->file ) {
    $workbook = Spreadsheet::WriteExcel->new( $self->file );
  }
  else {
    die "You must define either a file name or filehandle to write to!";
  }

  return $workbook;
}

sub _build_format_title {
  my $self = shift;
  return $self->workbook->add_format( bold => 1, size => 14 );
}

sub _build_format_subtitle {
  my $self = shift;
  return $self->workbook->add_format( bold => 1, size => 12 );
}

sub _build_format_bold {
  my $self = shift;
  return $self->workbook->add_format( bold => 1 );
}

sub _build_format_date {
  my $self = shift;
  return $self->workbook->add_format( num_format => 'dd-mmm-yy' );
}

sub _build_format_table {
  my $self = shift;
  return $self->workbook->add_format( border => 1 );
}

sub _build_format_table_bold {
  my $self = shift;
  return $self->workbook->add_format( bold => 1, border => 1, border_color => 63 );
}

sub _build_format_table_date {
  my $self = shift;
  return $self->workbook->add_format( num_format => 'dd-mmm-yy', border => 1, border_color => 63 );
}

sub _build_format_table_header {
  my $self = shift;
  return $self->workbook->add_format(
    color        => 'white',
    bold         => 1,
    border       => 1,
    border_color => 63,
    bg_color     => 63,
    text_wrap    => 1,
    align        => 'top'
  );
}

sub _build_format_table_highlight {
  my $self = shift;
  return $self->workbook->add_format( bold => 1, border => 1, border_color => 63, bg_color => 43 );
}

##
## Methods
##

sub add_worksheet {
  my ( $self, $params ) = @_;
  my $worksheet = $self->workbook->add_worksheet( $params->{sheet_name} );
  $worksheet->set_column( 'A:Z', 18 );    # Set the default column width
  return $worksheet;
}

sub write_centre_mi_data {
  my ( $self, $params ) = @_;

  my $dataset_ah_ref = $self->microinjections_detailed( { project => $params->{project}, centre => $params->{centre} } );
  my $worksheet = $self->add_worksheet( { sheet_name => $params->{sheet_name} ? $params->{sheet_name} : $params->{centre} } );
  $self->write_ah_ref_dataset_to_table( { worksheet => $worksheet, dataset => $dataset_ah_ref, row => 0 } );
  $worksheet->freeze_panes(1, 0);
}

sub write_summary_sheet {
  my ( $self, $params ) = @_;

  my $worksheet = $self->add_worksheet( { sheet_name => 'Summary' } );

  # Print a header...
  $worksheet->write( 0, 0, 'Mouse Production: Gene Summary', $self->format_title() );

  # Use this to control the row of the sheet that we print to...
  my $row = 3;

  $row = $self->write_summary_all_centre_overview( { worksheet => $worksheet, row => $row, project => $params->{project} } );
  $row += 2;

  my $project = $params->{project};

  if ( $project ) {
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'WTSI', project => $project, pretty_name => 'Sanger - '.$project } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'GSF', pretty_name => 'Helmholtz', project => $project } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'ICS', project => $project } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'MRC - Harwell', pretty_name => 'MRC', project => $project } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'Monterotondo', pretty_name => 'CNR', project => $project } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'UCD', pretty_name => 'UCD', project => $project } ); $row++;
  } else {
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'WTSI', project => 'EUCOMM', pretty_name => 'Sanger - EUCOMM' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'WTSI', project => 'KOMP', pretty_name => 'Sanger - KOMP' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'GSF', pretty_name => 'Helmholtz' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'ICS' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'MRC - Harwell', pretty_name => 'MRC' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'Monterotondo', pretty_name => 'CNR' } ); $row++;
    $row = $self->write_summary_centre_detail_by_month( { worksheet => $worksheet, row => $row, centre => 'UCD', pretty_name => 'UCD' } ); $row++;
  }

}

sub write_summary_all_centre_overview {
  my ( $self, $params ) = @_;

  my $centres   = $params->{centres};
  my $project   = $params->{project};
  my $worksheet = $params->{worksheet};
  my $row       = $params->{row};

  # Set-up a counter...
  my $totals = {
    'injected'    => 0,
    'transmitted' => 0
  };

  # Write the table header...
  $worksheet->write( $row, 0, 'Centre',              $self->format_table_header() );
  $worksheet->write( $row, 1, '# Genes Injected',    $self->format_table_header() );
  $worksheet->write( $row, 2, '# Genes Transmitted', $self->format_table_header() );
  $worksheet->write( $row, 3, '# Genes Genotype Confirmed', $self->format_table_header() );
  $row++;

  # Write the data for each centre...
  if ( $project ) {
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'WTSI', project => $project, pretty_name => 'Sanger - '.$project } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'GSF', pretty_name => 'Helmholtz', project => $project } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'ICS', project => $project } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'MRC - Harwell', pretty_name => 'MRC', project => $project } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'Monterotondo', pretty_name => 'CNR', project => $project } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'UCD', pretty_name => 'UCD', project => $project } );
  } else {
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'WTSI', project => 'EUCOMM', pretty_name => 'Sanger - EUCOMM' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'WTSI', project => 'KOMP', pretty_name => 'Sanger - KOMP' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'GSF', pretty_name => 'Helmholtz' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'ICS' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'MRC - Harwell', pretty_name => 'MRC' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'Monterotondo', pretty_name => 'CNR' } );
    ( $row, $totals ) = $self->write_summary_row( { worksheet => $worksheet, row => $row, totals => $totals, centre => 'UCD', pretty_name => 'UCD' } );
  }
  
  # Sums and totals...
  $worksheet->write( $row, 0, '',                     $self->format_table_highlight() );
  $worksheet->write( $row, 1, $totals->{injected},    $self->format_table_highlight() );
  $worksheet->write( $row, 2, $totals->{transmitted}, $self->format_table_highlight() );
  $worksheet->write( $row, 3, $totals->{genotype_confirmed}, $self->format_table_highlight() );
  $worksheet->write( $row, 4, 'Sum',                  $self->format_bold() );
  $row++;

  my $injected_data    = $self->injected_counts({ project => $params->{project} });
  my $transmitted_data = $self->transmitted_counts({ project => $params->{project} });
  my $genotype_confirmed_data = $self->genotype_confirmed_counts({ project => $params->{project} });

  $worksheet->write( $row, 0, '',                          $self->format_table_highlight() );
  $worksheet->write( $row, 1, $injected_data->{unique},    $self->format_table_highlight() );
  $worksheet->write( $row, 2, $transmitted_data->{unique}, $self->format_table_highlight() );
  $worksheet->write( $row, 3, $genotype_confirmed_data->{unique}, $self->format_table_highlight() );
  $worksheet->write( $row, 4, 'Unique',                    $self->format_bold() );
  $row++;

  return $row;
}

sub write_summary_row {
  my ( $self, $params ) = @_;

  my $worksheet     = $params->{worksheet};
  my $row           = $params->{row};
  my $centre        = $params->{centre};
  my $project       = $params->{project};
  my $pretty_centre = $params->{pretty_name} ? $params->{pretty_name} : $params->{centre};
  my $totals        = $params->{totals};

  my $injected_data = $self->injected_counts( { centre => $centre, project => $project } );
  my $transmitted_data = $self->transmitted_counts( { centre => $centre, project => $project } );
  my $genotype_confirmed_data = $self->genotype_confirmed_counts( { centre => $centre, project => $project } );

  $worksheet->write( $row, 0, $pretty_centre,              $self->format_table() );
  $worksheet->write( $row, 1, $injected_data->{unique},    $self->format_table() );
  $worksheet->write( $row, 2, $transmitted_data->{unique}, $self->format_table() );
  $worksheet->write( $row, 3, $genotype_confirmed_data->{unique}, $self->format_table() );
  $row++;
  
  $totals->{injected}    += $injected_data->{unique};
  $totals->{transmitted} += $transmitted_data->{unique};
  $totals->{genotype_confirmed} += $genotype_confirmed_data->{unique};
  
  return ( $row, $totals );
}

sub write_summary_centre_detail_by_month {
  my ( $self, $params ) = @_;

  my $worksheet     = $params->{worksheet};
  my $row           = $params->{row};
  my $centre        = $params->{centre};
  my $project       = $params->{project};
  my $pretty_centre = $params->{pretty_name} ? $params->{pretty_name} : $params->{centre};

  # Get the dataset
  my $dataset_ah_ref = $self->microinjections_overview( { centre => $centre, project => $project, pretty_name => $pretty_centre } );

  # Write the headers...
  $worksheet->write( $row, 0, $pretty_centre, $self->format_subtitle() );
  $row += 2;

  # Print the data table and summary row...
  $row = $self->write_ah_ref_dataset_to_table( { worksheet => $worksheet, dataset => $dataset_ah_ref, row => $row, summary_row => 1, return_row => 1 } );

  # Get summary counts for injection and transmission
  my $injected_data = $self->injected_counts( { centre => $centre, project => $project } );
  my $testcross_data = $self->injected_counts( { centre => $centre, project => $project, month_offset => 4 } );
  my $transmitted_data = $self->transmitted_counts( { centre => $centre, project => $project } );
  my $genotype_confirmed_data = $self->genotype_confirmed_counts( { centre => $centre, project => $project } );

  # Print these to the base of the table
  my $headings_a_ref = [ keys %{ $dataset_ah_ref->[0] } ];
  for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
    if ( $headings_a_ref->[$col] eq '# Clones Injected' ) {
      $worksheet->write( $row,     $col, '# Genes Injected',       $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $injected_data->{unique}, $self->format_table_highlight() );
    }
    elsif ( $headings_a_ref->[$col] eq '# Clones Transmitting' ) {
      $worksheet->write( $row,     $col, '# Genes Transmitted',       $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $transmitted_data->{unique}, $self->format_table_highlight() );
    }
    elsif ( $headings_a_ref->[$col] eq '# Clones Genotype Confirmed' ) {
      $worksheet->write( $row,     $col, '# Genes Genotype Confirmed',       $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $genotype_confirmed_data->{unique}, $self->format_table_highlight() );
    }
    elsif ( $headings_a_ref->[$col] eq '# Clones Test-Cross Completed' ) {
      $worksheet->write( $row,     $col, '# Genes Test-Cross Completed', $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $testcross_data->{unique}, $self->format_table_highlight() );
    }
    elsif ( $headings_a_ref->[$col] eq '% Clones Transmitting' ) {
      my $genes_transmitted = 0;
      if ( $testcross_data->{unique} ) { $genes_transmitted = round( ( $transmitted_data->{unique} / $testcross_data->{unique} ) * 100 ); }
      $worksheet->write( $row,     $col, '% Genes Transmitted', $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $genes_transmitted,    $self->format_table_highlight() );
    }
    elsif ( $headings_a_ref->[$col] eq '% Clones Genotype Confirmed' ) {
      my $genes_genotype_confirmed = 0;
      if ( $testcross_data->{unique} ) { $genes_genotype_confirmed = round( ( $genotype_confirmed_data->{unique} / $testcross_data->{unique} ) * 100 ); }
      $worksheet->write( $row,     $col, '% Genes Genotype Confirmed', $self->format_table_header() );
      $worksheet->write( $row + 1, $col, $genes_genotype_confirmed,    $self->format_table_highlight() );
    }
  }
  $row += 2;

  return $row;
}

sub write_ah_ref_dataset_to_table {
  my ( $self, $params ) = @_;

  my $worksheet      = $params->{worksheet};
  my $dataset_ah_ref = $params->{dataset};
  my $row            = $params->{row};

  my $headings_a_ref = [ keys %{ $dataset_ah_ref->[0] } ];

  # Write the header...
  for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
    $worksheet->write( $row, $col, $headings_a_ref->[$col], $self->format_table_header() );
  }
  $row++;

  # Now the data...
  foreach my $data_row ( @{$dataset_ah_ref} ) {
    for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
      if ( $headings_a_ref->[$col] =~ /date/i ) {
        my $excel_date = DateTime::Format::Excel->format_datetime( $data_row->{ $headings_a_ref->[$col] } );
        $worksheet->write( $row, $col, $excel_date, $self->format_table_date() );
      }
      else {
        $worksheet->write( $row, $col, $data_row->{ $headings_a_ref->[$col] }, $self->format_table() );
      }
    }
    $row++;
  }

  if ( $params->{summary_row} ) {
    for ( my $col = 0 ; $col < scalar( @{$headings_a_ref} ) ; $col++ ) {
      if ( $headings_a_ref->[$col] =~ /#/ ) {
        my $start_range = xl_rowcol_to_cell( $params->{row} + 1, $col );    # Add one to miss header
        my $end_range   = xl_rowcol_to_cell( $row - 1,           $col );    # Minus one to miss 'total' row
        my $sum_formula = '=SUM(' . $start_range . ':' . $end_range . ')';
        $worksheet->write( $row, $col, $sum_formula, $self->format_table_highlight() );
      }
      else {
        $worksheet->write( $row, $col, '', $self->format_table_highlight() );
      }
    }
    $worksheet->write( $row, scalar( @{$headings_a_ref} ), 'Total', $self->format_bold() );
    $row++;
  }

  if ( $params->{return_row} ) { $row++; return $row; }
}

no Moose;
1;
