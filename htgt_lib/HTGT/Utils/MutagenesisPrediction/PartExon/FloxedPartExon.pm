package HTGT::Utils::MutagenesisPrediction::PartExon::FloxedPartExon;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignPhase qw ( get_phase_from_transcript_id_and_U5_oligo
                            create_U5_oligo_loc_from_cassette_coords);
use POSIX qw( ceil );
use Bio::Location::Simple;
use List::Util qw( max min );

extends 'HTGT::Utils::MutagenesisPrediction::PartExon';

has fivep_edge_is_coding => (
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

sub _build_fivep_edge_is_coding{
    my $self = shift;

    my $cr_start = $self->full_exon->coding_region_start( $self->transcript )
        or return 0;
    if ( $self->strand == 1 ){
        return 0 if $cr_start > $self->start;
    }
    else{
        return 0 if $cr_start < $self->end;
    }
    return 1;
}

sub _build_phase{
    my ( $self ) = @_;

    my $cass_border_left = $self->strand == 1 ? $self->start - 1 : $self->end;
    my $cass_border_right = $cass_border_left + 1;
    my $u5_oligo_loc = create_U5_oligo_loc_from_cassette_coords(
        $cass_border_left, $cass_border_right, $self->strand );

    return get_phase_from_transcript_id_and_U5_oligo( $self->transcript, $u5_oligo_loc );
}

sub _build_end_phase{
    my ( $self ) = @_;

    return $self->full_exon->end_phase;
}

sub peptide{
    my ( $self, $transcript ) = @_;

    my $full_exon_peptide = $self->full_exon->peptide( $transcript );

    return $full_exon_peptide unless $self->fivep_edge_is_coding;

    my $floxed_part_coding_length;

    if ( $self->strand == 1 ){
        $floxed_part_coding_length = $self->full_exon->coding_region_end( $transcript ) - $self->start + 1;
    }
    else{
        $floxed_part_coding_length = $self->end - $self->full_exon->coding_region_start( $transcript ) + 1;
    }

    my $new_peptide_seq;
    if ( $floxed_part_coding_length < 0 ){
        $new_peptide_seq = '';
    }
    else{
        my $aa_required = ceil( $floxed_part_coding_length / 3 );
        my $full_exon_peptide_length = length( $full_exon_peptide->seq );
        if ( $aa_required > $full_exon_peptide_length ){
            $aa_required = $full_exon_peptide_length;
        }
        $new_peptide_seq = substr $full_exon_peptide->seq, -$aa_required;
    }

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
