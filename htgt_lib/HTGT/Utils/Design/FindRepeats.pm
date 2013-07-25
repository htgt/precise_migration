package HTGT::Utils::Design::FindRepeats;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( find_repeats report_repeats ) ]
};

use HTGT::Utils::EnsEMBL;

sub find_repeats {
    my ( $chr_name, $chr_start, $chr_end, $chr_strand ) = @_;

    my $slice = HTGT::Utils::EnsEMBL->slice_adaptor->fetch_by_region(
        'chromosome',
        $chr_name,
        $chr_start,
        $chr_end,
        $chr_strand,
    );

    my $repeat_adaptor = HTGT::Utils::EnsEMBL->repeat_feature_adaptor;

    [
        map $_->transform('chromosome'), @{ $repeat_adaptor->fetch_all_by_Slice( $slice ) }
    ];
}

sub report_repeats {
    my ( $chr_name, $chr_start, $chr_end, $chr_strand ) = @_;

    my $repeats = find_repeats( $chr_name, $chr_start, $chr_end, $chr_strand );

    return unless @{ $repeats };

    print "Repeats found in region $chr_name:$chr_start-$chr_end\n";
    for my $r ( map $_->transform( 'chromosome' ), @$repeats ) {
        my $c = $r->repeat_consensus;
        print join( "\t", '', $r->display_id, $r->feature_Slice->seq_region_name,
                    $r->start, $r->end, $r->score, $c->repeat_class, $c->repeat_type ) . "\n";
    }
}

1;

__END__
