package HTGT::Utils::DesignFinder::Helpers;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( butfirst
                     butlast
                     exon_3p_utr_length
                     exon_5p_utr_length
               ) ]
};

use Log::Log4perl qw( :easy );

=pod

=head1 NAME

HTGT::Utils::DesignFinder::Helpers

=head1 SYNOPSIS

  use HTGT::Utils::DesignFinder::Helpers;

=head1 DESCRIPTION

This module provides a number of helper functions for the design finder; see L</FUNCTIONS> for details.

=head1 FUNCTIONS

=over 4

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

=cut

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

=pod

=item exon_5p_utr_length( $exon, $transcript )

Returns the length of 5' UTR of C<$exon> in C<$transcript>.

=cut

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

=pod

=item butfirst( @list )

Return all but the first element of C<@list>.

=cut

sub butfirst { @_[ 1 .. $#_ ] }

=pod

=item butlast( @list )

Return all but the last element of C<@list>.

=cut

sub butlast { @_[ 0 .. ( $#_ - 1 ) ] }

1;

__END__
