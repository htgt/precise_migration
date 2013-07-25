package HTGT::Constants;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';
use Const::Fast;

BEGIN {
    our @EXPORT = ();
    our @EXPORT_OK = qw(
        %SPONSOR_FOR
        %SPONSOR_COLUMN_FOR
        %RANKED_QC_RESULTS
        %QC_RESULT_TYPES
        %CASSETTES %BACKBONES
        %PLATE_TYPES
        @PIQ_SHIPPING_LOCATIONS
        @PIQ_HIDE_WELL_DATA
        $DEFAULT_ANNOTATION_ASSEMBLY_ID
        $DEFAULT_ANNOTATION_BUILD_ID
        @ANNOTATION_BUILDS
        %ANNOTATION_ASSEMBLIES
    );
    our %EXPORT_TAGS = ();
}

const our %SPONSOR_FOR => (
    is_komp_csd         => 'KOMP',
    is_eucomm           => 'EUCOMM',
    is_komp_regeneron   => 'REGENERON',
    is_eutracc          => 'EUTRACC',
    is_norcomm          => 'NORCOMM',
    is_eucomm_tools     => 'EUCOMM-Tools',
    is_switch           => 'SWITCH',
    is_mgp              => 'MGP',
    is_eucomm_tools_cre => 'EUCOMM-Tools-Cre',
    is_mgp_bespoke      => 'MGP-Bespoke',
    is_tpp              => 'TPP',
);

const our %SPONSOR_COLUMN_FOR => map { $SPONSOR_FOR{$_} => $_ } keys %SPONSOR_FOR;

const our %RANKED_QC_RESULTS => (
    na   => 1,
    pass => 2,
    passb => 3,
    fail => 4,
    fa   => 5, #Failed Assay
);

const our %QC_RESULT_TYPES => (
    LOA => {
        well_data_type    => 'loa_qc_result',
        valid_plate_types => [ 'REPD' ],
    },
    LoxP_Taqman => {
        well_data_type    => 'taqman_loxp_qc_result',
        valid_plate_types => [ 'REPD' ],
    },
    PIQ => 1,
    SBDNA => 1,
    QPCRDNA => 1,
);

const our %BACKBONES => (
    'R3R4_pBR_DTA+_Bsd_amp' => {
        full_name      => 'pR3R4 pBR DTA(+) Bsd amp',
        filename       => 'pR3R4 DTA(+) EM7_Bsd.gbk',
        antibiotic_res => 'AmpR',
        gateway_type   => '2-way',
        comments =>
            'medium copy number vector backbone from 4th recombineering after gap repair plasmid recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.'
    },
    'R3R4_pBR_DTA _Bsd_amp' => {
        full_name      => 'pR3R4 pBR DTA(+) Bsd amp',
        filename       => 'pR3R4 DTA(+) EM7_Bsd.gbk',
        antibiotic_res => 'AmpR',
        gateway_type   => '2-way',
        comments =>
            'medium copy number vector backbone from 4th recombineering after gap repair plasmid recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.'
    },    #repeat of above without "+" to deal with bug in old Catalyst
    R3R4_pBR_amp => {
        full_name      => 'pR3R4 AsiSI',
        filename       => 'pR3R4AsiSI_postcre_backbone.gbk',
        antibiotic_res => 'AmpR',
        gateway_type   => '2-way',
        comments =>
            'medium copy number vector backbone from gap repair plasmid from recombineering which remains after 2-way Gateway reaction. Reactive R3 and R4 sites remain on plasmid.'
    },
    L3L4_pZero_DTA_kan => {
        full_name      => 'pL3L4_DTA_kan',
        filename       => 'pL3L4_(+)_DTA Kan MapVerified.gbk',
        antibiotic_res => 'KanR',
        gateway_type   => '3-way',
        comments       => 'high copy number; standard backbone for promoterless vectors'
    },
    L3L4_pZero_kan => {
        full_name      => 'pL3L4_Kan',
        filename       => 'L3L4 pZero map.gbk',
        antibiotic_res => 'KanR',
        gateway_type   => '3-way',
        comments       => 'high copy number, no DTA'
    },
    'L3L4_pD223_DTA_T_spec' => {
        full_name      => 'pL3L4_DONR223_DTA-_spec',
        filename       => 'pL3L4 DONR223 _Spec_DTA(-)Terminator MapVerified.gbk',
        antibiotic_res => 'spec R',
        gateway_type   => '3-way',
        comments       => 'high copy number with DTA'
    },
    L3L4_pD223_spec => {
        full_name      => 'pL3L4_DONR223_spec',
        filename       => '',
        antibiotic_res => 'spec R',
        gateway_type   => '3-way',
        comments       => 'high copy number with DTA'
    },
    L3L4_pD223_DTA_spec => {
        full_name      => 'pL3L4_DONR223_DTA-_noterm_spec',
        filename       => 'pL3L4 DONR223 _Spec_DTA(-) No Terminator MapVerified.gbk',
        antibiotic_res => 'spec R',
        gateway_type   => '3-way',
        comments =>
            'high copy number with DTA; version w/o E. Coli transcription terminator on L4 side; used in a ver limited number of experiments'
    },
    L4L3_pD223_DTA_spec => {
        full_name      => 'pL4L3_DONR223_DTA-_spec',
        filename       => 'pL4L3 DONR223 _Spec_DTA(-)Terminator Map.gbk',
        antibiotic_res => 'spec R',
        gateway_type   => '3-way',
        comments =>
            'INVERTED R3 and R4 Gateway Sites with Linearization close to DTA pA, potentially compromising negative selection'
    },
    L3L4_pZero_DTA_spec => {
        full_name => 'L3L4_pZero_DTA_spec',
        filename  => 'pL3L4_pZero_DTA_Spec Map Validated.gbk',
    },
    L3L4_pZero_DTA_kan_for_norcomm => {
        full_name => 'L3L4_pZero_DTA_kan_for_norcomm',
        filename  => 'pL3L4_(+)_DTA Kan_for_norcomm.gbk',
    },
);

const our %CASSETTES => (
    Ifitm2_intron_L1L2_Bact_P => {
        full_name => 'Ifitm2_intron_L1L2_Bact_P',
        filename  => '',
        comments  => 'Combination of art intron with standard beta actin neo cassette',
        class             => 'promotor',
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    pR6K_R1R2_ZP => {
        full_name => 'pR6K_R1R2_ZP',
        filename  => '',
        comments  => 'Standard intermediate vector cassette',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt0 => {
        full_name => 'pL1L2_gt0_EUCOMM',
        filename  => 'pL1L2_GT0_EUCOMM MapVerified.gbk',
        comments =>
            'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt1 => {
        full_name => 'pL1L2_gt1_EUCOMM',
        filename  => 'pL1L2_GT1_EUCOMM MapVerified.gbk',
        comments =>
            'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt2 => {
        full_name => 'pL1L2_gt2_EUCOMM',
        filename  => 'pL1L2_GT2_EUCOMM MapVerified.gbk',
        comments =>
            'Standard EUCOMM promoterless cassettes with T2 sequences in driving independent translation  of lacZ and neo',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gtk => {
        full_name         => 'pL1L2_gtk_EUCOMM',
        filename          => 'pL1L2_GTK_EUCOMM MapVerified.gbk',
        comments          => 'K frame contains Kozak/ATG for insertions after 5\' UTR\'s',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?',
        phase             => -1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt0_Del_LacZ => {
        full_name         => 'L1L2_gt0_Del_LacZ',
        filename          => 'L1L2_gt0_Del_LacZ.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?_Del_LacZ',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt1_Del_LacZ => {
        full_name         => 'L1L2_gt1_Del_LacZ',
        filename          => 'L1L2_gt1_Del_LacZ.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?_Del_LacZ',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_gt2_Del_LacZ => {
        full_name         => 'L1L2_gt2_Del_LacZ',
        filename          => 'L1L2_gt2_Del_LacZ.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_gt?_Del_LacZ',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT0_LacZ_BSD => {
        full_name         => 'L1L2_GT0_LacZ_BSD',
        filename          => 'L1L2_GT0_LacZ_BSD.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_GT?_LacZ_BSD',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT1_LacZ_BSD => {
        full_name         => 'L1L2_GT1_LacZ_BSD',
        filename          => 'L1L2_GT1_LacZ_BSD.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_GT?_LacZ_BSD',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT2_LacZ_BSD => {
        full_name         => 'L1L2_GT2_LacZ_BSD',
        filename          => 'L1L2_GT2_LacZ_BSD.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_GT?_LacZ_BSD',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GTK_LacZ_BSD => {
        full_name         => 'L1L2_GTK_LacZ_BSD',
        filename          => 'L1L2_GTK_LacZ_BSD.gbk',
        class             => 'promotorless',
        phase_match_group => 'L1L2_GT?_LacZ_BSD',
        phase             => -1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_st0 => {
        full_name => 'pL1L2 st0_EUCOMM',
        filename  => 'pL1L2_ST0_EUCOMM MapVerified.gbk',
        comments =>
            'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci',
        class             => 'promotorless',
        phase_match_group => 'L1L2_st?',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_st1 => {
        full_name => 'pL1L2_st1_EUCOMM',
        filename  => 'pL1L2_ST1_EUCOMM MapVerified.gbk',
        comments =>
            'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci',
        class             => 'promotorless',
        phase_match_group => 'L1L2_st?',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_st2 => {
        full_name => 'pL1L2_st2_EUCOMM',
        filename  => 'pL1L2_ST2_EUCOMM MapVerified.gbk',
        comments =>
            'Secretory Trap versions  of EUCOMM vector with CD4 Tm domain for targeting secreted/TM loci',
        class             => 'promotorless',
        phase_match_group => 'L1L2_st?',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_Bact_P => {
        full_name => 'pL1L2_GTIRES_Bact_P_FLFL',
        filename  => 'pL1L2_GTIRES_BetactP FLFL MapVerified.gbk',
        comments =>
            'Human beta actin promoter driving WT neo.  Frame independent IRES driven LacZ reporter',
        class => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_Pgk_P => {
        full_name => 'pL1L2_GTIRES_Pgk_P_FLFL',
        filename  => 'pL1L2_GTIRES_PgkP FLFL Verified Map.gbk',
        comments  => 'PGK promoter driving WT neo.  Frame indendent IRES driven lacZ reporter',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_Pgk_PM => {
        full_name => 'pL1L2_GTIRES_Pgk_PM_FLFL',
        filename  => 'pL1L2_GTIRES_PgkP FLFL Neo Mutant Verified Map.gbk',
        comments  => 'PGK promoter driving mutant  neo.  Frame indendent IRES driven lacZ reporter',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_hubi_P => {
        full_name => 'L1L2_hubi_P',
        filename  => 'pL1L2_GTIRES_hubiqui P FLFL Map Verified.gbk',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_6XOspnEnh_Bact_P => {
        full_name => 'L1L2_6XOspnEnh_Bact_P',
        filename  => 'pL1L2_GTIRES_6xostpn_BetactP FLFL Map Verified.gbk',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_Bact_EM7 => {
        full_name => 'L1L2_Bact_EM7',
        filename  => 'FINAL pL1L2_GTIRES_BetactP FLFL EM7_neo.gbk',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_Del_BactPneo_FFL => {
        full_name => 'L1L2_Del_BactPneo_FFL',
        filename  => 'pL1L2_Del_BactPneo_FFL_PG.gbk',
        class     => 'promotor',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_LF2A_H2BCherry_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT0_LF2A_H2BCherry_Puro.gbk',
        full_name         => "pL1L2_GT0_LF2A_H2BCherry_Puro",
        phase_match_group => 'pL1L2_GT?_LF2A_H2BCherry_Puro',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA => {
        class             => "promotor",
        filename          => 'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA.gbk',
        full_name         => "pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA",
        phase_match_group => 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT1_LF2A_H2BCherry_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT1_LF2A_H2BCherry_Puro.gbk',
        full_name         => "pL1L2_GT1_LF2A_H2BCherry_Puro",
        phase_match_group => 'pL1L2_GT?_LF2A_H2BCherry_Puro',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA => {
        class             => "promotor",
        filename          => 'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA.gbk',
        full_name         => "pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA",
        phase_match_group => 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT2_LF2A_H2BCherry_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT2_LF2A_H2BCherry_Puro.gbk',
        full_name         => "pL1L2_GT2_LF2A_H2BCherry_Puro",
        phase_match_group => 'pL1L2_GT?_LF2A_H2BCherry_Puro',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA => {
        class             => "promotor",
        filename          => 'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA.gbk',
        full_name         => "pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA",
        phase_match_group => 'pL1L2_GT?_T2A_H2BCherry_Puro_delRsrll_NO_DTA',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT0_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA => {
        class             => "promotor",
        filename          => 'L1L2_GT0_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA.gbk',
        full_name         => "L1L2_GT0_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA",
        phase_match_group => 'L1L2_GT?_T2A_H2BVenus_PGKPuro_delRsrII_NO_DTA',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_bsd_frt15_neo_barcode => {
        class             => "promotor",
        filename          => 'pL1L2_GT0_bsd_frt15_neo_barcode.gbk',
        full_name         => "pL1L2_GT0_bsd_frt15_neo_barcode",
        phase_match_group => 'pL1L2_GT?_bsd_frt15_neo_barcode',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT1_bsd_frt15_neo_barcode => {
        class             => "promotor",
        filename          => 'pL1L2_GT1_bsd_frt15_neo_barcode.gbk',
        full_name         => "pL1L2_GT1_bsd_frt15_neo_barcode",
        phase_match_group => 'pL1L2_GT?_bsd_frt15_neo_barcode',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT2_bsd_frt15_neo_barcode => {
        class             => "promotor",
        filename          => 'pL1L2_GT2_bsd_frt15_neo_barcode.gbk',
        full_name         => "pL1L2_GT2_bsd_frt15_neo_barcode",
        phase_match_group => 'pL1L2_GT?_bsd_frt15_neo_barcode',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_T2A_iCre_KI_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT0_T2A_iCre_KI_Puro.gbk',
        full_name         => "pL1L2_GT0_T2A_iCre_KI_Puro",
        phase_match_group => 'pL1L2_GT?_T2A_iCre_KI_Puro',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_GT1_T2A_iCre_KI_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT1_T2A_iCre_KI_Puro.gbk',
        full_name         => "pL1L2_GT1_T2A_iCre_KI_Puro",
        phase_match_group => 'pL1L2_GT?_T2A_iCre_KI_Puro',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_GT2_T2A_iCre_KI_Puro => {
        class             => "promotor",
        filename          => 'pL1L2_GT2_T2A_iCre_KI_Puro.gbk',
        full_name         => "pL1L2_GT2_T2A_iCre_KI_Puro",
        phase_match_group => 'pL1L2_GT?_T2A_iCre_KI_Puro',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    'L1L2_NTARU-0' => {
        class             => 'promotorless',
        filename          => 'NorCOMM_L1L2_frame_0.ape',
        full_name         => 'L1L2_NTARU-0',
        phase_match_group => 'L1L2_NTARU-?',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_NTARU-1' => {
        class             => 'promotorless',
        filename          => 'NorCOMM_L1L2_Frame_1.ape',
        full_name         => 'L1L2_NTARU-1',
        phase_match_group => 'L1L2_NTARU-?',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_NTARU-2' => {
        class             => 'promotorless',
        filename          => 'NorCOMM_L1L2_frame_2.ape',
        full_name         => 'L1L2_NTARU-2',
        phase_match_group => 'L1L2_NTARU-?',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_NTARU-K' => {
        class             => 'promotorless',
        filename          => 'NorCOMM_L1L2_Frame_K.ape',
        full_name         => 'L1L2_NTARU-K',
        phase_match_group => 'L1L2_NTARU-?',
        phase             => -1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'B1B2_frame0_Norcomm' => {
        class             => 'promotorless',
        filename          => 'NorCOMM B1B2 frame 0.ape',
        full_name         => 'B1B2_frame0_Norcomm',
        phase_match_group => 'B1B2_frame?_Norcomm',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'B1B2_frame1_Norcomm' => {
        class             => 'promotorless',
        filename          => 'NorCOMM B1B2 frame 1.ape',
        full_name         => 'B1B2_frame1_Norcomm',
        phase_match_group => 'B1B2_frame?_Norcomm',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'B1B2_frame2_Norcomm' => {
        class             => 'promotorless',
        filename          => 'NorCOMM B1B2 frame 2.ape',
        full_name         => 'B1B2_frame2_Norcomm',
        phase_match_group => 'B1B2_frame?_Norcomm',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'B1B2_framek_Norcomm' => {
        class             => 'promotorless',
        filename          => 'NorCOMM B1B2 frame k.ape',
        full_name         => 'B1B2_framek_Norcomm',
        phase_match_group => 'B1B2_frame?_Norcomm',
        phase             => -1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'Ty1_EGFP' => {
        class     => 'promotor',
        filename  => 'Ty1_EGFP tag.gbk',
        full_name => 'Ty1_EGFP',
        artificial_intron => 0,
        cre_knock_in      => 0,

    },
    'V5_Flag_biotin' => {
        class     => 'promotor',
        filename  => 'V5_Flag_biotin tag.gbk',
        full_name => 'V5_Flag_biotin',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_NorCOMM' => {
        class     => 'promotorless',
        filename  => 'L1L2_NorCOMM.gbk',
        full_name => 'L1L2_NorCOMM',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_Del_BactPneo_FFL_TAG1A' => {
        class     => 'promotor',
        filename  => 'pL1L2_Del_BactPneo_FFL_TAG1A.gbk',
        full_name => 'L1L2_Del_BactPneo_FFL_TAG1A',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'ZEN-Ub1' => {
        class     => 'promotor',
        filename  => 'ZEN-Ub1.gb',
        full_name => 'ZEN-Ub1',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    'L1L2_GOHANU' => {
        class     => 'promotor',
        filename  => 'pGOHANU_Promoter_L1L2_for_Sanger.ape',
        full_name => 'L1L2_GOHANU',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    Ifitm2_intron_R1_ZeoPheS_R2 => {
        class     => 'intermediate',
        filename  => "Ifitm2_intron_R1_ZeoPheS_R2.gbk",
        full_name => 'Ifitm2_intron_R1_ZeoPheS_R2',
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    L1L2_GT0_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'L1L2_GT0_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT1_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'L1L2_GT1_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    L1L2_GT2_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'L1L2_GT2_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 0,
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 1,
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo',
        phase_match_group => 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => 2,
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo',
        phase_match_group => 'Ifitm2_intron_L1L2_GT?_LF2A_LacZ_BetactP_neo',
        phase             => -1,
        artificial_intron => 1,
        cre_knock_in      => 0,
    },
    pL1L2_frt15_BetactinBSD_frt14_neo_Rox => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'pL1L2_frt15_BetactinBSD_frt14_neo_Rox',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro => {
        class             => 'promotorless',
        filename          => 'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro.gbk',
        full_name         => 'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro',
        phase_match_group => 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro',
        phase             => 0,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro => {
        class             => 'promotorless',
        filename          => 'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro.gbk',
        full_name         => 'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro',
        phase_match_group => 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro',
        phase             => 1,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro => {
        class             => 'promotorless',
        filename          => 'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro.gbk',
        full_name         => 'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro',
        phase_match_group => 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro',
        phase             => 2,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_GTK_nEGFPO_T2A_CreERT_puro => {
        class             => 'promotorless',
        filename          => 'pL1L2_GTK_nEGFPO_T2A_CreERT_puro.gbk',
        full_name         => 'pL1L2_GTK_nEGFPO_T2A_CreERT_puro',
        phase_match_group => 'pL1L2_GT?_LF2A_nEGFPO_T2A_CreERT_puro',
        phase             => -1,
        artificial_intron => 0,
        cre_knock_in      => 1,
    },
    pL1L2_frt_BetactP_neo_frt_lox => {
        class             => 'promotor',
        filename          => '',
        full_name         => 'pL1L2_frt15_BetactinBSD_frt14_neo_Rox',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT0_DelLacZ_bsd => {
        full_name         => 'pL1L2_GT0_DelLacZ_bsd',
        class             => 'promotorless',
        phase_match_group => 'pL1L2_GT?_DelLacZ_bsd',
        phase             => 0,
        filename          => '',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT1_DelLacZ_bsd => {
        full_name         => 'pL1L2_GT1_DelLacZ_bsd',
        class             => 'promotorless',
        phase_match_group => 'pL1L2_GT?_DelLacZ_bsd',
        phase             => 1,
        filename          => '',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_GT2_DelLacZ_bsd => {
        full_name         => 'pL1L2_GT2_DelLacZ_bsd',
        class             => 'promotorless',
        phase_match_group => 'pL1L2_GT?_DelLacZ_bsd',
        phase             => 2,
        filename          => '',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
    pL1L2_frt_EF1a_BSD_frt_lox => {
        full_name         => 'pL1L2_frt_EF1a_BSD_frt_lox',
        class             => 'promotor',
        filename          => '',
        artificial_intron => 0,
        cre_knock_in      => 0,
    },
);


const our %PLATE_TYPES => (
    EP    => 'EP',
    EPD   => 'EPD',
    FP    => 'FP',
    GR    => 'GR',
    GRD   => 'GRD',
    GRQ   => 'GRQ',
    GT    => 'GT',
    PCS   => 'PCS',
    PGS   => 'PGD',
    PGG   => 'PGG',
    PGR   => 'PGR',
    Q     => 'PGG',
    REPD  => 'REPD',
    VTP   => 'VTP',
    PIQ   => 'PIQ',
    PIQS  => 'PIQS',
    PIQFP => 'PIQFP',

    DESIGN => 'DESIGN',
    PC     => 'PC',

    QPCRDNA => 'QPCRDNA',
    SBDNA   => 'SBDNA',
);

const our @PIQ_SHIPPING_LOCATIONS => qw(
    BASH
    HARWELL
    MGP
);

const our @PIQ_HIDE_WELL_DATA => qw(
    loa_cn
    loa_min_cn
    loa_max_cn
    loa_confidence
    loxp_cn
    loxp_min_cn
    loxp_max_cn
    loxp_confidence
    lacz_cn
    lacz_min_cn
    lacz_max_cn
    lacz_confidence
    chry_cn
    chry_min_cn
    chry_max_cn
    chry_confidence
    chr1_cn
    chr1_min_cn
    chr1_max_cn
    chr1_confidence
    chr8a_cn
    chr8a_min_cn
    chr8a_max_cn
    chr8a_confidence
    chr8b_cn
    chr8b_min_cn
    chr8b_max_cn
    chr8b_confidence
    chr11a_cn
    chr11a_min_cn
    chr11a_max_cn
    chr11a_confidence
    chr11b_cn
    chr11b_min_cn
    chr11b_max_cn
    chr11b_confidence
);

const our $DEFAULT_ANNOTATION_ASSEMBLY_ID => 101;
const our $DEFAULT_ANNOTATION_BUILD_ID    => 69.38;

const our %ANNOTATION_ASSEMBLIES => (
    101 => 'GRCm38',
);

const our @ANNOTATION_BUILDS => (
    69.38
);

1;
