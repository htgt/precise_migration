#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-design/trunk/bin/change-ensembl-locus.pl $
# $LastChangedRevision: 4756 $
# $LastChangedDate: 2011-04-14 16:43:51 +0100 (Thu, 14 Apr 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::Utils::EnsEMBL;
use Term::Query qw( query );
use Try::Tiny;
use Const::Fast;

const my $GENE_BUILD => 'mus_musculus_core_61_37n';

GetOptions(
    'help'       => sub { pod2usage( -verbose => 1 ) },
    'man'        => sub { pod2usage( -verbose => 2 ) },
) and @ARGV == 1 or pod2usage(2);

my $design_id = shift @ARGV;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

$htgt->txn_do( \&change_ens_locus_of_design, $design_id );

exit;

sub change_ens_locus_of_design {
    my $design_id = shift;

    my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
        or pod2usage( "Failed to retrieve design $design_id" );

    my $current_locus = get_current_locus( $design );
    
    my $targeted_transcripts = get_targeted_transcripts( $design );
    
    my $selected_index = get_user_choice( $current_locus, $targeted_transcripts );

    if ( $selected_index < 0 ) {
        warn "Aborted\n";
        return;
    }

    my ( $start_exon_id, $end_exon_id ) = get_exon_ids( $targeted_transcripts->[$selected_index] );

    print "Updating design $design_id\n";
    $design->update(
        {
            start_exon_id => $start_exon_id,
            end_exon_id   => $end_exon_id
        }
    );

    my $response = query( "Commit changes?", 'N' );
    unless ( $response eq 'yes' ) {
        warn "Rollback\n";
        $htgt->txn_rollback;
    }
}

sub get_current_locus {
    my $design = shift;

    my %current_locus;

    try {
        $current_locus{ start_exon } = $design->start_exon->primary_name;
        $current_locus{ end_exon   } = $design->end_exon->primary_name;
        $current_locus{ transcript } = $design->start_exon->transcript->primary_name;
        $current_locus{ gene       } = $design->start_exon->transcript->gene_build_gene->primary_name;
    }
    catch {
        warn "Failed to determine current locus for $design_id: $_";
    };

    return \%current_locus;
}

sub get_targeted_transcripts {
    my $design = shift;

    my $transcript_adaptor = HTGT::Utils::EnsEMBL->transcript_adaptor;
    my $gene_adaptor       = HTGT::Utils::EnsEMBL->gene_adaptor;

    my $target_start = $design->info->target_region_start;
    my $target_end   = $design->info->target_region_end;
    
    my %targeted_transcripts;
    for my $exon ( @{ $design->info->target_region_slice->get_all_Exons } ) {
        my $transcripts = $transcript_adaptor->fetch_all_by_exon_stable_id( $exon->stable_id );
        for my $t ( grep { $_->biotype eq 'protein_coding' } @{$transcripts} ) {
            next if $targeted_transcripts{ $t->stable_id };
            my @overlapping_exons = grep {
                $_->seq_region_end > $target_start and $_->seq_region_start < $target_end
            } @{ $t->get_all_Exons };
            $targeted_transcripts{ $t->stable_id } = {
                transcript => $t,
                gene       => $gene_adaptor->fetch_by_transcript_stable_id( $t->stable_id ),
                start_exon => $overlapping_exons[0],
                end_exon   => $overlapping_exons[-1]
            };            
        }
    }

    return [
        sort {
            $a->{gene}->stable_id cmp $b->{gene}->stable_id
                || $b->{transcript}->translation->length <=> $a->{transcript}->translation->length
            } values %targeted_transcripts
    ];
}

sub get_user_choice {
    my ( $current_locus, $targeted_transcripts ) = @_;

    # Filter out the current locus from the list of targeted transcripts
    my @candidates = grep {
        $_->{gene}->stable_id ne $current_locus->{gene}
            || $_->{transcript}->stable_id ne $current_locus->{transcript}
                || $_->{start_exon}->stable_id ne $current_locus->{start_exon}
                    || $_->{end_exon}->stable_id ne $current_locus->{end_exon}
                } @{ $targeted_transcripts };
    
    # The current locus is invalid if we didn't filter out anything above
    my $maybe_valid = @candidates == @{$targeted_transcripts} ? 'INVALID' : 'VALID';

    print <<"EOT";
Considering design $design_id, currently mapped to:
$current_locus->{gene} - exons $current_locus->{start_exon} to $current_locus->{end_exon} of $current_locus->{transcript}
This mapping is $maybe_valid.
EOT

    if ( @candidates == 0 ) {
        print "There are no valid alternative candidate transcripts for this design\n";
        return -1;
    }

    print "Possible targets:\n";
    my $count = 0;
    for my $target ( @candidates ) {
        $count++;
        printf( "%d. %s (%s) exons %s - %s of %s (%d aa)\n",
                $count,
                $target->{gene}->stable_id,
                $target->{gene}->external_name,
                $target->{start_exon}->stable_id,
                $target->{end_exon}->stable_id,
                $target->{transcript}->stable_id,
                $target->{transcript}->translation->length,
            );
    }

    my $choice = query( "Please enter a number between 1 and $count, or 0 to quit:",
                        'isah',
                        sub {
                            my $input = shift;
                            return $$input >= 0 && $$input <= $count;
                        },
                        "To map the design to a new locus, please enter the number of a locus\n"
                       ."entered above.  To leave unchanged and quit this program, enter 0\n"
                    );

    return --$choice;
}

sub get_exon_ids {
    my $target = shift;

    my $gene_id       = $target->{gene}->stable_id;
    my $transcript_id = $target->{transcript}->stable_id;
    my $start_exon_id = $target->{start_exon}->stable_id;
    my $end_exon_id   = $target->{end_exon}->stable_id;

    my $gnm_transcript = $htgt->resultset( 'GnmTranscript' )->find(
        {
            'me.primary_name'              => $transcript_id,
            'gene_build_gene.primary_name' => $gene_id,
            'gene_build.name'              => $GENE_BUILD
        },
        {
            join => { gene_build_gene => 'gene_build' }
        }
    ) or die "Failed to retrieve $transcript_id from build $GENE_BUILD\n";

    my $start_exon = get_exon( $gnm_transcript, $start_exon_id );
    my $end_exon   = $start_exon_id eq $end_exon_id ? $start_exon : get_exon( $gnm_transcript, $end_exon_id );    

    return ( $start_exon->id, $end_exon->id );
}

sub get_exon {
    my ( $gnm_transcript, $exon_id ) = @_;

    my @exons = $gnm_transcript->search_related( 'exons', { 'me.primary_name' => $exon_id } );

    die "Failed to retrieve exon $exon_id\n" unless @exons;

    return shift @exons;
}


__END__

=head1 NAME

change-ensembl-locus.pl - Describe the usage of script briefly

=head1 SYNOPSIS

change-ensembl-locus.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for change-ensembl-locus.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
