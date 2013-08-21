#!/usr/bin/env perl

use HTGT::Utils::DesignFinder::Gene;
use Log::Log4perl ':easy';
use Bio::Graphics::Panel;
use Bio::Graphics::Feature;

use Smart::Comments;

Log::Log4perl->easy_init(
    {
        level  => $WARN,
        layout => '%p %m%n'
    }
);

my $ensembl_gene_id = shift
    or die "Usage: $0 ENSEMBL_GENE_ID\n";

my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $ensembl_gene_id );

my $transcript = $gene->template_transcript;

my $t = Bio::Graphics::Feature->new(
    -type  => 'transcript',
    -start => $transcript->start,
    -end   => $transcript->end,
    -name  => $transcript->stable_id,
    -desc  => $transcript->stable_id
);

my @exons;

for my $exon ( @{ $transcript->get_all_Exons } ) {
    my $e = Bio::Graphics::Feature->new(
        -type  => 'exon',
        -start => $exon->start,
        -end   => $exon->end,
        -name  => $exon->stable_id,
        -desc  => $exon->stable_id
    );
    push @exons, $e;
}

my $p = Bio::Graphics::Panel->new(
    -length => $t->length,
    -width  => 800,
    -start  => $transcript->start,
);

$p->add_track( transcript2 => \@exons, -height => 20 );

print $p->png;


