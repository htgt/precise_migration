package HTGT::Utils::MutagenesisPrediction::Deletion;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::MutagenesisPrediction';

use List::MoreUtils qw( firstval );
use Data::Dump 'dd';

for ( qw( reinitiation is_nmd ) ) {
    has $_ => (
        is         => 'ro',
        isa        => 'Bool',
        init_arg   => undef,
        writer     => "_set_$_"
    );
}

has description => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    writer     => '_set_description'
);

has mutant_transcript => (
    is         => 'ro',
    isa        => 'HTGT::Utils::MutagenesisPrediction::Transcript',
    init_arg   => undef,
    writer     => '_set_mutant_transcript'
);

sub BUILD {
    my $self = shift;

    if ( not $self->transcript->coding_region_start ) {
        # Non-coding transcript
        $self->_check_nmd_rescue;
    }
    elsif ( $self->upstream_coding_exons ) {
        if ( $self->downstream_exons ) {
            $self->first_coding_preserved_last_preserved;
        }
        else {
            $self->first_coding_preserved_last_deleted;
        }        
    }
    else {
        if ( $self->downstream_exons ) {
            $self->first_coding_deleted_last_preserved;
        }
        else {
            $self->first_coding_deleted_last_deleted;
        }
    }
}

sub first_coding_preserved_last_preserved {
    my $self = shift;

    my $transcript = $self->transcript;

    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, ( $self->upstream_coding_exons, $self->downstream_exons ) );
    if ( my $utr = $self->exon_5p_utr( ( $self->upstream_coding_exons )[0] ) ) {
        $seq = $seq->trunc( $utr + 1, $seq->length );            
    }

    $self->log->debug( "sequence after deletion: " . $seq->seq );

    my $translation = $seq->translate( -frame => 0 )->seq;
    $self->log->debug( "translation after deletion: " . $translation );

    my @fragments = $translation =~ /(M[^*]+\*)/g;

    if ( length( $fragments[0] ) >= 35 ) {
        
        
    }



    

}

sub first_coding_preserved_last_deleted {
    my $self = shift;

    $self->_set_description( 'Residual N-terminal, unknown C-terminal product' );
    $self->_set_mutant_transcript( $self->_residual_N_terminal, $self->_deleted_exons );
}

sub first_coding_deleted_last_deleted {
    my $self = shift;

    # Check for upstream ORF
    my $seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );
    Bio::SeqUtils->cat( $seq, map $_->seq, $self->upstream_exons );
    for my $frame ( 0, 1, 2 ) {
        my $translation = $seq->translate( -frame => $frame )->seq;
        my @fragments = $translation =~ /(M[^*]+\*)/g;
        if ( my $peptide = firstval { length( $_ ) >= 35 } @fragments ) {
            $self->_set_description( 'Upstream ORF' );
            $self->_set_mutant_transcript( [] ); # XXX need to do some
                                                 # work to map the
                                                 # translation back to
                                                 # the exons :-(
            return;
        }
    }
    
    # No upstream ORF => no protein product
    $self->_set_description( 'No protein product' );
    $self->_set_mutant_transcript( $self->_fivep_utr, $self->_deleted_exons );
}

sub first_coding_deleted_last_preserved {
    my $self = shift;

    confess "not implemented";
}


sub _check_nmd_rescue {
    my $self = shift;

    confess "not implemented";
}

sub _deleted_exons {
    my $self = shift;

    map {
        ensembl_stable_id => $_->stable_id,
        description       => 'deleted',
        domains           => $self->domains_for_exon_brief( $_->stable_id )
    }, $self->floxed_exons;
}
                
sub _residual_N_terminal {
    my $self = shift;

    map {
        ensembl_stable_id => $_->stable_id,
        description       => 'residual N-terminal',
        seq               => $_->seq->seq,
        peptide           => $_->peptide( $self->transcript )->seq,
        domains           => $self->domains_for_exon_brief( $_->stable_id )
    }, $self->upstream_exons;
}

sub _fivep_utr {
    my $self = shift;

    map {
        ensembl_stable_id => $_->stable_id,
        description       => "5' UTR",
        seq               => $_->seq->seq,
    }, $self->upstream_exons;
}


sub _residual_C_terminal {
    my $self = shift;
    
    map {
        ensembl_stable_id => $_->stable_id,
        description       => 'residual C-terminal',
        seq               => $_->seq->seq,
        peptide           => $_->peptide( $self->transcript )->seq,
        domains           => $self->domains_for_exon_brief( $_->stable_id )
    }, $self->downstream_exons;
}

1;

__END__
