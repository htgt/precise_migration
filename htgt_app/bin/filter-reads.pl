#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/HTGT-QC/trunk/bin/filter-reads.pl $
# $LastChangedRevision: 5689 $
# $LastChangedDate: 2011-08-19 17:07:01 +0100 (Fri, 19 Aug 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use HTGT::QC::Util::ParseCigar;
use List::Util qw( sum reduce );
use List::MoreUtils qw( uniq );
use Log::Log4perl ':easy';

# When counting number of primers that align to a target, ignore alignments shorter than this
const my $MIN_ALIGN_LENGTH => 200;

# The relative score is target score / best score. If the relative
# score for a target is greater than or equal to this cutoff, the
# appropriate cigar sequences are output for analysis.
const my $RELATIVE_SCORE_CUTOFF => 0.8;

{

    my $log_level = $WARN;
    
    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
    ) or pod2usage(2);

    Log::Log4perl->easy_init( { level => $log_level } );    
    
    # XXX Input *must* be sorted on query_id
    my $ifh = IO::Handle->new->fdopen( fileno(STDIN), 'r' )
        or die "dup STDIN: $!";

    my $cigar = next_cigar( $ifh );

    while ( $cigar ) {
        my @cigars = ( $cigar );
        my $next = next_cigar( $ifh );
        while ( $next && $next->{query_well} eq $cigar->{query_well} ) {
            push @cigars, $next;
            $next = next_cigar( $ifh );
        }
        process_cigars_for_well( $cigar->{query_well}, \@cigars );
        $cigar = $next;
    }
}

sub next_cigar {
    my $ifh = shift;

    my $cigar = $ifh->getline
        or return;

    parse_cigar( $cigar );
}

sub best_reads_for_target {
    my ( $target, $cigars ) = @_;

    # Filter the cigars for this target, and group by primer
    my %cigars_for_primer;
    for my $cigar ( grep { $_->{target_id} eq $target } @{$cigars} ) {
        push @{ $cigars_for_primer{ $cigar->{query_primer} } }, $cigar;
    }

    # Now pick the highest-scoring read for each primer
    my %best_read_for_primer;
    for my $primer ( keys %cigars_for_primer ) {
        $best_read_for_primer{$primer} = reduce { $a->{score} > $b->{score} ? $a : $b } @{ $cigars_for_primer{$primer} };
    }

    return \%best_read_for_primer;
}

sub debug_rankings {
    return unless get_logger->is_debug;
    my ( $well, $cigar_for, $score_for, $ranked_targets ) = @_;

    for my $target ( @{$ranked_targets} ) {
        my $cigars = $cigar_for->{$target};
        DEBUG( sprintf( '%s %s %d %s', $well, $target, $score_for->{$target},
                        join( q{, }, map { "$_ => $cigars->{$_}{score}" } sort keys %{$cigars} ) ) );
    }
}

sub emit_cigars {
    my ( $well, $target, $cigars ) = @_;

    print "$_->{raw}\n" for values %{$cigars};
}

sub process_cigars_for_well {
    my ( $well, $cigars ) = @_;

    my %cigars_for;
    my %score_for;
    my %num_primers_for;

    for my $target ( uniq map { $_->{target_id} } @{$cigars} ) {
        $cigars_for{ $target } = best_reads_for_target( $target, $cigars );
        my @significant_reads  = grep { $_->{length} >= $MIN_ALIGN_LENGTH } values %{ $cigars_for{$target} };
        next unless @significant_reads;
        $score_for{ $target }       = sum( 0, map { $_->{score} } @significant_reads );    
        $num_primers_for{ $target } = @significant_reads;
    }

    my @ranked_on_score   = reverse sort { $score_for{$a} <=> $score_for{$b}
                                               || $num_primers_for{$a} <=> $num_primers_for{$b} } keys %score_for;
    debug_rankings( $well, \%cigars_for, \%score_for, \@ranked_on_score );    

    my @to_emit;

    if ( @ranked_on_score == 1 ) {
        push @to_emit, $ranked_on_score[0];
    }
    elsif ( @ranked_on_score > 1 ) {
        my $best_score = $score_for{ $ranked_on_score[0] };
        for my $target ( @ranked_on_score ) {
            my $target_score = $score_for{ $target };
            my $relative_score = $target_score / $best_score;
            last unless $relative_score >= $RELATIVE_SCORE_CUTOFF;
            push @to_emit, $target;
        }
    }

    if ( @to_emit >= 1 and @to_emit <= 4 ) {
        emit_cigars( $well, $_, $cigars_for{ $_ } ) for @to_emit;
    }
    else {
        WARN @to_emit . " alignments for $well";
    }
}

__END__

=head1 NAME

find-best-reads.pl - Describe the usage of script briefly

=head1 SYNOPSIS

find-best-reads.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for find-best-reads.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
