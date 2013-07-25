package HTGT::Utils::TargRep::Genbank;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'fetch_allele_seq', 'fetch_vector_seq' ] };

use HTGT::Utils::Tarmits;
use IO::String;
use Bio::SeqIO;
use Carp 'confess';

sub fetch_allele_seq {
    my $query_term = shift;

    confess "fetch_allele_seq requires an argument"
        unless defined $query_term;

    my $allele_id;

    if ( $query_term =~ /^\d+$/ ) {
        $allele_id = $query_term;
    }
    else {
        $allele_id = _allele_id( es_cell => $query_term );
    }

    _fetch_seq_for_allele( $allele_id, 'escell_clone' );
}

sub fetch_vector_seq {
    my $query_term = shift;

    confess "fetch_vector_seq requires an argument"
        unless defined $query_term;

    my $allele_id;

    if ( $query_term =~ /^\d+$/ ) {
        $allele_id = $query_term;
    }
    else {
        $allele_id = _allele_id( targeting_vector => $query_term );
    }

    _fetch_seq_for_allele( $allele_id, 'targeting_vector' );
}

{
    my $targ_rep;

    sub targ_rep {
        $targ_rep ||= HTGT::Utils::Tarmits->new_with_config;
    }
}

sub _allele_id {
    my ( $key, $name ) = @_;

    my $method = "find_$key";

    my $res = targ_rep->$method( { name_eq => $name } );

    confess  "failed to retrieve $name from targeting repository"
        unless defined $res
            and ref($res) eq 'ARRAY'
                and @{$res} == 1;

    my $allele_id = $res->[0]->{allele_id}
        or confess "failed to retrieve allele_id for $name";

    return $allele_id;
}

sub _fetch_seq_for_allele {
    my ( $allele_id, $what ) = @_;

    my $gbk = targ_rep->find_genbank_file( { allele_id => $allele_id } );

    confess "failed to retrieve GenBank file for allele $allele_id"
        unless defined $gbk
            and ref($gbk) eq 'ARRAY'
                and @{$gbk} == 1
                    and $gbk->[0]->{escell_clone};

    return Bio::SeqIO->new(
        -format => 'genbank',
        -fh     => IO::String->new( $gbk->[0]->{$what} )
    )->next_seq;
}

1;

__END__
