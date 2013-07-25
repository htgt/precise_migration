package HTGT::Utils::DesignFinder::Constants;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Const::Fast;

our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
BEGIN {
    @EXPORT       = ();
    @EXPORT_OK    = qw( $MAX_CRITICAL_REGION_SIZE
                        $MAX_CANDIDATE_OLIGO_DISTANCE
                        $DS_IN_UTR_THRESHOLD
                        $DEFAULT_5P_SPACER
                        $MIN_5P_SPACER
                        $DEFAULT_BLOCK
                        $MIN_BLOCK
                        $DEFAULT_3P_SPACER
                        $MIN_3P_SPACER
                        $DEFAULT_OFFSET
                        $MIN_OFFSET
                        $MIN_OLIGO_REGION
                        $IDEAL_INTRON_SIZE
                        $MIN_INTRON_SIZE
                        $MIN_5P_INTRON_SIZE
                        $MIN_3P_INTRON_SIZE
                        $MIN_POST_DEL_TRANSLATION_SIZE
                        $MAX_REINITIATION_PROTEIN_SIZE
                        $MAX_ORIG_PROTEIN_PCT
                        $MIN_VALID_INTRON_LENGTH
                        $MIN_CLEAR_FLANK                                          
                        $OVERLAP_GENE_3P_FLANK
                        $OVERLAP_GENE_5P_FLANK
                        $NMD_SPLICE_LIMIT
                        $MIN_CONSTRAINED_ELEMENT_SCORE
                        $MAX_REPEAT_CE_OVERLAP
                        $OLIGO_SIZE
                        $INSERT_SITE_RX
                        $MIN_START_CASS_DIST
                        candidate_region_size
                  );
    %EXPORT_TAGS = ( default                => \@EXPORT,
                     candidate_oligo_region => [ qw( $MAX_CRITICAL_REGION_SIZE
                                                     $MAX_CANDIDATE_OLIGO_DISTANCE
                                                     $DS_IN_UTR_THRESHOLD
                                                     $MIN_CLEAR_FLANK
                                                     $IDEAL_INTRON_SIZE
                                                     $MIN_INTRON_SIZE
                                                     $DEFAULT_5P_SPACER
                                                     $MIN_5P_SPACER
                                                     $DEFAULT_BLOCK
                                                     $MIN_BLOCK
                                                     $DEFAULT_3P_SPACER
                                                     $MIN_3P_SPACER
                                                     $DEFAULT_OFFSET
                                                     $MIN_OFFSET
                                                     $MIN_OLIGO_REGION
                                                     $MIN_5P_INTRON_SIZE
                                                     $MIN_3P_INTRON_SIZE
                                                     $MIN_CONSTRAINED_ELEMENT_SCORE
                                                     $MAX_REPEAT_CE_OVERLAP
                                                     $OLIGO_SIZE
                                                     candidate_region_size
                                               ) ]
                 );
}

const our $MAX_CANDIDATE_OLIGO_DISTANCE  => 3200;
const our $MAX_CRITICAL_REGION_SIZE      => 3000;
const our $DS_IN_UTR_THRESHOLD           => 2000;

const our $DEFAULT_5P_SPACER => 300;
const our $MIN_5P_SPACER     => 180;
const our $DEFAULT_BLOCK     => 120;
const our $MIN_BLOCK         => 65;
const our $DEFAULT_3P_SPACER => 100;
const our $MIN_3P_SPACER     => 40;
const our $DEFAULT_OFFSET    => 60;
const our $MIN_OFFSET        => 20;
const our $MIN_OLIGO_REGION  => $MIN_OFFSET + 2*$MIN_BLOCK;

const our $MIN_CONSTRAINED_ELEMENT_SCORE   => 50;
const our $MAX_REPEAT_CE_OVERLAP           => 20;

const our $IDEAL_INTRON_SIZE             => candidate_region_size( $DEFAULT_5P_SPACER, $DEFAULT_BLOCK, $DEFAULT_OFFSET, $DEFAULT_3P_SPACER );

const our $MIN_INTRON_SIZE               => candidate_region_size( $MIN_5P_SPACER, $MIN_BLOCK, $MIN_OFFSET, $MIN_3P_SPACER );

const our $MIN_5P_INTRON_SIZE            => $MIN_INTRON_SIZE;
const our $MIN_3P_INTRON_SIZE            => $MIN_INTRON_SIZE;

const our $MIN_CLEAR_FLANK               => 1500;

const our $OLIGO_SIZE                    => 50;

# If the translated protein is less than $MIN_POST_DEL_TRANSLATION_SIZE aa, we need
# to check for re-initiation
const our $MIN_POST_DEL_TRANSLATION_SIZE => 35;

const our $MAX_REINITIATION_PROTEIN_SIZE => 100;

const our $MAX_ORIG_PROTEIN_PCT          => 50;

const our $MIN_VALID_INTRON_LENGTH       => 15;

const our $OVERLAP_GENE_3P_FLANK         => 500;
const our $OVERLAP_GENE_5P_FLANK         => 900;

# If splicing occurs more than $NMD_SPLICE_LIMIT base pairs
# after the stop codon, a transcript is considered subject
# to nonsense mediated decay (NMD)

const our $NMD_SPLICE_LIMIT              => 55;

const our $INSERT_SITE_RX      => qr/AG[GA]/;
const our $MIN_START_CASS_DIST => 100;

sub candidate_region_size {
    my ( $five_spacer_size, $block_size, $offset, $three_spacer_size ) = @_;

    return $five_spacer_size + ( 2 * $block_size ) + $offset + $three_spacer_size;
}

1;

__END__
