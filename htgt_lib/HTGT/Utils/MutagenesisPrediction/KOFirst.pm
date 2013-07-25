package HTGT::Utils::MutagenesisPrediction::KOFirst;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::MutagenesisPrediction';

has domains => (
    is         => 'ro',
    isa        => 'ArrayRef',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_translation {
    my $self = shift;

    my $transcript = $self->transcript;

    my @coding_exons = grep $_->coding_region_start( $transcript ), $self->upstream_exons;
    unless ( @coding_exons ) {
        # XXX Does floxing the first coding exon have an impact on computing the
        # translation of the cassette elements?
        return Bio::Seq->new( -alphabet => 'protein', -seq => '' );
    }

    my $dna_seq = Bio::Seq->new( -alphabet => 'dna', -seq => '' );    
    Bio::SeqUtils->cat( $dna_seq, map $_->seq, @coding_exons );
    if ( my $utr = $self->exon_5p_utr( $coding_exons[0] ) ) {
        $dna_seq = $dna_seq->trunc( $utr + 1, $dna_seq->length );
    }
    
    $self->log->debug( "Upstream sequence: " . $dna_seq->seq );

    my $protein_seq = $dna_seq->translate;
    $self->log->debug( "Upstream protein: " . $protein_seq->seq );

    return $protein_seq;
}

sub _build_domains {
    my $self = shift;

    # XXX This will break when (if) _build_translation() is updated to include translation of
    # the cassette elements
    
    $self->domains_for_peptide( $self->translation->seq );
}

sub _build_desc {
    my $self = shift;

    my $orig_protein_length         = $self->transcript->translation->length;
    my $ko_first_translation_length = $self->translation->length;
    my $domains                     = $self->domains;

    my $domains_desc;
    if ( @{$domains} ) {
        $domains_desc = join q{, },
            map sprintf( '%s [%d/%d aa]', $_->{domain}->{idesc}, @{$_->{amino_acids}} ), @{$domains};
    }
    else {
        $domains_desc = 'no protein domains';
    }
    
    sprintf( '%d/%d amino acids (%s)', $ko_first_translation_length, $orig_protein_length, $domains_desc );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

[
  {
    description       => "upstream",
    domains           => [],
    ensembl_stable_id => "ENSMUSE00000761328",
    peptide           => "",
    sequence          => "GAGTGAGAGGCTCTTTTGTTCGGCTGAGGGGAGGGCCGTTAGCGGGGCCTGCGGTACGCCGCTTCAGCGGGACGGTCGACTTGTGGCCACACGGCTCTTTGCTCCTCTGGGCGCGCTACTCCCCTCGGACCGCCCGACGCAACGCGCGAGTAGCGCGGCACCGATTCCTCTCGGACTCTCGGGCGCTGCTACGAG",
  },
  {
    description       => "upstream",
    domains           => [["Chromodomain", 26, 50]],
    ensembl_stable_id => "ENSMUSE00000858269",
    peptide           => "MGKKQNKKKVEEVLEEEEEEYVVEKVLDRRVVKGKVEYLLKWKGFSD",
    sequence          => "CAGTGTCACCCTTCACACCAGAAAGCTGGCGGGTACTATGGGGAAAAAGCAAAACAAGAAGAAAGTGGAGGAGGTACTAGAAGAAGAGGAAGAGGAATATGTGGTGGAAAAAGTTCTTGATCGGCGAGTTGTCAAGGGCAAGGTGGAATATCTTCTAAAGTGGAAGGGTTTCTCAGA",
  },
  {
    description => "deleted",
    domains => [["Chromodomain", 25, 50]],
    ensembl_stable_id => "ENSMUSE00000110990",
  },
  {
    description => "frameshifted",
    ensembl_stable_id => "ENSMUSE00000110987",
    peptide => "QKSHEALPGVWSQSGLLELLTPVESSCS*",
    sequence => "TCAGAAAAGCCACGAGGCTTTGCCCGGGGTTTGGAGCCAGAGCGGATTATTGGAGCTACTGACTCCAGTGGAGAGCTCATGTTCCTGATGAAATG",
  },
  {
    description => "frameshifted",
    ensembl_stable_id => "ENSMUSE00000585970",
    sequence => "GAAAAACTCTGATGAGGCTGACCTGGTCCCTGCCAAGGAAGCCAATGTCAAGTGCCCACAGGTTGTCATATCCTTCTATGAGGAAAGGCTAACGTGGCATTCCTACCCCTCAGAGGATGATGACAAAAAAGACGACAAGAATTAGCCCT",
  },
  {
    description => "frameshifted",
    ensembl_stable_id => "ENSMUSE00000585969",
    sequence => "GTCTTCTTCCCGTGTTGCCCAGTCTGGCCTAGAACTTTGAATCCTATGCCTCCACTGTTCAGTGCTGGAATTGCATGGTGTGTGTACCACTGCAGCAGGCATCTTCATCTTATCAGCAGCCCTCTTGCCTCAGCTCAGCTTCTCAAAAGTGCCTGCCACAGCTTCATGACTATAGATGGACACTGTAGGCTCAATCTTGTGCCCTAGTCTTTTAAATGGCCTCAGTTTATTAATATAGTAATATTTGAGCATTTATAATTGCTGAACATATAGTTAGGAACTGGCACATCATTCTATATTTCGTATTGCTGGGAAATTATTTACTGATAACACTTCCAAATATAGTTATTTGAAAACATGTTTTATGAAGTAGCTTAGTCAGTTGGATGGCATCAGCATATGTTGTCACCAAAAAGTTTGAGGAATTGGCATTATGTATTAAACACTCAGTTGGATG",
  },
]

[
  {
    description       => "upstream",
    domains           => [],
    ensembl_stable_id => "ENSMUSE00000196464",
    peptide           => "MALWLPGGQLTLLLLLWVQQTPAGSTE",
    sequence          => "ATTCCCCTGCATGCCGACTAGACAGAGAGACGGTTTTTGCCTTCTTTACACTGAAAACCATTCTGTGCCGCGCACATCTGGCCCTTTCGCGGAGACTTCAACACTGCAAAGGCGCTAGACTTCTACCTTGGAGGAAACTGTCGGTTGTTGAGGTTGTTGATATTCAACAGAAGTCACAGTTGCGGCAGGAGCAGAACCTCAGACACAGCCGGAAAAGAAAATGCCAAAGGAGGACTCTAGAGCGTATTCTGGGACGAGGCTTTCAGAATAAAGAAGTGTTGCTGACACAAACCACCAAGCTGCCCACTGACCAGTAGATCTAAGAGAACGTGTCTACCAAGTGCTACAGACAGGAGGATGGCGCTGTGGCTTCCAGGAGGGCAGCTCACCCTGCTGCTACTGCTCTGGGTCCAGCAGACACCCGCGGGGAGCACTGAG",
  },
  {
    description => "deleted",
    domains => [["ART", 223, 223]],
    ensembl_stable_id => "ENSMUSE00000196466",
  },
  {
    description => "frameshifted",
    ensembl_stable_id => "ENSMUSE00000313469",
    peptide => "LAARSAPLLQWLSAASFWSLLLSRPKAERKGIYWLLFKGAA*",
    sequence => "CTTGCAGCAAGAAGTGCGCCCCTGCTCCAGTGGTTATCGGCTGCCTCTTTTTGGTCACTGTTGTTATCTCGTCCAAAAGCAGAGCGCAAAGGAATCTACTGGCTCCTTTTTAAAGGAGCTGCTTAAATTTGATGCTCCTATTTGTGTTACCAAAGTCTGAGGCCCACACTTCCCACAATACCACAGAAGATGTGCAAGAAAAGTTCATGGGGGGGGAGAGGGGGCGGGGACAACCCTAAGTTCAAATCTAGGCCTAAATAAGGCAGAAGACTGTCAGAAATCCCTGCCTAAAAGGATTTAGGCTACTTTTTCCTGTTGCTGTCAGCAAAACCAATCACAGAAGCTCAAACAAAGTTCAGGATGAAAGCTTTGCTTCCACTTATAAACTTACAGAACATCGTAGACCAGAAGTGTTTGGTCCCAGCAGCACCAGGCACTACAGAAGCAGATACCAGGCAGACTATCAAATCTCAAGGCCTGCCCCTTGTGACTCACTTCCTCCAGCAAGGCTCCACCTCCGGAAGACTCTACAGCCACGAAAAATAACACCACCAGAAGGAGACAAAGATCTCAACACATGAGGCACATTTAACCTTCAAACCACAGCAAGGTCTTAGTGTTCAGCGCTCTCTTCCAGGAGAGGAGATGGGAGTCCTGACAGACAAGGGCAGAACATCCCTGCTCTGTGAAGGTTTTTCCTACCCAGACCCGTCTTTGCTCTGCCCTCCTCAGGAACCTCACAAAGGACCACTCTCCTGCAGCCAGCCAACCAGAACTGAAAAGGGCCTTCAGCACACTGCTACTGAAAGCCATGCATGGCGTCTTCCTTGCCTGTCCATTTGCCCTTCCCAGTCTCAGGGCCTTGGTCTTATTCAGTGAAGACACCCAAGGATACCACTTGCCCATTACTTGGCCAGAGATCCATGACAAAATGACAATCTTGTGGCAGCATATGAGACAGAATTAGGATACGTTTTCTAGATTAGTTTTGGGAGCGCAGCATTCAGAATCTATTGTGAGTGATTATAAAAGCTGAGCACATGGCACGCTGCGTTGCCTGTAGCTGCCTCGCCACCAAGAGATAAGAATTTGCCTCCCTAAGAAACTAATTCAGTGGAGGCAGTGCTAAGAAACAGAGAGAAGATAGGCAAGATGAGCCTCTAGCGCCAAACTGGGCCTGAACCAGATAGTCAGCTTCATCATTTTCATGGATTAATAAATGATATCTGTGCTAACG",
  },
]

[
  {
    description => "upstream",
    ensembl_stable_id => "ENSMUSE00000187658",
    sequence => "TCAGACTCACACTTTCCATGTCTAGATTTCATTTTCGTGAGTTGATGAAAAGCTAAAGCCAGAAAGCAGCTGGGAGGACAAGAAAGAGGCCTTATAAG",
  },
  {
    description => "deleted",
    domains => [],
    ensembl_stable_id => "ENSMUSE00000187657",
  },
  {
    description => "deleted",
    domains => [],
    ensembl_stable_id => "ENSMUSE00000223424",
  },
]

