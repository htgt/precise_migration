package HTGT::Utils::DesignQcReports::TaqmanIDs;

use Moose;
use namespace::autoclean;
use Const::Fast;
use Try::Tiny;

extends 'HTGT::Utils::DesignQcReports';


sub _build_column_names {
    return [ qw( 
        design_id marker_symbol assay_id well 
        deleted_region forward_primer_seq 
        reverse_primer_seq reporter_probe_seq
    ) ];
}

sub get_data_for_design {
    my ( $self, $design ) = @_;
    my @taqman_data;
    my $design_id = $design->design_id;
    my $marker_symbol;
    try {
        $marker_symbol = $design->info->mgi_gene->marker_symbol;
    }
    catch {
        $marker_symbol = '-';
    };

    my $taqman_assay_rs = $design->taqman_assays;
    unless ( $taqman_assay_rs->count ) {
        my %d;
        $d{design_id}     = $design_id;
        $d{marker_symbol} = $marker_symbol;
        push @taqman_data, \%d;
    }

    while ( my $taqman = $taqman_assay_rs->next ) {
        my %d;
        $d{design_id}     = $design_id;
        $d{marker_symbol} = $marker_symbol;

        map { $d{$_} = $taqman->$_ }
            qw( assay_id deleted_region forward_primer_seq reverse_primer_seq reporter_probe_seq );

        my $taqman_plate = $taqman->taqman_plate;
        $d{plate} = $taqman_plate->name;
        $d{well}  = $taqman_plate->name . '_' . $taqman->well_name;
        push @taqman_data, \%d;
    }

    return \@taqman_data;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
