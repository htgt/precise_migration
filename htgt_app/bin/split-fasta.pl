#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::SeqIO;
use Path::Class;
use Getopt::Long;

my $outdir = dir( '.' );

GetOptions( 'outdir=s' => sub { $outdir = dir( $_[1] ) } )
    and @ARGV or die "Usage: $0 [--outdir=PATH] IN.FASTA ...\n";

for my $in_path ( @ARGV ) {
    my $seq_in = Bio::SeqIO->new( -file => $in_path, -format => 'fasta' );
    while ( my $seq = $seq_in->next_seq ) {
        ( my $id = $seq->display_id ) =~ s/\s+.+$//;
        my $out_path = $outdir->file( "$id.fasta" );
        die "$out_path already exists\n" if $out_path->stat;
        my $seq_out = Bio::SeqIO->new( -fh => $out_path->openw, -format => 'fasta' );
        $seq_out->write_seq( $seq );
    }                                   
}
