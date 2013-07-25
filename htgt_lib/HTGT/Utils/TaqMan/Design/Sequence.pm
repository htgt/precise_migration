package HTGT::Utils::TaqMan::Design::Sequence;

use Moose::Role;
use namespace::autoclean;
use HTGT::Utils::EnsEMBL;
use Const::Fast;
use List::MoreUtils qw( uniq );
use CSV::Writer;
use File::Temp qw( tempfile );
use Bio::SeqIO;
use Bio::Seq;
use Try::Tiny;

const my @OUT_DELETED_COLUMNS => qw(
    marker_symbol
    design_id
    has_primer
    sponsor
    chromosome
    strand
    design_type
    u_5_flank
    u_deleted
    u_3_flank
    d_5_flank
    d_deleted
    d_3_flank
    5_flank
    deleted
    3_flank
);

const my @OUT_CRITICAL_COLUMNS => qw(
    marker_symbol
    design_id
    has_primer
    sponsor
    chromosome
    strand
    design_type
    5_flank
    critical
    3_flank
);

has flank_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 150,
);

has slice_adaptor => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::DBSQL::SliceAdaptor',
    lazy_build => 1,
);

has csv => (
    is => 'ro',
    isa => 'CSV::Writer',
    lazy_build => 1,
);

sub _build_csv {
    my $self = shift;

    my @out_columns = $self->target eq 'deleted'  ? @OUT_DELETED_COLUMNS
                    : $self->target eq 'critical' ? @OUT_CRITICAL_COLUMNS
                    :                               '';

    my $csv = CSV::Writer->new(
        columns => \@out_columns, output => $self->temp_output_files->{csv} );
    $csv->write(@out_columns);

    return $csv;
}

has fasta => (
    is => 'ro',
    isa => 'Bio::SeqIO',
    lazy_build => 1,
);

sub _build_fasta {
    my $self = shift;

    return Bio::SeqIO->new(
        -fh     => $self->temp_output_files->{fasta},
        -format => 'fasta'
    );
}

sub _build_slice_adaptor {
    my $self = shift;

    return HTGT::Utils::EnsEMBL->slice_adaptor;
}

sub _build_temp_output_files {
    my $self = shift;

    my $fasta_file = File::Temp->new() or die "Unable to create fasta tmp file: $!";
    my $csv_file   = File::Temp->new() or die "Unable to create csv tmp file: $!";

    return { csv => $csv_file, fasta => $fasta_file };
}

sub get_taqman_design_info {
    my ( $self, $data )= @_;

    my $design_ids = $self->get_designs( $data );

    foreach my $design_id ( @{ $design_ids } ) {
        my $data = $self->get_taqman_target_data( $design_id )
            or return;

        $self->create_csv_output( $data );
        $self->create_fasta_output( $data ) unless $data->{has_primer};
    }
}

sub fetch_wildtype_critical_data {
    my ( $self, $data, $features ) = @_;

    if ( $data->{strand} == 1 ) {
        @{ $data }{ ( '5_flank', $self->target, '3_flank' ) } = $self->get_target_sequences_plus(
            $data,
            $self->coordinates_plus( 'U3', 'D5', $features )
        );
    }
    else {
        @{ $data }{ ( '5_flank', $self->target, '3_flank' ) } = $self->get_target_sequences_minus(
            $data,
            $self->coordinates_minus( 'U3', 'D5', $features )
        );
    }
}

sub fetch_wildtype_deleted_data {
    my ( $self, $data, $features ) = @_;

    if ( $data->{strand} == 1 ) {
        @{ $data }{ ( 'u_5_flank', 'u_deleted', 'u_3_flank' ) } = $self->get_target_sequences_plus(
            $data,
            $self->coordinates_plus( 'U5', 'U3', $features )
        );
        @{ $data }{ ( 'd_5_flank', 'd_deleted', 'd_3_flank' ) } = $self->get_target_sequences_plus(
            $data,
            $self->coordinates_plus( 'D5', 'D3', $features )
        );
    }
    else {
        @{ $data }{ ( 'u_5_flank', 'u_deleted', 'u_3_flank' ) } = $self->get_target_sequences_minus(
            $data,
            $self->coordinates_minus( 'U5', 'U3', $features )
        );
        @{ $data }{ ( 'd_5_flank', 'd_deleted', 'd_3_flank' ) } = $self->get_target_sequences_minus(
            $data,
            $self->coordinates_minus( 'D5', 'D3', $features )
        );
    }
}

sub fetch_wildtype_data_non_KO_design {
    my ( $self, $data, $features ) = @_;

    if ( $data->{strand} == 1 ) {
        @{ $data }{ ( '5_flank', $self->target, '3_flank' ) } = $self->get_target_sequences_plus(
            $data,
            $self->coordinates_plus( 'U5', 'D3', $features )
        );
    }
    else {
        @{ $data }{ ( '5_flank', $self->target, '3_flank' ) } = $self->get_target_sequences_minus(
            $data,
            $self->coordinates_minus( 'U5', 'D3', $features )
        );
    }
}

sub get_target_sequences_plus {
    my ( $self, $data, $c ) = @_;
    my ( $five_prime_oligo_end, $three_prime_oligo_start );

    # only fetch flanking sequence if oligoes next to each other
    my $target_slice_seq = '';
    if ( $c->{end} ne '-' ) {
        my $target_slice = $self->slice_adaptor->fetch_by_region(
            'chromosome', $data->{chromosome},
            $c->{start},
            $c->{end},
            $data->{strand}
        );
        $target_slice_seq = $target_slice->seq;

        $five_prime_oligo_end     = $c->{start} - 1;
        $three_prime_oligo_start = $c->{end} + 1;
    }
    else {
        $five_prime_oligo_end    = $c->{start};
        $three_prime_oligo_start = $c->{start} + 1;
    }

    my $five_prime_flank_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome', $data->{chromosome},
        $five_prime_oligo_end - $self->flank_size,
        $five_prime_oligo_end,
        $data->{strand}
    );
    my $three_prime_flank_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome', $data->{chromosome},
        $three_prime_oligo_start,
        $three_prime_oligo_start + $self->flank_size,
        $data->{strand}
    );

    return ( $five_prime_flank_slice->seq, $target_slice_seq, $three_prime_flank_slice->seq );
}

sub get_target_sequences_minus {
    my ( $self, $data, $c ) = @_;
    my ( $five_prime_oligo_end, $three_prime_oligo_start );

    # only fetch flanking sequence if oligoes next to each other
    my $target_slice_seq = '';
    if ( $c->{end} ne '-' ) {
        my $target_slice = $self->slice_adaptor->fetch_by_region(
            'chromosome', $data->{chromosome},
            $c->{start},
            $c->{end},
            $data->{strand}
        );
        $target_slice_seq = $target_slice->seq;

        $three_prime_oligo_start = $c->{start} - 1;
        $five_prime_oligo_end    = $c->{end} + 1;
    }
    else {
        $three_prime_oligo_start = $c->{start};
        $five_prime_oligo_end    = $c->{start} + 1;
    }


    my $five_prime_flank_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome', $data->{chromosome},
        $five_prime_oligo_end,
        $five_prime_oligo_end + $self->flank_size,
        $data->{strand}
    );
    my $three_prime_flank_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome', $data->{chromosome},
        $three_prime_oligo_start - $self->flank_size,
        $three_prime_oligo_start,

        $data->{strand}
    );

    return ( $five_prime_flank_slice->seq, $target_slice_seq, $three_prime_flank_slice->seq );
}

sub create_csv_output {
    my ( $self, $taqman_data ) = @_;

    $self->csv->write($taqman_data);
}

sub create_fasta_output {
    my ( $self, $data ) = @_;

    if ( $self->target eq 'critical' ) {
        $self->_create_fasta_output( $data, 'critical' );
    }
    elsif ( $data->{design_type} =~ /KO/ ) { # deleted target, KO design
        $self->_create_fasta_output( $data, 'deleted', $_ ) for qw( u d );
    }
    else { # deleted target, non KO design
        $self->_create_fasta_output( $data, 'deleted' );
    }
}

sub _create_fasta_output {
    my ( $self, $data, $target, $append ) = @_;

    my $id = $data->{marker_symbol} eq '' ? $data->{marker_symbol} : $data->{design_id};
    my $display_id  = $append ? $id     . '_' . $append : $id;

    my $five_flank  = $append ? $append . '_5_flank'    : '5_flank';
    my $three_flank = $append ? $append . '_3_flank'    : '3_flank';
    my $target_name = $append ? $append . '_' . $target : $target;

    my $seq     = $data->{$five_flank} . $data->{$target_name} . $data->{$three_flank};
    my $seq_obj = Bio::Seq->new(
        -display_id => $display_id,
        -seq        => $seq,
        -alphabet   => 'dna'
    );
    $self->fasta->write_seq($seq_obj);
}

1;

__END__

