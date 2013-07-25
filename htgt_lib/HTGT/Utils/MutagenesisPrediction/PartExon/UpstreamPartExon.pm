package HTGT::Utils::MutagenesisPrediction::PartExon::UpstreamPartExon;

use Moose;
use namespace::autoclean;
use HTGT::Utils::EnsEMBL;
use Bio::Seq;
use Bio::Location::Simple;
use HTGT::Utils::DesignPhase qw ( get_phase_from_transcript_id_and_U5_oligo
                            create_U5_oligo_loc_from_cassette_coords );
use POSIX qw( ceil );

extends 'HTGT::Utils::MutagenesisPrediction::PartExon';


has is_coding => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

has phase => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

has end_phase => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_is_coding{
    my $self = shift;

    my $cr_start = $self->full_exon->coding_region_start( $self->transcript )
        or return 0;
    
    if ( $self->strand == 1 ){
        return 0 if $cr_start > ( $self->start + $self->length - 1 );
    }
    else{
        return 0 if $cr_start < ( $self->end - $self->length + 1 );
    }
    return 1;
}

sub _build_phase{
    my ( $self ) = @_;

    return $self->full_exon->phase;
}

sub _build_end_phase{
    my $self = shift;

    # We are calculating the end phase for the upstream part of the split exon
    # by calculating the start phase of the floxed part, hence the difference
    # between this method and the equivalent method in FloxedPartExon.pm
    my $cass_border_left = $self->strand == 1 ? $self->end : $self->start - 1;
    my $cass_border_right = $cass_border_left + 1;

    my $u5_oligo_loc = create_U5_oligo_loc_from_cassette_coords(
            $cass_border_left, $cass_border_right, $self->strand );

    return get_phase_from_transcript_id_and_U5_oligo( $self->transcript, $u5_oligo_loc );
}

sub coding_region_start{
    my ( $self, $transcript ) = @_;

    return unless $self->is_coding;

    return $self->full_exon->coding_region_start( $transcript );
}

sub cdna_end{
    my ( $self, $transcript ) = @_;

    return unless $self->full_exon->cdna_end( $transcript );

    my $new_cdna_end = $self->full_exon->cdna_end( $transcript ) - $self->other_part_length;

    return unless $new_cdna_end >= $self->full_exon->cdna_start( $transcript );

    return $new_cdna_end;
}

sub peptide{
    my ( $self, $transcript ) = @_;

    unless ( $self->full_exon->coding_region_start( $transcript ) ){
        return Bio::Seq->new(
            -seq      => '',
            -moltype  => 'protein',
            -alphabet => 'protein',
            -id       => $self->stable_id
        );
    }

    my $full_exon_peptide = $self->full_exon->peptide( $transcript );
    my $coding_start_to_end;
    if ( $self->strand == 1 ){
        $coding_start_to_end = $self->full_exon->end - $self->full_exon->coding_region_start( $transcript ) + 1;
    }
    else{
        $coding_start_to_end = $self->full_exon->coding_region_end( $transcript ) - $self->full_exon->start + 1;
    }
    my $new_coding_length = $coding_start_to_end - $self->other_part_length;
    my $aa_required = ceil( $new_coding_length / 3 );
    my $new_peptide_seq = substr $full_exon_peptide->seq, 0, $aa_required;

    return Bio::Seq->new(
        -seq      => $new_peptide_seq,
        -moltype  => 'protein',
        -alphabet => 'protein',
        -id       => $self->stable_id,
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
