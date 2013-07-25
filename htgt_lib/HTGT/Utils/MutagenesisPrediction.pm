package HTGT::Utils::MutagenesisPrediction;

use Moose;
use namespace::autoclean;
use HTGT::Utils::MutagenesisPrediction::Error;
use HTGT::Utils::MutagenesisPrediction::Constants;
use HTGT::Utils::MutagenesisPrediction::Transcript;
use HTGT::Utils::MutagenesisPrediction::PartExon::UpstreamPartExon;
use HTGT::Utils::MutagenesisPrediction::PartExon::FloxedPartExon;
use List::MoreUtils qw( firstval lastval );

has target_gene => (
    is       => 'ro',
    isa      => 'HTGT::Utils::DesignFinder::Gene',
    required => 1,
    handles => {
        target_strand     => 'strand',
        target_chromosome => 'chromosome'
    },
);

has transcript_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has transcript => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignFinder::Transcript',
    init_arg   => undef,
    lazy_build => 1,
);

has target_region_start => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has target_region_end => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has deletes_first_coding_exon => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    traits     => [ 'Bool' ],
    handles    => {
        preserves_first_coding_exon => 'not'
    },
    lazy_build => 1,
);

has deletes_last_exon => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    traits     => [ 'Bool' ],
    handles    => {
        preserves_last_exon => 'not'
    },
    lazy_build => 1,
);

has floxed_transcript => (
    is         => 'ro',
    isa        => 'Maybe[HTGT::Utils::MutagenesisPrediction::Transcript]',
    init_arg   => undef,
    lazy_build => 1,
);

has error => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_error',
    writer    => 'add_error',
);

for ( qw( upstream_exons floxed_exons downstream_exons ) ) {
    has $_ => (
        isa        => 'ArrayRef',
        init_arg   => undef,
        writer     => "_set_$_",
        traits     => [ 'Array' ],
        handles    => {
            "$_"     => 'elements',
            "has_$_" => 'count',
        },
    );
}

has upstream_coding_exons => (
    isa        => 'ArrayRef',
    init_arg   => undef,
    traits     => [ 'Array' ],
    handles    => {
        upstream_coding_exons => 'elements',
    },
    lazy_build => 1,
);

with qw( HTGT::Utils::MutagenesisPrediction::ProteinDomains MooseX::Log::Log4perl );

sub fatal {
    my ( $self, $message ) = @_;

    HTGT::Utils::MutagenesisPrediction::Error->throw(
        message => $message,
    );
}

sub BUILD {
    my $self = shift;

    $self->log->debug( "Analysing transcript " . $self->transcript->stable_id );

    $self->fatal( "target_chromosome must be the same as the transcript chromosome" )
        unless $self->target_chromosome eq $self->transcript->seq_region_name;

    $self->fatal( "target_strand must be the same as the transcript strand" )
        unless $self->target_strand == $self->transcript->strand;
    $self->fatal( $self->target_gene->stable_id . "," . $self->transcript_id . ",target_region_start must be less than target_region_end" )
        unless $self->target_region_start < $self->target_region_end;

    unless ( $self->target_region_start < $self->transcript->end and $self->target_region_end > $self->transcript->start ) {
        $self->log->debug( 'Target region start: ' . $self->target_region_start . ' Target region end: ' .
                               $self->target_region_end . ' Transcript start: ' . $self->transcript->start
                                   . ' Transcript end: ' . $self->transcript->end );
        $self->add_error( "Target region does not overlap transcript" );
        return;
    }

    $self->_partition_exons;

    unless ( $self->transcript->is_complete ) {
        $self->add_error( "No analysis available: incomplete transcript" );
        return;
    }

    unless ( $self->has_upstream_exons  ) {
        $self->add_error( "Design floxes first exon in transcript " . $self->transcript->stable_id );
        return;
    }

    unless ( $self->has_floxed_exons ) {
        $self->add_error( "Design floxes no exons in transcript " . $self->transcript->stable_id );
        return;
    }
}

sub _build_transcript {
    my $self = shift;

    my $transcript_id = $self->transcript_id;

    my $transcript = firstval { $_->stable_id eq $transcript_id } $self->target_gene->all_transcripts
        or $self->fatal( "No such transcript $transcript_id for gene " . $self->target_gene->stable_id );

    return $transcript;
}

sub _partition_exons {
    my $self = shift;

    my ( $upstream, $floxed, $downstream );

    if ( $self->transcript->strand == 1 ) {
        ( $upstream, $floxed, $downstream ) = $self->_partition_exons_fwd;
    }
    else {
        ( $upstream, $floxed, $downstream ) = $self->_partition_exons_rev;
    }

    $self->log->debug( "Upstream exons: "   . join( q{, }, map $_->stable_id, @{$upstream} ) );
    $self->log->debug( "Floxed exons: "     . join( q{, }, map $_->stable_id, @{$floxed} ) );
    $self->log->debug( "Downstream exons: " . join( q{, }, map $_->stable_id, @{$downstream} ) );

    $self->_set_upstream_exons( $upstream );
    $self->_set_floxed_exons( $floxed );
    $self->_set_downstream_exons( $downstream );
}

sub _partition_exons_fwd {
    my $self = shift;

    $self->log->debug( "_partition_exons_fwd" );

    my ( @upstream, @floxed, @downstream, $upstream_part_exon, $floxed_part_exon );

    my @exons = @{ $self->transcript->get_all_Exons };

    for my $exon ( @exons ){
        if ( $exon->start < $self->target_region_start ){
            if ( $exon->end < $self->target_region_start ){
                push @upstream, $exon;
            }
            else{
                ( $upstream_part_exon, $floxed_part_exon ) = $self->split_exon_fwd( $exon );
                push @upstream, $upstream_part_exon;
                push @floxed, $floxed_part_exon;
            }
        }
        elsif ( $exon->start < $self->target_region_end ) {
            push @floxed, $exon;
        }
        else{
            push @downstream, $exon;
        }
    }

    return ( \@upstream, \@floxed, \@downstream );
}

sub _partition_exons_rev {
    my $self = shift;

    $self->log->debug( "_partition_exons_rev" );

    my ( @upstream, @floxed, @downstream, $upstream_part_exon, $floxed_part_exon );

    my @exons = @{ $self->transcript->get_all_Exons };

    for my $exon ( @exons ){
        if ( $exon->end > $self->target_region_end ) {
            if ( $exon->start > $self->target_region_end ) {
                push @upstream, $exon;
            }
            else{
                ( $upstream_part_exon, $floxed_part_exon ) = $self->split_exon_rev( $exon );
                push @upstream, $upstream_part_exon;
                push @floxed, $floxed_part_exon;
            }
        }
        elsif ( $exon and $exon->end > $self->target_region_start ) {
            push @floxed, $exon;
        }
        else {
            push @downstream, $exon;
        }
    }

    return ( \@upstream, \@floxed, \@downstream );
}

sub split_exon_fwd{
    my ( $self, $exon ) = @_;

    my $upstream_part_exon = HTGT::Utils::MutagenesisPrediction::PartExon::UpstreamPartExon->new(
        full_exon  => $exon,
        transcript => $self->transcript,
        start      => $exon->start,
        end        => $self->target_region_start - 1,
        gene       => $self->target_gene,
    );
    my $floxed_part_exon = HTGT::Utils::MutagenesisPrediction::PartExon::FloxedPartExon->new(
        full_exon  => $exon,
        transcript => $self->transcript,
        start      => $self->target_region_start,
        end        => $exon->end,
        gene       => $self->target_gene,
    );

    return ( $upstream_part_exon, $floxed_part_exon );
}

sub split_exon_rev{
    my ( $self, $exon ) = @_;

    my $upstream_part_exon = HTGT::Utils::MutagenesisPrediction::PartExon::UpstreamPartExon->new(
        full_exon  => $exon,
        transcript => $self->transcript,
        start      => $self->target_region_end + 1,
        end        => $exon->end,
        gene       => $self->target_gene,
    );
    my $floxed_part_exon = HTGT::Utils::MutagenesisPrediction::PartExon::FloxedPartExon->new(
        full_exon  => $exon,
        transcript => $self->transcript,
        start      => $exon->start,
        end        => $self->target_region_end,
        gene       => $self->target_gene,
    );

    return ( $upstream_part_exon, $floxed_part_exon );
}

sub _build_upstream_coding_exons {
    my $self = shift;

    my $transcript = $self->transcript;

    [ grep $_->coding_region_start( $transcript ), $self->upstream_exons ];
}

sub exon_5p_utr {
    my ( $self, $exon ) = @_;

    $self->log->debug( "exon_5p_utr: " . $exon->stable_id );

    my $transcript = $self->transcript;

    return $exon->length unless $exon->coding_region_start( $transcript );

    if ( $transcript->strand == 1 ) {
        return $exon->coding_region_start( $transcript ) - $exon->start;
    }
    else {
        return $exon->end - $exon->coding_region_end( $transcript );
    }
}

sub exon_3p_utr {
    my ( $self, $exon ) = @_;

    $self->log->debug( "exon_3p_utr: " . $exon->stable_id );

    my $transcript = $self->transcript;

    return $exon->length unless $exon->coding_region_start( $transcript );

    if ( $transcript->strand == 1 ) {
        $exon->end - $exon->coding_region_end( $transcript );
    }
    else {
        $exon->coding_region_start( $transcript ) - $exon->start;
    }
}

sub _build_deletes_first_coding_exon {
    my $self = shift;

    $self->upstream_coding_exons == 0;
}

sub _build_deletes_last_exon {
    my $self = shift;

    $self->downstream_exons == 0;
}

sub _build_floxed_transcript {
    my $self = shift;

    $self->log->debug( "_build_floxed_transcript" );

    return if $self->has_error;

    my $mutant_transcript = HTGT::Utils::MutagenesisPrediction::Transcript->new(
        $self->upstream_exons,
        $self->downstream_exons,
    );

    $self->_compute_predicted_orf( $mutant_transcript );

    return $mutant_transcript;
}

sub _compute_predicted_orf {
    my ( $self, $mutant_transcript ) = @_;

    $self->log->debug( "_compute_predicted_orf" );

    if ( not defined $self->transcript->cdna_coding_start ) { # original transcript is non-coding
        return $self->_compute_predicted_orf_check_nmd_rescue( $mutant_transcript );
    }
    elsif ( $self->preserves_first_coding_exon ) {
        return $self->_compute_predicted_orf_first_coding_exon_preserved( $mutant_transcript );
    }
    else {
        return $self->_compute_predicted_orf_first_coding_exon_deleted( $mutant_transcript );
    }
}

sub _compute_predicted_orf_first_coding_exon_preserved {
    my ( $self, $mutant_transcript ) = @_;

    $self->log->debug( "_compute_predicted_orf_first_coding_exon_preserved" );

    my $orig_cdna_coding_start = $self->transcript->cdna_coding_start;

    # Ignore upstream ORFs
    my @orfs = grep $_->cdna_coding_start >= $orig_cdna_coding_start, $mutant_transcript->orfs;
    $self->fatal( "No ORFs identified" ) if scalar @orfs == 0;

    my $orf_orig_start = shift @orfs;
    $self->fatal( "unexpected ORF (should have same start as original transcript)" )
        unless $orf_orig_start->cdna_coding_start == $orig_cdna_coding_start;

    # If the last exon of the original transcript is deleted (so the
    # stop and polyA signal are lost), we have a residual N-terminal
    # and unknown C-terminal
    if ( $self->deletes_last_exon ) {
        $mutant_transcript->set_predicted_orf( $orf_orig_start );
        $mutant_transcript->set_description( "Residual N-terminal, unknown C-terminal" );
        return;
    }

    # If the ORF with the same start as the original transcript is >= $MIN_TRANSLATION_LENGTH aa, this
    # is the predicted ORF
    if ( $orf_orig_start->translation->length >= $MIN_TRANSLATION_LENGTH ) {
        $mutant_transcript->set_predicted_orf( $orf_orig_start );
        if ( $mutant_transcript->is_nmd ) {
            $mutant_transcript->set_description( "No protein product (NMD)" );
        }
        elsif ( $mutant_transcript->is_frameshift ) {
            $mutant_transcript->set_description( "Residual N-terminal, novel C-terminal product" );
        }
        else {
            $mutant_transcript->set_description( "Residual N-terminal, residual C-terminal product" );
        }
        return;
    }

    # If there are no downstream ORFs with a translation >= $MIN_TRANSLATION_LENGTH aa, there is no protein product
    @orfs = grep $_->translation->length >= $MIN_TRANSLATION_LENGTH, @orfs;
    unless ( @orfs ) {
        $mutant_transcript->set_predicted_orf( $orf_orig_start );
        $mutant_transcript->set_description( "No protein product" );
        return;
    }

    # ...there is at least one downstream ORF producing a product >= $MIN_TRANSLATION_LENGTH aa

    # If any ORF produces the same C-terminal as the original, that's the one we want
    # XXX Is this right? Shouldn't it be the first ORF producing >= $MIN_TRANSLATION_LENGTH aa?
    my $orf_preserving_c_terminal = firstval { $self->_orf_preserves_c_terminal( $mutant_transcript, $_ ) } @orfs;
    if ( $orf_preserving_c_terminal ) {
        $mutant_transcript->set_predicted_orf( $orf_preserving_c_terminal );
        $mutant_transcript->set_description( "Residual C-terminal product" );
        return;
    }

    # Otherwise, it's the first ORF producing >= $MIN_TRANSLATION_LENGTH aa
    $mutant_transcript->set_predicted_orf( shift @orfs );
    if ( $mutant_transcript->is_nmd ) {
        $mutant_transcript->set_description( "No protein product (NMD)" );
    }
    else {
        $mutant_transcript->set_description( "Novel C-terminal product" );
    }
}

sub _compute_predicted_orf_first_coding_exon_deleted {
    my ( $self, $mutant_transcript ) = @_;

    $self->log->debug( "_compute_predicted_orf_first_coding_exon_deleted" );

    my @orfs = grep { $_->translation->length >= $MIN_TRANSLATION_LENGTH } $mutant_transcript->orfs;
    $self->log->debug( @orfs . " ORFs with translation >= $MIN_TRANSLATION_LENGTH" );

    if ( $self->deletes_last_exon ) {
        my @orfs_with_stop = grep /\*$/, @orfs;
        $self->log->debug( @orfs_with_stop . " complete upstream ORFs" );
        if ( @orfs_with_stop ) {
            $mutant_transcript->set_predicted_orf( shift @orfs_with_stop );
            $mutant_transcript->set_description( "Upstream ORF" );
        }
        else {
            $mutant_transcript->set_predicted_orf( shift @orfs ) if @orfs;
            $mutant_transcript->set_description( "No protein product" );
        }
        return;
    }

    # We need this to distinguish upstream from downstream ORFs
    my $last_upstream_exon = ( $self->upstream_exons )[-1];
    my $downstream_start   = $last_upstream_exon->cdna_end( $self->transcript );

    # Look for an ORF that produces a product >= $MIN_TRANSLATION_LENGTH with the same C-terminal as the original
    my @orfs_preserving_c_terminal = grep $self->_orf_preserves_c_terminal( $mutant_transcript, $_ ), @orfs;

    if ( @orfs_preserving_c_terminal ) {
        # Prefer the first downstream ORF
        if ( my $o = firstval { $_->cdna_coding_start >= $downstream_start } @orfs_preserving_c_terminal ) {
            $mutant_transcript->set_predicted_orf( $o );
            $mutant_transcript->set_description( "Residual C-terminal product" );
        }
        else {
            # XXX We're taking the 3'-most ORF here...
            $mutant_transcript->set_predicted_orf( pop @orfs_preserving_c_terminal );
            $mutant_transcript->set_description( "Novel N-terminal, residual C-terminal product" );
        }
        return;
    }

    # If we get this far, we know there is no in-frame start codon; here we're only considering
    # ORFs with translation >= $MIN_TRANSLATION_LENGTH aa

    # ...but there may be none
    unless ( @orfs ) {
        $mutant_transcript->set_description( "No protein product" );
        return;
    }

    # We have at least one ORF with translation >= $MIN_TRANSLATION_LENGTH aa

    # Prefer the first downstream ORF
    if ( my $o = firstval { $_->cdna_coding_start >= $downstream_start } @orfs ) {
        $mutant_transcript->set_predicted_orf( $o );
    }
    else {
        # XXX We're taking the 3'-most ORF here...
        $mutant_transcript->set_predicted_orf( pop @orfs );
    }

    if ( $mutant_transcript->is_nmd ) {
        $mutant_transcript->set_description( "No protein product (NMD)" );
    }
    else {
        $mutant_transcript->set_description( "Novel (out of frame) product" );
    }
}

sub _compute_predicted_orf_check_nmd_rescue {
    my ( $self, $mutant_transcript ) = @_;

    $self->log->debug( "_compute_predicted_orf_check_nmd_rescue" );

    my $orf = firstval { $_->translation->length >= $MIN_TRANSLATION_LENGTH } $mutant_transcript->orfs;

    if ( $orf ) {
        $self->log->debug( "Found ORF >= $MIN_TRANSLATION_LENGTH" );
        $mutant_transcript->set_predicted_orf( $orf );
        if ( !$mutant_transcript->is_nmd( $orf ) ) {
            $self->log->debug( "Found ORF that escapes NMD" );
            $mutant_transcript->set_description( "Possible NMD rescue" );
        }
        else {
            $mutant_transcript->set_description( "No protein product (NMD)" );
        }
    }
    else {
        $mutant_transcript->set_description( "No protein product" );
    }
}

sub _orf_preserves_c_terminal {
    my ( $self, $mutant_transcript, $orf ) = @_;

    $self->log->debug( "_orf_preserves_c_terminal" );

    my $last_coding_exon      = lastval { $_->is_coding( $orf ) } $mutant_transcript->exons;
    my $last_orig_coding_exon = lastval { $_->coding_region_start( $self->transcript ) } @{ $self->transcript->get_all_Exons };

    return 1
        if $last_coding_exon->ensembl_exon->stable_id eq $last_orig_coding_exon->stable_id 
            and $last_coding_exon->phase( $orf ) == $last_orig_coding_exon->phase;
}

sub to_hash {
    my $self = shift;

    if ( $self->has_error ) {
        return {
            ensembl_transcript_id         => $self->transcript->stable_id,
            biotype                       => $self->transcript->biotype,
            floxed_transcript_description => $self->error,
            is_warning                    => 1
        };
    }

    my $h = $self->floxed_transcript->detail_to_hash;
    $h->{ensembl_transcript_id} = $self->transcript->stable_id;
    $h->{biotype}               = $self->transcript->biotype;

    if ( $self->floxed_transcript->predicted_orf ) {
        my $floxed_transcript_exons = $self->floxed_transcript->exons_to_hash;
        my $downstream = $self->floxed_transcript->is_frameshift ? 'frameshifted' : 'downstream';
        $h->{exons} = [
            map( $self->_exon_to_hash( $_, 'upstream',  $floxed_transcript_exons, 0 ), $self->upstream_exons ),
            map( $self->_exon_to_hash( $_, 'deleted',   $floxed_transcript_exons, 1 ), $self->floxed_exons ),
            map( $self->_exon_to_hash( $_, $downstream, $floxed_transcript_exons, 0 ), $self->downstream_exons  )
        ];
    }

    return $h;
}

sub _exon_to_hash {
    my ( $self, $exon, $desc, $floxed_transcript_exons, $floxed_exons ) = @_;

    $self->log->debug( "_exon_to_hash " . $exon->stable_id );
    my $peptide_seq = $exon->peptide( $self->transcript )->seq;

    my %h = (
        ensembl_stable_id => $exon->stable_id,
        phase             => $exon->phase,
        end_phase         => $exon->end_phase,
        seq               => $exon->seq->seq,
        translation       => $peptide_seq,
        description       => $desc,
        domains           => $self->domains_for_peptide_brief( $peptide_seq ),
        structure         => $self->_exon_structure( $exon->phase, $exon->end_phase, $exon )
    );

    if ( ref $exon eq 'HTGT::Utils::MutagenesisPrediction::PartExon::UpstreamPartExon' ){
        $h{ art_intron_offset } = $exon->length;
    }
    elsif ( ref $exon eq 'HTGT::Utils::MutagenesisPrediction::PartExon::FloxedPartExon' ){
        $h{ art_intron_offset } = - $exon->length;
    }
    if ( $floxed_transcript_exons and $floxed_transcript_exons->{ $exon->stable_id }
             and $floxed_exons == 0 ){
        my $f = $floxed_transcript_exons->{ $exon->stable_id };
        $h{floxed_phase}       = $f->{phase};
        $h{floxed_end_phase}   = $f->{end_phase};
        $h{floxed_translation} = $f->{translation};
        $h{floxed_structure}   = $self->_exon_structure( $f->{phase}, $f->{end_phase}, $exon );
        $self->log->debug( "Floxed exon: " . $exon->stable_id );
        $self->log->debug( "Floxed exon phase: " . $f->{phase} );
        $self->log->debug( "Floxed exon end phase: " . $f->{end_phase} );
    }
    return \%h;
}

sub _exon_structure {
    my ( $self, $start_phase, $end_phase, $exon ) = @_;

    if ( $start_phase == -1 ) {
        if ( $end_phase == -1 ) {
            if( $exon->coding_region_start( $self->transcript ) ){
                return 'UCU';
            }
            # Non-coding exon
            return 'U';
        }
        else {
            # UTR followed by coding region
            return 'UC';
        }
    }
    else {
        if ( $end_phase == -1 ) {
            # Coding region followed by UTR
            return 'CU';
        }
        else {
            # Coding exon with no UTR
            return 'C';
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
