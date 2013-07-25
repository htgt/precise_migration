package HTGT::Utils::ESCellStrain;

use strict;
use warnings FATAL => 'all';
use Readonly;
use Carp 'croak';

use base 'Exporter';

BEGIN {
    our @EXPORT      = 'es_cell_strain';
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
}

{
    Readonly my %ES_CELL_STRAIN_FOR => map { chomp; split "\t" } <DATA>;

    sub es_cell_strain {
        my ( $es_cell_line ) = @_;

        croak "ES cell line not specified"
            unless defined $es_cell_line;

        for ( $es_cell_line ) {
            s/^\s+//;
            s/\s+$//;
            s/\s+(\([pP]\d+\)|[pP]\d+)$//;
            s/\s+\(Agouti\)//;
            s/\s+parental//;
        }
            
        croak "Unrecognized ES cell line: $es_cell_line"
            unless exists $ES_CELL_STRAIN_FOR{$es_cell_line};
        
        return $ES_CELL_STRAIN_FOR{$es_cell_line};
    }
}

1;

=pod

=head1 NAME

HTGT::Utils::ESCellStrain

=head1 SYNOPSIS

  use HTGT::Utils::ESCellStrain;
  my $strain = es_cell_strain( $es_cell_line );
  
=head1 DESCRIPTION

This module implements a map from I<es_cell_line> to I<es_cell_strain>.

=head2 EXPORT

=over 4

=item B<es_cell_strain>

Given C<$es_cell_line>, returns the corresponding C<$es_cell_strain>.  C<croak> if 
no matching strain is found.

=back

=head1 AUTHOR

Ray Miller, E<lt>rm7@internal.sanger.ac.ukE<gt>
  
=cut

__DATA__
A3-1	129X1/SvJ
AB1	129S7/SvEvBrd-Hprt<+>
AB2.1	129S7/SvEvBrd-Hprt<b-m2>
AB2.2	129S7/SvEvBrd-Hprt<b-m2>
AC1	129/Sv
AK18.1	129S4/SvJaeSor
AK7	129S4/SvJaeSor
AK7.1	129S4/SvJaeSor
alphaR2	129S4/SvJae
ART4.12	(C57BL/6 x 129S6/SvEvTac)F1
AT1	129S2/SvPasCrl
ATOM1	(C57BL/6 x 129)F1
AV3	129X1/SvJ
B6-Jj	C57BL/6
BALB/c-I	BALB/cJ
BK4	129P2/OlaHsd
BL/6-III	C57BL/6
Bruce 4	C57BL/6
C1	129X1/SvJ
C13	129X1/SvJ
C1368	129T2/SvEms
C2 (Nagy)	C57BL/6N
C4R8	129P2/OlaHsd
C57BL/6Hprt	B6.129P2-Hprt<b-m3>
C57BL/6J-693	C57BL/6J
CB1-4	C57BL/6J x (Rb(11.16)2H x Rb(16.17)32Lub)F1
CBA	CBA/CaOlaHsd
CC1.2	129S7/SvEvBrd
CCB	129S/SvEv-Gpi1<c>
CCE/EK.CCE	129S/SvEv-Gpi1<c>
CCE916	129S/SvEv
CGR8	129P2/OlaHsd
CJ7	129S1/Sv-Oca2<+> Tyr<+> Kitl<+>
CK35	129S2/SvPas
CMTI-1	129S/SvEv
CMTI-2	C57BL/6J
CP-1	129S6/SvEvTac
CSL3	129S6/SvEvTac
CT129	129S/Sv
CY2.4	B6(Cg)-Tyr<c-2J>
D1	(129S6/SvEvTac x C57BL/6J)F1
D3	129S2/SvPas
D3a1	129S2/SvPas
D3a2	129S2/SvPas
D3H	129S2/SvPas
D4	129/Sv
DBA-252	DBA/1LacJ
E	129S4/SvJae
E14	129P2/OlaHsd
E14.1	129P2/OlaHsd
E14.1a	129P2/OlaHsd
E14.1TG3B1	129P2/OlaHsd
E14K	129P2/OlaHsd
E14TG2a	129P2/OlaHsd
E14TG2a.4	129P2/OlaHsd
E14TG2aIV	129P2/OlaHsd
EC7.1	(C57BL/6 x 129X1/SvJ)F1
EF1	129S/SvEv and C57BL/6
ENS	129/Sv
ESF 116	CBA
ESF 122	CBA
ESF 48/1	129P2/Ola
ESF 55	129P2/Ola
ESF 58/2	129P2/Ola
ESVJ	129X1/SvJ
ESVJ-1182	129X1/SvJ
ESVJ-1183	129X1/SvJ
F1H4	(129 x C57BL/6)F1
G4	(129S6/SvEvTac x C57BL/6NCr)F1
GK129	129P2/OlaHsd
GS1	129/Sv
GSI-1	129X1/SvJ
GSIB-1	C57BL/6
H1	129S2/SvPas
HM-1	129P2/OlaHsd-Hprt<b-m3>
IB10/E14IB10	129P2/OlaHsd
IDG3.2	(C57BL/6J x 129S6/SvEvTac)F1
IT2	129/Sv
iTL1	129S6/SvEvTac
J-A18 (B6-albino)	B6(Cg)-Tyr<c-2J>/J
J1	129S4/SvJae
JH1	129S7/SvEvBrd
JM-1	129X1/SvJ
JM8	C57BL/6N
JM8.F6	C57BL/6N
JM8.N19	C57BL/6N
JM8.N4	C57BL/6N
JM8A1	C57BL/6N-A
JM8A1.N3	C57BL/6N-A
JM8A3	C57BL/6N-A
JM8A3.N1	C57BL/6N-A
KAB6	B6(Cg)-Tyr<c-2J>/JCard
KG1/KG-1	129S6/SvEvTac
KMB6-6	C57BL/6
KTPU10	(C57BL/6 x CBA)F1
KTPU8	(C57BL/6 x CBA)F1
Lex-1	129S5/SvEvBrd
Lex-2	129S5/SvEvBrd
Lex3.13	C57BL/6N
LSW1	129X1/SvJ
LW1	129S4/SvJae
MC1	129S6/SvEvTac
MC3	129S6/SvEvTac
MC50	129S/SvEv
mEMS1202	(B6.129P2-Hprt<b-m3>/J x 129S-Gt(ROSA)26Sor<tm1Sor>/J)F1
mEMS1204	(B6.129P2-Hprt<b-m3>/J x 129S-Gt(ROSA)26Sor<tm1Sor>/J)F1
mEMS128	129S1/SvImJ
mEMS21	129P2/OlaHsd
mEMS21TG2A	129P2/OlaHsd
mEMS32	129P3/JEmsJ
MESC 20	129P2/OlaHsd
MM13	129S/SvEv
MPI 65-3	B6.129P2-Hprt<b-m3>
MPI-12D	129S6/SvEvTac
MPI-12G	129S6/SvEvTac
MPI-17A	129S6/SvEvTac
MPI-17E	129S6/SvEvTac
MPI-48.1	B6.129P2-Hprt<b-m3>
MPI-71.6	B6.129P2-Hprt<b-m3>
MPI-II	129/Sv
MPI53.1	B6.129P2-Hprt<b-m3>
MPI76.11	B6.129P2-Hprt<b-m3>
MRL-+/+ 3	MRL/MpJ
MS12	C57BL/6
N1	C57BL/6
NOD/ShiLtJ #43	NOD/ShiLtJ
P1	129S2/SvPas
Pat5	129X1/SvJ
PB150.18	BALB/cByJ
PB151.24	C3H/HeJ
PB35.17	NZW/LacJ
PB60.6	BTBR T<+> tf/J
PB61.11	MRL/MpJ
PB84.3	FVB/NJ
PC3	129S4/SvJae-Tg(Prm-cre)70Og
PJ1-5	129X1/SvJ
PJ5	129X1/SvJ
R1	(129X1/SvJ x 129S1/Sv)F1-Kitl<+>
REK1	129X1/SvJ
REK2	129X1/SvJ
REK3	129X1/SvJ
REK4	129X1/SvJ
RENKA	C57BL/6N
RF8	129S4/SvJae
RJ2.2	(C57BL/6-Tyr<c-Brd> x 129S6/SvEvTac)F1
RW-4	129X1/SvJ
RW1	129X1/SvJ
SCC10	129X1/SvJ
SI2.3	129S7/SvEvBrd-Hprt<b-m2>
SI6.C21	C57BL/6JCrl
SM1	129S6/SvEvTac
TBV2	129S2/SvPas
TC	129S6/SvEvTac
TC-1	129S6/SvEvTac
TG3	129S6/SvEvTac
TG4	129S6/SvEvTac
TG6	129S6/SvEvTac
TL1/TL-1	129S6/SvEvTac
TT2	(C57BL/6 x CBA)F1
TT2F	(C57BL/6 x CBA)F1
v17.2	(BALB/cJ x 129S4/SvJae)F1
V26.2,ES-MK	C57BL/6
v6.4	(C57BL/6J x 129S4/SvJae)F1
v6.5	(C57BL/6 x 129S4/SvJae)F1
VGB6	C57BL/6NTac
W12	129S6/SvEvTac
W2	129S6/SvEvTac
W3	129S6/SvEvTac
W4	129S6/SvEvTac
W5	129S6/SvEvTac
W9.5/W95	129S1/Sv-Oca2<+> Tyr<+> Kitl<+>
WB6a	C57BL/6
WB6b	C57BL/6
WB6d	C57BL/6NTac
WW6	STOCK 129/Sv and C57BL/6J and SJL
ZX3	129/Sv
