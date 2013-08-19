package HTGT::Utils::Design::FindConstrainedElements;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( find_constrained_elements report_constrained_elements ) ]
};

use HTGT::Utils::EnsEMBL;
use Bio::SeqFeature::Generic;

sub find_constrained_elements {
    my ( $chr_name, $chr_start, $chr_end, $chr_strand ) = @_;
    my $slice = HTGT::Utils::EnsEMBL->slice_adaptor->fetch_by_region(
        'chromosome',
        $chr_name,
        $chr_start,
        $chr_end,
        $chr_strand
    );
    my $method_link_species_set_adaptor = Bio::EnsEMBL::Registry->get_adaptor( 'Multi', 'compara', 'MethodLinkSpeciesSet' );
    my $method_link_species_set =
        $method_link_species_set_adaptor->fetch_by_method_link_type_species_set_name( 'GERP_CONSTRAINED_ELEMENT', 'mammals' );

    my $constrained_element_adaptor = HTGT::Utils::EnsEMBL->constrained_element_adaptor;

    [
        map Bio::SeqFeature::Generic->new(
            -start       => $chr_start + $_->start - 1,
            -end         => $chr_start + $_->end - 1,
            -strand      => $chr_strand,
            -score       => $_->score,
            -primary_tag => 'misc_feature',            
        ), @{ $constrained_element_adaptor->fetch_all_by_MethodLinkSpeciesSet_Slice( $method_link_species_set, $slice ) }
    ];
}

sub report_constrained_elements {
    my ( $chr_name, $chr_start, $chr_end, $chr_strand ) = @_;

    my $constrained_elements = find_constrained_elements( $chr_name, $chr_start, $chr_end, $chr_strand );

    return unless @{ $constrained_elements };

    print "Constrained elements found in region $chr_name:$chr_start-$chr_end\n";
    for my $c ( @$constrained_elements ) {
        print join( "\t", $c->start, $c->end, $c->score ) . "\n";        
    }
}

1;

__END__
