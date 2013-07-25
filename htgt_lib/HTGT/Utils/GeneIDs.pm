package HTGT::Utils::GeneIDs;

#
# $HeadURL:$
# $LastChangedDate:$
# $LastChangedRevision:$
# $LastChangedBy:$
#

use strict;
use warnings FATAL => 'all';
use SOAP::Lite;
use List::MoreUtils qw(uniq);

use Sub::Exporter -setup => { exports => ['get_gene_ids'] };
use Readonly;
use Try::Tiny;

use HTGT::Utils::MGIWebService;

sub get_gene_ids {
    my ( $mgi_gene, $requested_values ) = @_;

    die "Invalid or no mgi_gene\n" unless ($mgi_gene);

    my $mgi_accession_id = $mgi_gene->mgi_accession_id;
    die "No mgi accession id found for mgi gene" unless ($mgi_accession_id);

    my @requested_output;
    if ($requested_values) {
        @requested_output = @$requested_values;
    }
    else {
        @requested_output = ( 'ensembl', 'vega' );
    }

    my $request = HTGT::Utils::MGIWebService->new();

    my @results;
    my $gene_info
        = $request->get_mgi_gene_info( $mgi_accession_id, @requested_output );
    if ($gene_info) {
        foreach my $result_row (@{$gene_info}) {
            foreach my $gene_info_type ( keys %{$result_row} ) {
                push @results, $result_row->{$gene_info_type};
            }
        }
    }
    else {
        @results = mgi_sanger_genes($mgi_gene); #fallback to mgi_sanger table
    }

    return sort { $a cmp $b } uniq @results;
}

sub mgi_sanger_genes {
    my ($mgi_gene) = @_;

    my $schema = $mgi_gene->result_source->schema;

    my @ensembl_genes = $schema->resultset( 'MGIEnsemblGeneMap' )->search( { mgi_accession_id => $mgi_gene->mgi_accession_id } );
    my @vega_genes    = $schema->resultset( 'MGIVegaGeneMap' )->search( { mgi_accession_id => $mgi_gene->mgi_accession_id } );

    return ( map( $_->ensembl_gene_id, @ensembl_genes ),
             map( $_->vega_gene_id, @vega_genes ) );
}

1;
