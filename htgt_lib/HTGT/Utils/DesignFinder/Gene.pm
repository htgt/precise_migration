package HTGT::Utils::DesignFinder::Gene;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Constants qw( $MIN_INTRON_SIZE $MAX_CRITICAL_REGION_SIZE );
use HTGT::Utils::DesignFinder::Transcript;
use List::MoreUtils qw( any );

with qw( MooseX::Log::Log4perl HTGT::Role::EnsEMBL );

has ensembl_gene_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has ensembl_gene => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Gene',
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        strand     => 'strand',
        chromosome => 'seq_region_name',
        stable_id  => 'stable_id',
    }
);

for ( qw( all_transcripts valid_coding_transcripts complete_transcripts incomplete_transcripts ) ) {

    has "_$_" => (
        is         => 'ro',
        isa        => 'ArrayRef[HTGT::Utils::DesignFinder::Transcript]',
        traits     => [ 'Array' ],
        handles    => {
            $_       => 'elements',
            "has_$_" => 'count',  
        },
        init_arg   => undef,
        lazy_build => 1
    );
}

has template_transcript => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignFinder::Transcript',
    init_arg   => undef,
    lazy_build => 1,
);

has _template_exons => (
    is         => 'ro',
    isa        => 'ArrayRef[Bio::EnsEMBL::Exon]',
    init_arg   => undef,
    traits     => [ 'Array' ],
    handles    => {
        template_exons     => 'elements',
        num_template_exons => 'count',
        get_template_exon  => 'get',
    },
    lazy_build => 1,
);

sub _build_ensembl_gene {

    my $self = shift;
    my $gene = $self->gene_adaptor->fetch_by_stable_id( $self->ensembl_gene_id )
        or confess 'failed to retrieve EnsEMBL gene: ' . $self->ensembl_gene_id;

    return $gene;
}

# Instantiate a HTGT:Utils::DesignFinder::Transcript object for
# each EnsEMBL transcript for this gene, and return a list
# sorted on translation length and length.

sub _build__all_transcripts {
    my $self = shift;

    my @transcripts = map $_->[0],
        sort { $b->[1] <=> $a->[1]
                   || $b->[2] <=> $a->[2]
                       || $b->[3] <=> $a->[3]
                           || $b->[4] <=> $a->[4]
                               || $b->[5] <=> $a->[5] }
            map [ $_,
                  $_->biotype eq 'protein_coding' ? 1 : 0,
                  $_->has_valid_start ? 1 : 0,
                  $_->analysis->logic_name eq 'ensembl_havana_transcript' ? 1 : 0,
                  $_->translation ? $_->translation->length : 0,
                  $_->length
              ], map HTGT::Utils::DesignFinder::Transcript->new( $_ ), @{ $self->ensembl_gene->get_all_Transcripts };

    my $template_transcript = $transcripts[0];
    $_->check_complete( $template_transcript ) for @transcripts;

    return \@transcripts;
}

sub _build__valid_coding_transcripts {
    my $self = shift;

    my @transcripts = grep $_->is_valid_coding_transcript, $self->all_transcripts;
    
    $self->log->debug( "Valid coding trancripts: " . join q{, }, map $_->stable_id, @transcripts );    

    return \@transcripts;
}

sub _build__complete_transcripts {
    my $self = shift;

    my @complete_transcripts = grep $_->is_complete, $self->valid_coding_transcripts;
    $self->log->debug( "Complete transcripts: " . join q{, }, map $_->stable_id, @complete_transcripts );

    return \@complete_transcripts;
}

sub _build__incomplete_transcripts {
    my $self = shift;

    my @incomplete_transcripts = grep $_->is_incomplete, $self->valid_coding_transcripts;
    $self->log->debug( "Incomplete transcripts: " . join q{, }, map $_->stable_id, @incomplete_transcripts );
    
    return \@incomplete_transcripts;
}

sub _build_template_transcript {
    my $self = shift;

    my $template_transcript = ( $self->valid_coding_transcripts )[0]
        or confess "Failed to find a template transcript";

    $self->log->debug( "Template transcript: " . $template_transcript->stable_id );

    return $template_transcript;
}

sub _build__template_exons {
    my $self = shift;

    my $exons = $self->template_transcript->get_all_Exons;

    $self->log->debug( "Template exons: " . join q{, }, map $_->stable_id, @$exons );

    return $exons;
}

sub first_exon_codes_more_than_50pct_protein {
    my $self = shift;

    my $first_exon = $self->get_template_exon(0);
    
    return $first_exon->coding_region_start( $self->template_transcript )
        && $first_exon->peptide( $self->template_transcript )->length >= $self->template_transcript->translation->length / 2;
}

sub last_candidate_start_ce_index {
    my $self = shift;

    my $transcript = $self->template_transcript;
    my $total_translation = $transcript->translation->length;

    my @exons = $self->template_exons;
    
    #
    # Find the index of the last exon that starts before we are 50% of the way
    # into the protein
    #
    my $running_total = 0;
    for my $index ( 0 .. $#exons ) {
        $running_total += $exons[$index]->peptide( $transcript )->length;
        return $index if $running_total >= $total_translation / 2;        
    }

    # never reached
    confess "failed to find index of exon coding 50% protein";
}

sub has_symmetrical_exons {
    my $self = shift;

    
    my $last_ce = $self->get_template_exon( $self->last_candidate_start_ce_index );
    my @exons;
    if ( $self->strand == 1 ) {
        my $cutoff = $last_ce->start + $MAX_CRITICAL_REGION_SIZE;
        @exons = grep $_->start < $cutoff, $self->template_exons;        
    }
    else {
        my $cutoff = $last_ce->end - $MAX_CRITICAL_REGION_SIZE;
        @exons = grep $_->end > $cutoff, $self->template_exons;
        
    }

    shift @exons; # we never delete the first exon
    
    for my $exon ( @exons ) {        
        if ( $exon->phase == -1 or $exon->end_phase == -1 or $exon->phase != $exon->end_phase ) {
            return;
        }
    }

    return 1;
}

sub has_transcripts_starting_after_half_protein {
    my $self = shift;

    if ( $self->ensembl_gene->strand == 1 ) {
        my $cutoff = $self->get_template_exon( $self->last_candidate_start_ce_index )->start;
        return any { $_->start > $cutoff } $self->complete_transcripts;
    }
    else {
        my $cutoff = $self->get_template_exon( $self->last_candidate_start_ce_index )->end;
        return any { $_->end < $cutoff } $self->complete_transcripts;
    }
}

sub has_small_introns {
    my $self = shift;

    for my $transcript ( $self->complete_transcripts ) {
        my @introns;
        if ( $self->ensembl_gene->strand == 1 ) {
            my $cutoff = $self->get_template_exon( $self->last_candidate_start_ce_index )->start;
            @introns = grep $_->start < $cutoff, @{ $transcript->get_all_Introns };
        }
        else {
            my $cutoff = $self->get_template_exon( $self->last_candidate_start_ce_index )->end;
            @introns = grep $_->end > $cutoff, @{ $transcript->get_all_Introns };
        }
        $self->log->debug( "Transcript " . $transcript->stable_id . " intron lengths: " . join q{, }, map $_->length, @introns );
        return 1 unless any { $_->length > $MIN_INTRON_SIZE } @introns;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
