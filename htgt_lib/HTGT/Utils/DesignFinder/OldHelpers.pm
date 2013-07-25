package HTGT::Utils::DesignFinder::OldHelpers;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( has_valid_splicing
                     has_valid_intron_length
                     butfirst
                     butlast
                     exon_3p_utr_length
                     exon_5p_utr_length
                     is_nmd_transcript
               ) ]
};

use HTGT::Utils::DesignFinder::Constants qw( $MIN_VALID_INTRON_LENGTH );
use List::MoreUtils qw( all firstval before_incl after_incl );
use Log::Log4perl qw( :easy );

sub has_valid_splicing {
    my $transcript = shift;

    for my $intron ( @{ $transcript->get_all_Introns } ) {
        my $donor = substr($intron->seq, 0, 2);
        my $acceptor = substr($intron->seq, -2, 2);
        unless ( is_valid_donor_acceptor( $donor, $acceptor ) ) {
            return;            
        }
    }

    return 1;
}

sub is_valid_donor_acceptor {
    my ( $donor, $acceptor ) = @_;

    return ( ( $donor eq 'GT' or $donor eq 'GC' ) and $acceptor eq 'AG' )
        or ( $donor eq 'AT' and $acceptor eq 'AC' );
}

sub has_valid_intron_length {
    my $transcript = shift;

    my @introns = @{ $transcript->get_all_Introns }
        or return 1;

    all { $_->length >= $MIN_VALID_INTRON_LENGTH } @introns;
}

sub exon_3p_utr_length {
    my ( $exon, $transcript ) = @_;

    if ( not $exon->coding_region_start( $transcript ) ) {
        return $exon->length;
    }
    elsif ( $exon->strand == 1 ) {
        return $exon->end - $exon->coding_region_end( $transcript );
    }
    else {
        return $exon->coding_region_start( $transcript ) - $exon->start;
    }
}

sub exon_5p_utr_length {
    my ( $exon, $transcript ) = @_;

    if ( not $exon->coding_region_start( $transcript ) ) {
        return $exon->length;
    }
    elsif ( $exon->strand == 1 ) {
        return $exon->coding_region_start( $transcript ) - $exon->start;
    }
    else {
        return $exon->end - $exon->coding_region_end( $transcript );
    }
}

sub butfirst { @_[ 1 .. $#_ ] }

sub butlast { @_[ 0 .. ( $#_ - 1 ) ] }

sub is_nmd_transcript {
    my $transcript = shift;

    my @exons = @{ $transcript->get_all_Exons };
    
    my $last_exon = pop @exons;
    return if $last_exon->coding_region_start( $transcript );

    my $utr = 0;
    while ( @exons ) {
        my $exon_utr = exon_3p_utr_length( pop @exons, $transcript )
            or last;
        $utr += $exon_utr;
    }

    if ( $utr > 55 ) {
        return 1;
    }
    
    return;
}

1;

__END__

=pod

=head1 NAME

HTGT::Utils::DesignFinder::Helpers

=head1 SYNOPSIS

  use HTGT::Utils::DesignFinder::Helpers;

=head1 DESCRIPTION

This module provides a number of helper functions for the design finder; see L</FUNCTIONS> for details.

=head1 FUNCTIONS

=over 4

=item has_valid_splicing( $transcript )

Returns true if C<$transcript> has valid splicing, otherwise false.

A transcript is condidered to have valid splicing if every
intron has a valid donor/acceptor pair.

=item is_valid_donor_acceptor( $donor, $acceptor )

Returns true if C<$donor>, C<$acceptor> are a valid donor/acceptor pair,
otherwise false. The following pairs are considered valid:

  GT / AG
  GC / AG
  AT / AC

=item has_valid_intron_length( $transcript )

Returns true if every intron in C<$trancript> is at least
C<$MIN_VALID_INTRON_LENGTH> bp, where C<$MIN_VALID_INTRON_LENGTH> is
defined in L<HTGT::Utils::DesignFinder::Constants>.

=item exon_3p_utr_length( $exon, $transcript )

Returns the length of 3' UTR of C<$exon> in C<$transcript>.

For an exon on the forward strand:

  >>>
  XXXXOOOO
     ^   ^
     |   |
     |   +- exon end
     |
     +- coding region end

3' UTR = exon end - coding region end

For an exon on the reverse strand:

       <<<
  OOOOXXXX
  ^   ^
  |   |
  |   +- coding region start
  |
  +- exon start

3' UTR = coding region start - exon start

If the exon is non-coding, then 3' UTR = length of exon.

=item exon_5p_utr_length( $exon, $transcript )

Returns the length of 5' UTR of C<$exon> in C<$transcript>.

=item butfirst( @list )

Return all but the first element of I<@list>.

=item butlast( @list )

Return all but the last element of I<@list>.

=pod

=item is_nmd_transcript( $transcript )

Returns true if I<$transcript> is subject to nonsense mediated decay (NMD).

We consider a transcript to be subject to NMD if a splicing event
occurs more that 55bp after the stop codon:

                     30     30      50
  --//--XXXX----XXXXOOO----OOO---OOOOO
                              ^
                              last splicing event

Here, there are 30+30 = 60bp UTR before the last splicing event, so this
transcript would be subject to NMD.

                    20    20       50
  --//--XXXX----XXXXOO----OO----OOOOO
                            ^
                            last splicing event

Here, there are only 20+20 = 40bp UTR before the last splicing event,
so this transcript would B<not> be subject to NMD.

If the last exon is a coding exon, there is no splicing after the stop
codon, hence no NMD:

  --//--XXXX---XXXXOOOOOOO

=cut
