#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::SeqIO;

for my $input_file ( @ARGV ) {
    ( my $output_file = $input_file ) =~ s/\.[^.]+/.fasta/;
    my $seq_in  = Bio::SeqIO->new( -file => $input_file,      -format => 'genbank' );
    my $seq_out = Bio::SeqIO->new( -file => '>'.$output_file, -format => 'fasta' );
    while ( my $seq = $seq_in->next_seq ) {
        $seq_out->write_seq( $seq );        
    }
}
