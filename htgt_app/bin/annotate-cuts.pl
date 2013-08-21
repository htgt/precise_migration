#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::SeqIO;
use Bio::Restriction::Analysis;

die "Usage: $0 GENBANK_FILE ENZYME_NAME\n"
    unless @ARGV == 2;

my ( $genbank_file, $enzyme_name ) = @ARGV;

my $in = Bio::SeqIO->new(
    -format => 'genbank',
    -file   => $genbank_file
);

my $out = Bio::SeqIO->new(
    -format => 'genbank',
    -fh     => \*STDOUT
);

while ( my $seq = $in->next_seq ) {
   my $ra = Bio::Restriction::Analysis->new( -seq => $seq );
   for my $fragment ( $ra->fragment_maps( $enzyme_name ) ) {
       my $feature = Bio::SeqFeature::Generic->new(
           -start       => $fragment->{start},
           -end         => $fragment->{end},
           -primary_tag => 'misc_feature',
           -tag         => { label => "$enzyme_name fragment", note => "$enzyme_name fragment" }
       );
       $seq->add_SeqFeature( $feature );       
   }
   $out->write_seq( $seq );
}

