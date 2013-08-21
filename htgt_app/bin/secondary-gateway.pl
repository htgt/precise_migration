#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use HTGT::Utils::Recovery::Report::SecondaryGateway;
use Log::Log4perl ':easy';
use CSV::Writer;

my $plate_name = shift
    or die "Usage: $0 PLATE_NAME\n";

Log::Log4perl->easy_init( $WARN );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $vector_qc = HTGT::DBFactory->connect( 'vector_qc' );

my $report = HTGT::Utils::Recovery::Report::SecondaryGateway->new(
    plate_name       => $plate_name,
    schema           => $htgt,
    vector_qc_schema => $vector_qc,
);

my $csv = CSV::Writer->new( columns => [ $report->columns ] );
$csv->write( $report->columns );

while ( $report->has_next ) {
    $csv->write( $report->next_record );    
}
