#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use HTGT::Utils::Design::Info;
use YAML;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

for ( @ARGV ) {
    my $design;
    if ( /^\d+$/ ) {
        $design = $htgt->resultset( 'Design' )->find( { design_id => $_ } )
           or die "failed to retrieve design $_\n"; 
    }
    elsif ( (my ( $plate, $well ) =  /^(\w+)\[(\w+)\]$/ ) ) {
        my $well = $htgt->resultset( 'Well' )->find(
            {
                'plate.name'     => $plate,
                'me.well_name' => $well
            },
            {
                join => 'plate'
            }
        ) or die "failed to retrieve well $_\n";
        $design = $well->design_instance->design;
    }
    else {
        die "Unrecognized input: $_\n";        
    }

    my $i = HTGT::Utils::Design::Info->new( design => $design );    
    
    print YAML::Dump( $i->as_hash );
}
