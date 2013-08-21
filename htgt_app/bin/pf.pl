#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Bio::EnsEMBL::Registry;
use List::Util qw( max min );
use Data::Dump 'dd';

my $gene_id = shift @ARGV
    or die "Usage: $0 ENSEMBL_GENE_ID\n";

Bio::EnsEMBL::Registry->load_registry_from_db(
    -host => $ENV{HTGT_ENSEMBL_HOST} || 'ens-livemirror.internal.sanger.ac.uk',
    -user => $ENV{HTGT_ENSEMBL_USER} || 'ensro'
);

my $gene_adaptor = Bio::EnsEMBL::Registry->get_adaptor( 'mouse', 'core', 'gene' );

my $gene = $gene_adaptor->fetch_by_stable_id( $gene_id )
    or die "failed to retrieve gene $gene_id";

for my $transcript ( @{ $gene->get_all_Transcripts } ) {
    next unless $transcript->biotype eq 'protein_coding';
    #dump_data( $gene, $transcript );    
    dd( {
        transcript => $transcript->stable_id,
        peptide    => $transcript->translation->seq
    } );
    
    dd( domain_exon_map( $gene, $transcript ) );
}

sub domain_exon_map {
    my ( $gene, $transcript ) = @_;

    my $translation = $transcript->translation;

    my @domains;
    for my $domain ( @{ $translation->get_all_DomainFeatures } ) {
        push @domains, {
            idesc       => $domain->idesc,
            interpro_ac => $domain->interpro_ac,
            logic_name  => $domain->analysis->logic_name,
            peptide     => substr( $translation->seq, $domain->start, $domain->end - $domain->start + 1 ),
            start       => $domain->start,
            end         => $domain->end,
            exons       => overlapping_exons( $transcript, $domain )
        };        
    }

    return \@domains;
}

sub overlapping_exons {
    my ( $transcript, $domain ) = @_;

    my $exons = $transcript->get_all_Exons;
    my $transcript_peptide = $transcript->translation->seq;    

    my @overlapping_exons;

    for my $exon ( @{ $exons } ) {
        my $exon_peptide = $exon->peptide( $transcript )
            or next;
        $exon_peptide = $exon_peptide->seq;
        my $start = index( $transcript_peptide, $exon_peptide );
        die "can't find $exon_peptide in $transcript_peptide" unless $start >= 0;
        my $end = $start + length( $exon_peptide );
        my $overlap_start = max( $start, $domain->start );
        my $overlap_end   = min( $end, $domain->end );
        my $overlap = $overlap_end - $overlap_start + 1;
        next unless $overlap > 0;
        my $pct_domain_ko = int( $overlap * 100 / ( $domain->end - $domain->start + 1 ) );
        push @overlapping_exons, {
            stable_id  => $exon->stable_id,
            start      => $exon->start,
            end        => $exon->end,
            pct_ko     => $pct_domain_ko,
            peptide    => $exon_peptide
        };
    }

    return \@overlapping_exons;    
}

sub dump_data {
    my ( $gene, $transcript ) = @_;

    my $exons       = $transcript->get_all_Exons;
    my $translation = $transcript->translation;
    my $domains     = $translation->get_all_DomainFeatures;

    my %data = (
        gene => {
            stable_id  => $gene->stable_id,
            start      => $gene->start,
            end        => $gene->end,
            strand     => $gene->strand,
            chromosome => $gene->slice->seq_region_name
        },
        transcript => {
            stable_id => $transcript->stable_id,
            start     => $transcript->start,
            end       => $transcript->end,
            coding_region_start => $transcript->coding_region_start,
            coding_region_end   => $transcript->coding_region_end,         
        },
        exons => [
            map {
                stable_id  => $_->stable_id,
                start      => $_->start,
                end        => $_->end,
                cdna_start => $_->cdna_start( $transcript ),
                cdna_end   => $_->cdna_end( $transcript ),
                peptide    => $_->peptide( $transcript )->seq
            }, @{ $exons }           
        ],
        translation => {
            start_exon => $translation->start_Exon->stable_id,
            end_Exon   => $translation->end_Exon->stable_id,
            peptide    => $translation->seq
        },
        domains => [
            map {
                idesc       => $_->idesc,
                interpro_ac => $_->interpro_ac,
                logic_name  => $_->analysis->logic_name,
                start       => $_->start,
                end         => $_->end,
                cdna_start  => $_->start * 3,
                cdna_end    => $_->end * 3
            }, @{ $domains }
        ]
    );
    dd( %data );    
}

    

