package HTGT::Utils::Recovery::GeneHistory;
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/lib/HTGT/Utils/Recovery/GeneHistory.pm $
# $LastChangedRevision: 1672 $
# $LastChangedDate: 2010-05-11 09:34:16 +0100 (Tue, 11 May 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'get_gene_recovery_history' ] };
use Carp 'confess';

sub get_gene_recovery_history {
    my ( $schema, $search_term ) = @_;

    my $mgi_gene_id = get_mgi_gene_id( $schema, $search_term );

    my $history_rs = $schema->resultset( 'GRGeneStatusHistory' )->search(
        {
            mgi_gene_id => $mgi_gene_id
        },
        {
            order_by => { -desc => 'updated' }
        }
    );

    my @history;

    while ( my $h = $history_rs->next ) {
        push @history, {
            state   => $h->state,
            desc    => $h->status->description,
            updated => $h->updated,
            note    => $h->note
        };
    }

    return \@history;
}

sub get_mgi_gene_id {
    my ( $schema, $search_term ) = @_;

    if ( ref $search_term eq 'HTGTDB::MGIGene' ) {
        return $search_term->mgi_gene_id;
    }

    confess "search for " . ref( $search_term ) . " not supported"
        if ref $search_term;

    if ( $search_term =~ /^\d+$/ ) {
        return $search_term;
    }

    my %search;
   
    if ( $search_term =~ /^MGI:\d+$/ ) {
        $search{ mgi_accession_id } = $search_term;
    }
    else {
        $search{ marker_symbol } = $search_term;
    }

    my $mgi_gene = $schema->resultset( 'MGIGene' )->find( \%search )
        or confess "search for %search failed";

    return $mgi_gene->mgi_gene_id;
}

1;

__END__
