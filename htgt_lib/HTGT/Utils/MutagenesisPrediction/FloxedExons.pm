package HTGT::Utils::MutagenesisPrediction::FloxedExons;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'get_floxed_exons' ]
};

use HTGT::Utils::DesignFinder::Gene;
use Try::Tiny;

sub get_floxed_exons {
    my ( $ensembl_gene_id, $target_region_start, $target_region_end ) = @_;

    my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $ensembl_gene_id );
    
    if ( $gene->strand < 0 ) {
        ( $target_region_start, $target_region_end ) = ( $target_region_end, $target_region_start );        
    }
    
    my $transcript;
    try {
        $transcript = $gene->template_transcript;
    }
    catch {
        die $_ unless $_ =~ m/Failed to find a template transcript/;        
        $transcript = ( $gene->all_transcripts )[0];
    };
    
    my @floxed_exons;

    if ( $target_region_start && $target_region_end ) {
        @floxed_exons = map { $_->stable_id }
            grep { $_->end >= $target_region_start and $_->start <= $target_region_end }
                @{ $transcript->get_all_Exons };
    }
    elsif( $target_region_start ) {
        @floxed_exons = map { $_->stable_id }
            grep { $_->end >= $target_region_start }
                @{ $transcript->get_all_Exons };
    }
    else{
        @floxed_exons = map { $_->stable_id }
            grep { $_->start <= $target_region_end }
                @{ $transcript->get_all_Exons };
    }
    return \@floxed_exons;
}

1;

__END__
