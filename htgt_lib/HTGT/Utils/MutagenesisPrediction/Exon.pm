package HTGT::Utils::MutagenesisPrediction::Exon;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use List::Util qw( max min );
require UNIVERSAL;

class_type 'Bio::EnsEMBL::Exon';
class_type 'HTGT::Utils::MutagenesisPrediction::PartExon';

has ensembl_exon => (
    is  => 'ro',
    isa => 'Bio::EnsEMBL::Exon | HTGT::Utils::MutagenesisPrediction::PartExon',
    handles => {
        seq => 'seq'
    },
    required => 1
);

has [ qw( cdna_start cdna_end ) ] => (
    is       => 'rw',
    isa      => 'Int',
    required => 1
);

with 'MooseX::Log::Log4perl';

sub is_coding {
    my ( $self, $orf ) = @_;
    $self->_assert_is_orf( $orf );

    defined $self->cdna_coding_start( $orf ) ? 1 : 0;
}

sub cdna_coding_start {
    my ( $self, $orf ) = @_;
    $self->_assert_is_orf( $orf );

    my $s = max( $self->cdna_start, $orf->cdna_coding_start );

    if ( $s <= min( $self->cdna_end, $orf->cdna_coding_end ) ) {
        return $s;
    }
    else {
        return;
    }
}

sub cdna_coding_end {
    my ( $self, $orf ) = @_;
    $self->_assert_is_orf( $orf );

    my $e = min( $self->cdna_end, $orf->cdna_coding_end );

    if ( $e >= max( $self->cdna_start, $orf->cdna_coding_start ) ) {
        return $e;
    }
    else {
        return;        
    }
}

sub phase {
    my ( $self, $orf ) = @_;
    $self->_assert_is_orf( $orf );

    if ( $orf->cdna_coding_start > $self->cdna_end ) {
        return -1;
    }
    elsif ( $orf->cdna_coding_end < $self->cdna_start ) {
        return -1;
    }
    elsif ( $self->cdna_start < $orf->cdna_coding_start ) {
        return -1;
    }
    else {
        return ( $self->cdna_start - $orf->cdna_coding_start ) % 3;
    }
}

sub end_phase {
    my ( $self, $orf ) = @_;

    $self->_assert_is_orf( $orf );

    if ( $orf->cdna_coding_start > $self->cdna_end ) {
        return -1;
    }
    elsif ( $orf->cdna_coding_end < $self->cdna_start ) {
        return -1;
    }
    elsif ( $orf->cdna_coding_end < $self->cdna_end ) {
        return -1;
    }
    else {
        return ( $self->cdna_coding_end( $orf ) - $orf->cdna_coding_start + 1 ) % 3;
    }
    
}

sub is_in_phase {
    my ( $self, $orf ) = @_;
    $self->_assert_is_orf( $orf );

    my $phase      = $self->phase( $orf );
    my $orig_phase = $self->ensembl_exon->phase;

    return $phase >= 0 and $phase == $orig_phase;
}

sub translation {
    my ( $self, $orf ) = @_;

    $self->_assert_is_orf( $orf );

    return unless $self->is_coding( $orf );
    my $start_offset = $self->phase( $orf ) > 0 ? $self->phase( $orf ) : 0;
    my $start  = $self->cdna_coding_start( $orf ) - $start_offset - $orf->cdna_coding_start;
    
    my $end_offset = $self->end_phase( $orf ) > 0 ? 3 - $self->end_phase( $orf ) : 0;
    my $end = $self->cdna_coding_end( $orf ) + $end_offset - $orf->cdna_coding_start + 1;

    $self->log->debug ( $self->ensembl_exon->stable_id . ": ORF phase: " . $self->phase( $orf ) );
    $self->log->debug ( $self->ensembl_exon->stable_id . ": ORF cDNA coding start: " . $orf->cdna_coding_start );
    $self->log->debug ( $self->ensembl_exon->stable_id . ": exon cDNA coding start for ORF: " . $self->cdna_coding_start( $orf ) );
    $self->log->debug ( $self->ensembl_exon->stable_id . ": ORF end phase: " . $self->end_phase( $orf ) );
    $self->log->debug ( $self->ensembl_exon->stable_id . " ORF cDNA coding end: " . $orf->cdna_coding_end );
    $self->log->debug ( $self->ensembl_exon->stable_id . ": exon cDNA coding end for ORF: " . $self->cdna_coding_end( $orf ) );
    $self->log->debug ( $self->ensembl_exon->stable_id . ": ORF translation length: " . $orf->translation->length );

    my $aa_start = ( $start / 3 ) + 1;
    my $aa_end   = min( $end / 3, $orf->translation->length );
    
    $self->log->debug( $self->ensembl_exon->stable_id . " translation is from $aa_start to $aa_end" );
    
    $orf->translation->trunc( $aa_start, $aa_end );
}

sub _assert_is_orf {
    my ( $self, $maybe_orf ) = @_;
    
    confess "expected HTGT::Utils::MutagenesisPrediction::ORF"
        unless defined $maybe_orf
            and UNIVERSAL::isa( $maybe_orf, 'HTGT::Utils::MutagenesisPrediction::ORF' );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
