#!/usr/bin/env perl

use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Readonly;

my $vector_qc = HTGT::DBFactory->connect( 'vector_qc' );    
my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $htgt_rs = $htgt->resultset( 'HTGTDB::Plate' )->search(
    {
        'plate_data.data_type'  => 'is_384',
        'plate_data.data_value' => 'yes', 
    },
    {
        join => 'plate_data',
        columns => [ 'name' ],
        distinct => 1
    }
);

my @htgt_plates;
while ( my $p = $htgt_rs->next ) {
    push @htgt_plates, $p->name; 
}

my $qc_rs = $vector_qc->resultset( 'ConstructQC::QctestRun' )->search(
    {
        stage       => 'post_gateway',
    },
    {
        columns  => [ 'clone_plate' ],
        distinct => 1
    }
);

while ( my $p = $qc_rs->next ) {
    my $plate_name = $p->clone_plate;
    unless ( grep $_ =~ /^\Q$plate_name\E/, @htgt_plates ) {
        print "$plate_name\n";
    }     
}
