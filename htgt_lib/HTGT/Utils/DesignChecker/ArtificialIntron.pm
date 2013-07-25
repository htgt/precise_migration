package HTGT::Utils::DesignChecker::ArtificialIntron;

=head1 NAME

HTGT::Utils::DesignChecker::ArtificialIntron

=head1 DESCRIPTION

Collection of design checks relating to the artificial intron designs.

=cut

use Moose;
use namespace::autoclean;

use List::MoreUtils qw( any none );
use Try::Tiny;
use Const::Fast;

with 'HTGT::Utils::DesignCheckRole';
with 'HTGT::Role::EnsEMBL';

sub _build_check_type {
    return 'artificial_intron';
}

has features => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has strand => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
    required => 1,
);

=head2 _build_checks

Populate the checks array of the parent class

=cut
sub _build_checks {
    my $self = shift;

    if ( $self->is_artificial_intron_design ) {
        #art intron specific checks
        return [ 
            'design_marked_artificial_intron',
            'u5_u3_oligos_adjacent',
            'end_phase_target_region_not_zero',
            'insertion_point_boundary_correct',
        ];
    }
    elsif ( $self->is_intron_replacement_design ) {
        #intron replacement specific checks
        return [ 
            'design_marked_artificial_intron',
            'design_marked_intron_replacement',
        ];
    }
    else {
        $self->log->debug('Not artificial intron design');
        #a single test to make sure the design isn't art intron
        return [ 'design_not_art_intron', ];
    };
}

=head2 incorrectly_marked_art_intron_design

Make sure this design is not art-intron (i.e. skip art intron checks on non art-intron designs) 

=cut
sub design_not_art_intron {
    my $self = shift;

    if ( $self->design->is_artificial_intron || $self->design->is_intron_replacement ) {
        $self->set_status( 'incorrectly_marked_artificial_intron_design' );
        return;
    }

    return 1;
}

=head2 is_artificial_intron_design

Check if a design is a artificial intron design by seeing if the U5 and U3
oligos are within the same exon.

=cut
sub is_artificial_intron_design {
    my $self = shift;

    return if !$self->design->design_type || $self->design->design_type =~ /^(Ins|Del)/;

    return unless exists $self->features->{U5} && exists $self->features->{U3};

    my $u5_exons = $self->_get_oligo_exons( $self->features->{U5} );
    my $u3_exons = $self->_get_oligo_exons( $self->features->{U3} );

    if ( %{ $u5_exons } && %{ $u3_exons } ) {
        if ( any { exists $u3_exons->{$_} } keys %{ $u5_exons } ) {
            $self->log->debug("Is artificial intron design");
            return 1;
        }
    }

    return;
}

=head2 is_intron_replacement_design

Check if a design is a intron replacement design by seeing if the U5 and U3
oligos are within different exon.

=cut
sub is_intron_replacement_design {
    my $self = shift;

    return if !$self->design->design_type || $self->design->design_type =~ /^(Ins|Del)/;

    return unless exists $self->features->{U5} && exists $self->features->{U3};

    # U5 and U3 overlap different exons ( start and end of )
    my $u5_exons = $self->_get_oligo_exons( $self->features->{U5} );
    my $u3_exons = $self->_get_oligo_exons( $self->features->{U3} );

    if ( %{ $u5_exons } && %{ $u3_exons } ) {
        if ( none { exists $u3_exons->{$_} } keys %{ $u5_exons } ) {
            $self->log->debug("Is intron replacement design");
            return 1;
        }
    }

    return;
}

=head2 _get_oligo_exons

Return hashref of exons a design oligo lies across.
Hashref is keyed on the stable id of a exon, the value is a Bio::EnsEMBL::Exon

=cut
sub _get_oligo_exons {
    my ( $self, $oligo ) = @_;

    my $oligo_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome',
        $oligo->chromosome->name,
        $oligo->feature_start,
        $oligo->feature_end,
        $oligo->feature_strand,
    );

    my @exons = @{ $oligo_slice->get_all_Exons }; 
    return {} unless @exons;

    my @transcripts = grep{ $_->biotype eq 'protein_coding' } @{ $oligo_slice->get_all_Transcripts };

    my @coding_exons;
    for my $tran ( @transcripts ) {
        my @transcript_exons = map{ $_->stable_id } @{ $tran->get_all_Exons };

        for my $exon ( @exons ) {
            # is exon on this transcript
            next if none { $_ eq $exon->stable_id } @transcript_exons;

            push @coding_exons, $exon
                if $self->_is_coding_exon( $exon, $tran );
        }
    }

    return { } unless @coding_exons;

    return { map{ $_->stable_id => $_ } @coding_exons };
}

=head2 _is_coding_exon

Given a exon and a transcript check the exon is coding, with relation to the transcript.

=cut
sub _is_coding_exon {
    my ( $self, $exon, $transcript ) = @_;

    my $coding_start = try{ $exon->cdna_coding_start( $transcript ) };

    return 1 if $coding_start;
    return;
}

=head2 design_marked_artificial_intron

Check if a design is marked as artificial intron in htgt, if not it should be.

=cut
sub design_marked_artificial_intron {
    my $self = shift;

    unless ( $self->design->is_artificial_intron ) {
        $self->set_status('design_not_marked_artificial_intron');
        return;
    }

    return 1;
}

=head2 design_marked_intron_replacement

Check if a design is marked as intron replacement in htgt, if not it should be.

=cut
sub design_marked_intron_replacement {
    my $self = shift;

    unless ( $self->design->is_intron_replacement ) {
        $self->set_status('design_not_marked_intron_replacement');
        return;
    }

    return 1;
}

=head2 u5_u3_oligos_adjacent

For artificial designs the U5 and U3 oligos should lie next to each other.

=cut
sub u5_u3_oligos_adjacent {
    my $self = shift;

    if ( $self->strand == 1 ) {
        if ( $self->features->{U5}->feature_end != ( $self->features->{U3}->feature_start - 1 ) ) {
            $self->set_status('u5_u3_oligos_not_adjacent');
            return;
        }
    }
    else {
        if ( $self->features->{U3}->feature_end != ( $self->features->{U5}->feature_start - 1 ) ) {
            $self->set_status('u5_u3_oligos_not_adjacent');
            return;
        }
    }

    return 1;
}

=head2 end_phase_target_region_not_zero 

For artificial designs that target part of a exon AND another exon further down check
the number of coding bases that would be removed is not divisibly by 3 ( we do induce a frame shift )

=cut
sub end_phase_target_region_not_zero {
    my $self = shift;

    #check we have a design that targets more than one exon
    my @exons = @{ $self->target_slice->get_all_Exons };
    return 1 if scalar(@exons) == 1;

    my %transcript_phases;
    my @transcripts = @{ $self->target_slice->get_all_Transcripts };
    for my $transcript ( @transcripts ) {
        next unless $transcript->translation;
        my $phase = $self->_get_targeted_region_end_phase( $transcript );
        $transcript_phases{ $transcript->stable_id } = $phase;
    }

    my @phase_zero_transcripts = grep{ $transcript_phases{$_} == 0 } keys %transcript_phases;

    if ( @phase_zero_transcripts ) {
        $self->set_status('end_phase_target_region_is_zero'
            , [ map{ "Transcript $_ has target region end phase of 0" } @phase_zero_transcripts ] );
        return;
    }

    return 1;
}

=head2 _get_targeted_region_end_phase 

Work out number of coding bases within the target region then %3 to get the phase

=cut
sub _get_targeted_region_end_phase {
    my ( $self, $transcript ) = @_;
    
    # transfer transcript to chromosome coordinate system ( it was target slice )
    $transcript = $transcript->transform( 'chromosome' );

    my $coding_bases = 0;
    if ( $transcript->strand == 1 ) {
        my $cs = $self->features->{U5}->feature_end; # cassette start
        my $ls = $self->features->{D5}->feature_end; # loxp start

        for my $e ( @{ $transcript->get_all_Exons } ){
            next unless $e->coding_region_start( $transcript );
            # not interested in exons before the targetted exon
            next if $e->seq_region_end < $cs;
            # exons after loxp insertion we skip
            next if $e->seq_region_start > $ls;

            my $bases;
            if ( $e->seq_region_start > $cs ){
                $coding_bases
                    += $e->coding_region_end( $transcript ) - $e->coding_region_start( $transcript ) + 1;
            }
            # exon is split by art intron cassette
            else {
                $coding_bases += $e->coding_region_end( $transcript ) - $cs;
            }
        }
    }
    else{
        my $ce = $self->features->{U5}->feature_start; # cassette end
        my $le = $self->features->{D5}->feature_start; # loxp end

        for my $e ( @{ $transcript->get_all_Exons } ){
            next unless $e->coding_region_start( $transcript );
            # not interested in exons before targeted exon
            next if $e->seq_region_start > $ce;
            # exons after loxp insertion we skip
            next if $e->seq_region_end < $le;

            if ( $e->seq_region_end < $ce ){
                $coding_bases
                    += $e->coding_region_end( $transcript ) - $e->coding_region_start( $transcript ) + 1;
            }
            # exon is split my art intron cassette
            else{
                $coding_bases +=  $ce - $e->coding_region_start( $transcript );
            }
        }
    }
    return $coding_bases %3;
}

=head2 insertion_point_boundary_correct 

Check insertion point of cassette into exon is AG|G or AG|A

=cut
sub insertion_point_boundary_correct {
    my $self = shift;

    my ( $start, $end );
    if ( $self->strand == 1 ) {
        $start = $self->features->{U5}->feature_end - 1;
        $end   = $self->features->{U3}->feature_start;
    }
    else {
        $start = $self->features->{U3}->feature_end;
        $end   = $self->features->{U5}->feature_start + 1;
    }
    
    my $boundary_slice = $self->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->design->info->chr_name,
        $start,
        $end,
        $self->strand,
    );

    my $seq = $boundary_slice->seq;

    if ( $seq !~ /^AG[G|A]$/ ) {
        $self->set_status('boundary_sequence_not_correct', [ "Boundary sequence is $seq" ]);
        return;
    }

    return 1;
}

1;

__END__
