#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Const::Fast;
use Getopt::Long;

use Smart::Comments;

my $new_gene_build_name = 'mus_musculus_core_59_37l';

GetOptions(
    'new-gene-build=s' => \$new_gene_build_name,
    'commit'           => \my $commit,
    )
    and @ARGV
    or die "Usage: $0 [--new-gene-build=GENE_BUILD_NAME] [--commit] DESIGN_ID\n";

my $htgt = HTGT::DBFactory->connect('eucomm_vector');

$htgt->txn_do(
    sub {
        my $new_gene_build = $htgt->resultset('GnmGeneBuild')->find( { name => $new_gene_build_name } )
            or die "failed to retrieve gene build $new_gene_build_name";

        for my $design_id (@ARGV) {
            migrate_design( $design_id, $new_gene_build );
        }

        unless ($commit) {
            warn "Rollback\n";
            $htgt->txn_rollback;
        }
    }
);

sub migrate_design {
    my ( $design_id, $new_gene_build ) = @_;

    my $design = $htgt->resultset('Design')->find( { design_id => $design_id } )
        or die "failed to retrieve design $design_id\n";

    my $cur_gene_build    = $design->gene_build->name;
    my $cur_start_exon_id = $design->start_exon->primary_name;
    my $cur_end_exon_id   = $design->end_exon->primary_name;
    my $cur_gene          = $design->start_exon->transcript->gene_build_gene;

    ### Current gene build: $cur_gene_build
    ### Current gene_build_gene: $cur_gene->primary_name
    ### Current start exon: $cur_start_exon_id
    ### Current end exon: $cur_end_exon_id

    my $new_start_exon = get_gene_build_exon( $new_gene_build, $cur_start_exon_id );
    my $new_end_exon   = get_gene_build_exon( $new_gene_build, $cur_end_exon_id );

    warn "Migrating design " . $design->design_id . " from build $cur_gene_build to $new_gene_build_name\n";
    $design->update(
        {   gene_build_id => $new_gene_build->id,
            start_exon_id => $new_start_exon->id,
            end_exon_id   => $new_end_exon->id,
        }
    );
}

sub get_gene_build_exon {
    my ( $gene_build, $exon_primary_name ) = @_;

    my @exons = $htgt->resultset('GnmExon')->search(
        {   'me.primary_name' => $exon_primary_name,
            'gene_build.id'   => $gene_build->id
        },
        { join => { transcript => { gene_build_gene => 'gene_build' } } }
    );

    die 'found ' . @exons . ' exons with primary name ' . $exon_primary_name . ' in build ' . $gene_build->name . "\n"
        unless @exons == 1;

    return shift @exons;
}
