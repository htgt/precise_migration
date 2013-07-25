package HTGT::Utils::Recovery::Constants;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';

use Readonly;

BEGIN {
    our @EXPORT = ();

    our %EXPORT_TAGS = (
        state     => [ qw( $ST_INITIAL
                           $ST_NO_PCS_QC
                           $ST_RDR_C $ST_RDR
                           $ST_GWR_C $ST_GWR
                           $ST_RESEQ_C $ST_RESEQ
                           $ST_ACR_C $ST_ACR_C_NO_ALT $ST_ACR
                           $ST_NONE ) ],
        limits    => [ qw( $EPD_DISTRIBUTE_THRESHOLD $MIN_PROMOTORLESS_TRAPS ) ],
        cassettes => [ qw( %IS_ST_CASSETTE %IS_PROMOTORLESS_CASSETTE ) ],
    );
    
    our @EXPORT_OK = ( map( @$_, values %EXPORT_TAGS ),
                       qw( @PROJECT_STATUS_IGNORE_GENE @PROJECT_STATUS_IGNORE_PROJECT $PROJECT_STATUS_REDESIGN_REQUESTED
                           @PCS_PRIMERS @REPORTS @BL6_CLONE_LIBS $OLFACTORY_MARKER_RX ) );
}

# Valid recovery states
Readonly our $ST_INITIAL      => 'initial';
Readonly our $ST_NO_PCS_QC    => 'no-pcs-qc';
Readonly our $ST_RDR_C        => 'rdr-c';
Readonly our $ST_RDR          => 'rdr';
Readonly our $ST_GWR_C        => 'gwr-c';
Readonly our $ST_GWR          => 'gwr';
Readonly our $ST_ACR_C        => 'acr-c';
Readonly our $ST_ACR_C_NO_ALT => 'acr-c-no-alt';
Readonly our $ST_ACR          => 'acr';
Readonly our $ST_RESEQ_C      => 'reseq-c';
Readonly our $ST_RESEQ        => 'reseq';
Readonly our $ST_NONE         => 'none';

# Marker symbols for olfactory and taste receptor genes match this regular expression
Readonly our $OLFACTORY_MARKER_RX => qr/^(?:Olfr|Tas|Vmn)/;

# Clone library IDs for Bl6/J BAC strain (see CLONE_LIB_DICT table)
Readonly our @BL6_CLONE_LIBS => ( 2, 200 );

# Genes are in 'final' state if they have more than $EPD_DISTRIBUTE_THRESHOLD distributable EPDs
Readonly our $EPD_DISTRIBUTE_THRESHOLD => 2;

# Promotorless cassettes are considered unsuitable for this
# gene if it has fewer than $MIN_PROMOTORLESS_TRAPS traps.
Readonly our $MIN_PROMOTORLESS_TRAPS => 4;

# For classifying cassettes...
Readonly our %IS_ST_CASSETTE => map { $_ => 1 }
    qw( L1L2_st0 L1L2_st1 L1L2_st2 );

Readonly our %IS_PROMOTORLESS_CASSETTE => map { $_ => 1 }
    qw( L1L2_gt0 L1L2_gt1 L1L2_gt2 L1L2_gtk L1L2_st0 L1L2_st1 L1L2_st2 );

# Project status codes that signal no recovery should be done at the *gene* level
Readonly our @PROJECT_STATUS_IGNORE_GENE => qw( DNP W H TN );

# Project status codes that signal the *project* should be ignored
Readonly our @PROJECT_STATUS_IGNORE_PROJECT => ( qw( TV-PT TVC-PT ESC-GT REG ), @PROJECT_STATUS_IGNORE_GENE );

# Project status code that signals the gene is a redesign candidate
Readonly our $PROJECT_STATUS_REDESIGN_REQUESTED => 'RR';

# PCS primers to take note of when looking for best PCS well
Readonly our @PCS_PRIMERS => qw( r4r r2r z1 r1r r3 r3f lr lrr r4 z2 lfr );

# List of reports, used to generate cached reports and index page in controller
Readonly our @REPORTS => (
    #
    # Miscellaneous
    #
    {
        name => 'Miscellaneous',
        reports => [
            {
                action => 'no_recovery',
                name   => 'Genes requiring no recovery',
                class  => 'HTGT::Utils::Recovery::Report::NoRecovery'
            },        
            {
                action => 'design_plate_no_pcs_qc',
                name   => 'Design Plates with no PCS QC',
                class  => 'HTGT::Utils::Report::DesignPlateNoPCSQC'
            },
            {
                action => 'no_pcs_qc',
                name   => 'Genes with no PCS QC',
                class  => 'HTGT::Utils::Recovery::Report::NoPCSQC',
            },
            {
                action => 'komp_no_pcs_qc',
                name   => 'KOMP Genes with no PCS QC',
                class  => 'HTGT::Utils::Recovery::Report::NoPCSQC::KOMP'
            },
            {
                action => 'eucomm_no_pcs_qc',
                name   => 'EUCOMM Genes with no PCS QC',
                class  => 'HTGT::Utils::Recovery::Report::NoPCSQC::EUCOMM'
            },
        ]
    },
    #
    # Alt Clone Candidates
    #
    {
        name => 'Alternate Clone Recovery Candidates',
        reports => [
            {
                action => 'reseq_candidates',
                name   => 'Candidates for Resequencing Recovery',
                class  => 'HTGT::Utils::Recovery::Report::ResequencingCandidate',
            },
            {
                action => 'alt_clone_candidate_with_alt',
                name   => 'Candidates for Alternate Clone Recovery (with alternates)',
                class  => 'HTGT::Utils::Recovery::Report::AltCloneCandidate',
            },
            {
                action => 'alt_clone_candidate_no_alt',
                name   => 'Candidates for Alternate Clone Recovery (no alternates)',
                class  => 'HTGT::Utils::Recovery::Report::AltCloneCandidateNoAlt',
            },
        ]
    },
    #
    # Alt Clone
    #
    {
        name => 'Alternate Clone Recovery',
        reports => [
            {
                action => 'alt_clone',
                name   => 'Genes in Alternate Clone Recovery',
                class  => 'HTGT::Utils::Recovery::Report::AltClone',
            },
            {
                action => 'komp_alt_clone',
                name   => 'KOMP Genes in Alternate Clone Recovery',
                class  => 'HTGT::Utils::Recovery::Report::AltClone::KOMP',
            },
            {
                action => 'eucomm_alt_clone',
                name   => 'EUCOMM Genes in Alternate Clone Recovery',
                class  => 'HTGT::Utils::Recovery::Report::AltClone::EUCOMM',
            },
        ]
    },
    #
    # Redesign Candidates
    #
    {
        name => 'Redesign/Resynthesis Recovery Candidates',
        reports => [
            {
                action => 'redesign_candidates',
                name   => 'Candidates for Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::RedesignCandidate'
            },
            {
                action => 'komp_redesign_candidates',
                name   => 'KOMP Candidates for Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::RedesignCandidate::KOMP'
            },
            {
                action => 'eucomm_redesign_candidates',
                name   => 'EUCOMM Candidates for Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::RedesignCandidate::EUCOMM'
            },
        ]
    },
    #
    # Redesign
    #
    {
        name => 'Redesign/Resynthesis Recovery',
        reports => [
            {
                action => 'redesign',
                name   => 'Genes in Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Redesign'
            },
            {
                action => 'komp_redesign',
                name   => 'KOMP Genes in Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Redesign::KOMP'
            },
            {
                action => 'eucomm_redesign',
                name   => 'EUCOMM Genes in Redesign/Resynthesis Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Redesign::EUCOMM'
            },
        ]
    },
    #
    # Gateway Candidates
    #
    {
        name => 'Gateway Recovery Candidates',
        reports => [
            {
                action => 'gateway_candidates',
                name   => 'Candidates for Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::GatewayCandidate'
            },
            {
                action => 'komp_gateway_candidates',
                name   => 'KOMP Candidates for Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::GatewayCandidate::KOMP'
            },
            {
                action => 'eucomm_gateway_candidates',
                name   => 'EUCOMM Candidates for Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::GatewayCandidate::EUCOMM'
            },
        ]
    },
    #
    # Gateway
    #
    {
        name => 'Gateway Recovery',
        reports => [
            {
                action => 'gateway',
                name   => 'Genes in Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Gateway'
            },
            {
                action => 'komp_gateway',
                name   => 'KOMP Genes in Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Gateway::KOMP'
            },
            {
                action => 'eucomm_gateway',
                name   => 'EUCOMM Genes in Gateway Recovery',
                class  => 'HTGT::Utils::Recovery::Report::Gateway::EUCOMM'
            },
            {
                action => 'gateway_distribute',
                name   => 'Gateway Recovery Distributable Vectors',
                class  => 'HTGT::Utils::Recovery::Report::GatewayDistribute'
            },
            {
                action => 'gateway_distribute_summary',
                name   => 'Gateway Recovery Distributable Vectors Summary',
                class  => 'HTGT::Utils::Recovery::Report::GatewayDistributeSummary'
            },            
        ]
    },
);


1;

__END__
