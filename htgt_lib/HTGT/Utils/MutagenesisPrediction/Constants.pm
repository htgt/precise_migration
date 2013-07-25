package HTGT::Utils::MutagenesisPrediction::Constants;

use base 'Exporter';
use Const::Fast;

our @EXPORT      = qw( $MIN_TRANSLATION_LENGTH $NMD_SPLICE_LIMIT );
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = ();

# Any erroneous peptides less than 35aa will be produced, but simply
# get degraded by the cell.  Up to 35aa and the ribosomal initiation
# complex will most likely still be intact, allowing further
# initiations, but beyond this the components will have dissociated,
# preventing reinitiation.

const our $MIN_TRANSLATION_LENGTH => 35;

# NMD is a specific process which occurs when an ORF of >35aa has a PTC
# (premature termination codon) AT LEAST 55bp before the last splice site.
# It is the combination of the PTC followed by the exon junction complex
# which makes the surveillance mechanism realise that the transcript is junk
# & so it is degraded

# XXX Alejo says 55, Ruth says 50 - double-check with Ruth.

const our $NMD_SPLICE_LIMIT       => 55;

1;

__END__
