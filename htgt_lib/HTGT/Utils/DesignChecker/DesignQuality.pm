package HTGT::Utils::DesignChecker::DesignQuality;

=head1 NAME

HTGT::Utils::DesignChecker::DesignQuality

=head1 DESCRIPTION

Collection of design checks relating to the quality of the design.

=cut

use Moose;
use namespace::autoclean;

use List::MoreUtils qw( none );
use Try::Tiny;
use Const::Fast;

with 'HTGT::Utils::DesignCheckRole';

sub _build_check_type {
    return 'design_quality';
}

=head2 _build_checks

Populate the checks array of the parent class

=cut
sub _build_checks {
    my $self = shift;

    return [
        'genes_in_target_region',
        'exons_in_target_region',
        'coding_exons',
        'check_target_region_length',
    ];
}

=head2 genes_in_target_region

Check there are genes in the target region of the design, according to Ensembl.

=cut
sub genes_in_target_region{
    my $self = shift;

    my @genes = grep{ $_->biotype eq 'protein_coding' } @{ $self->target_slice->get_all_Genes };

    unless ( @genes ) {
        $self->set_status( 'no_genes_in_target_region' );
        return;
    }
    
    $self->log->debug( 'Genes on target slice: ' . join(' ', map{ $_->stable_id } @genes) );

    return 1;
}

=head2 exons_in_target_region

Check there are exons in the target region, even if the target region hits a gene,
it may be the intron part of the genes transcripts.

=cut
sub exons_in_target_region {
    my $self = shift;

    my @exons = @{ $self->target_slice->get_all_Exons };
    unless ( @exons ) {
        $self->check_introns;
        $self->set_status( 'no_exons_in_target_region' );
        return;
    }

    $self->log->debug( 'Exons on target slice: ' . join( ' ', map{ $_->stable_id } @exons ) );

    return 1;
}

=head2 check_introns

If there are no exons in the target region, find out which introns are hit.

=cut
sub check_introns {
    my $self = shift;

    for my $tran ( @{ $self->target_slice->get_all_Transcripts } ) {
        my @introns = @{ $tran->get_all_Introns };

        for my $intron (@introns) {
            if ((      $intron->seq_region_start <= $self->target_slice->start
                    && $intron->seq_region_end >= $self->target_slice->start )
                || (   $intron->seq_region_start <= $self->target_slice->end
                    && $intron->seq_region_end >= $self->target_slice->end )
                || (   $intron->seq_region_start >= $self->target_slice->start
                    && $intron->seq_region_end <= $self->target_slice->end )
               )
            {
                $self->add_note( 'Transcript ' 
                    . $tran->stable_id . ' ( gene: ' . $tran->get_Gene->stable_id 
                    . ' ) has intron within target region' );
            }
        }
    }
}

=head2 check_introns

For each Transcript check the exons within the target region are coding exons.

=cut
sub coding_exons {
    my $self = shift;

    my @transcripts = @{ $self->target_slice->get_all_Transcripts };
    my @exons = @{ $self->target_slice->get_all_Exons };

    my @coding_exons;
    for my $tran ( @transcripts ) {
        my @transcript_exons = map{ $_->stable_id } @{ $tran->get_all_Exons };

        for my $exon ( @exons ) {
            # is exon on this transcript
            next if none { $_ eq $exon->stable_id } @transcript_exons;

            push @coding_exons, $exon->stable_id
                if $self->_is_coding_exon( $exon, $tran );
        }
    }

    unless ( @coding_exons ) {
        $self->_coding_transcripts( \@transcripts );
        $self->set_status('non_coding_exons');
        return;
    }

    $self->add_note( 'Coding exons: ' . join( ' ', @coding_exons ) );
    return 1;
}

=head2 _is_coding_exon

Given a exon and a transcript check the exon is coding, with relation to the transcript.

=cut
sub _is_coding_exon {
    my ( $self, $exon, $transcript ) = @_;

    my $coding_start = try{ $exon->cdna_coding_start( $transcript ) };
    if ( $coding_start ) {
        $self->log->debug( 'Exon ' . $exon->stable_id . ' has cdna coding region ( on transcript '
                         . $transcript->stable_id . ' )' );
        return 1;
    }
    else {
        $self->log->debug( 'Exon ' . $exon->stable_id . ' is NON coding ( on transcript '
                           . $transcript->stable_id . ' )' );
    }
    
    return;
}

=head2 _coding_transcripts

Add a note if the target region has no coding transcripts overlapping it.

=cut
sub _coding_transcripts {
    my ( $self, $transcripts ) = @_;

    my $coding_transcript;
    for my $tran ( @{ $transcripts } ) {
        if ( $tran->translation ) {
            $self->log->debug( 'Transcript ' . $tran->stable_id . ' is coding' );
            $coding_transcript = 1;
        }
        else {
            $self->log->debug( 'Transcript ' . $tran->stable_id . ' is NON coding' );
        }
    }

    $self->add_note('Target region has no coding transcripts overlapping it')
        unless $coding_transcript;
}

=head2 check_target_region_length

Add a note if the target region length is greated than 10000 base pairs long.

=cut
sub check_target_region_length {
    my $self = shift;

    if ( $self->target_slice->length > 10000 ) {
        $self->add_note( "Target Region length too big: " . $self->target_slice->length );
    }

    return 1;
}

1;

__END__
