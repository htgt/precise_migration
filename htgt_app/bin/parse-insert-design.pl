#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

my $ensembl_gene_id;
my %by_gene_id;

while ( <> ) {
    if ( /^(ENSMUSG\d+)/ ) {
        $ensembl_gene_id = $1;
    }
    if ( /^Inserted design (\d+)/ ) {
        push @{ $by_gene_id{ $ensembl_gene_id } }, $1;
    }    
}

while ( my ( $gene, $designs ) = each %by_gene_id ) {
    print join( "\t", $gene, @$designs ) . "\n";    
}
