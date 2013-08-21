#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use HTGT::Utils::Recovery::GeneHistory 'get_gene_recovery_history';

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

for my $mgi_gene ( @ARGV ) {
    my $history = get_gene_recovery_history( $htgt, $mgi_gene );
    print "$mgi_gene:\n";
    for ( @{ $history } ) {
        print join( "\t", map { $_ || '' } @{$_}{ qw( updated state desc note ) } ) . "\n";
    }
}
