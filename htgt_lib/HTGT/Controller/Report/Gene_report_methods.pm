package HTGT::Controller::Report::Gene_report_methods;

use warnings;
use strict;
use base 'Catalyst::Controller';

=head1 NAME

HTGT::Controller::Report::Gene_report_methods

=head1 AUTHOR

Dan Klose dk3@sanger.ac.uk

=cut

=head2 index 

=cut

require Exporter;
our @ISA     = qw(Exporter);
#The methods that we want to export
our @EXPORT  = qw(
                get_gene_information    
); 

sub get_gene_information {
    my ( $self, $c, $gene_name, $gene_id ) = @_;
    my %gene = ();
    my $dbh  = $c->model(q(HTGTDB))->storage->dbh;
    
    my @headers = qw( Primary_Name Ensembl_ID Otter_ID );
    
    my %q = (
        get_gene_name => "select distinct primary_name from mig.gnm_gene  where id = ?",
        
        check_gene_name => "select distinct gn.name from mig.gnm_gene_name gn where lower(gn.name) = lower(?)",
        
        get_gene_id => (q/
            select distinct gn.gene_id, gn.name, gg.primary_name
            from mig.gnm_gene_name gn,
            mig.gnm_gene_2_gene_build_gene g2gbg,
            mig.gnm_gene gg
            where lower(gn.name) like lower(?)
            and gn.gene_id = g2gbg.gene_id
            and gg.id = gn.gene_id
            /),
            
        get_ens_ott => (q/
            select distinct gene_id, gbgn.name
            from mig.gnm_gene_2_gene_build_gene g2gbg,
            mig.gnm_gene_build_gene_name gbgn
            where g2gbg.gene_id = ?
            and gbgn.gene_build_gene_id = g2gbg.gene_build_gene_id
            and gbgn.source = 'Ensembl_ID'
            /),
    );
       
    if ( $gene_id =~ /^\d+$/ or ( defined $gene_name and defined $gene_id ) ) {    
        my $get_name = $dbh->prepare( $q{get_gene_name} );
        $get_name->execute( $gene_id );
        $gene{Gene_Name} = $get_name->fetchall_arrayref()->[0][0];
        $gene{Primary_Name}=$gene{Gene_Name};        
        $c->req->params->{gene_name} = $gene{Gene_Name};        
        $gene{Gene_ID} = $gene_id;
        $gene_name = $gene{Gene_Name};
    }        
    else {
        my $get_gene_id_e = $dbh->prepare( $q{get_gene_id} );
        $get_gene_id_e->execute( $gene_name );
        while ( my $r = $get_gene_id_e->fetchrow_arrayref() ) {
            $gene{Gene_ID}=$r->[0];
            $gene{Gene_Name}=$r->[1];
            $gene{Primary_Name}=$r->[2];
        }
    } 
            
    my $gene_name_check = $dbh->prepare( $q{check_gene_name} );
    $gene_name_check->execute( $gene{Gene_Name} );
    my $check = $gene_name_check->fetchall_arrayref()->[0][0];
    if ( ! $check ) { return() }        
            
    $c->req->params->{gene_id}   = $gene{Gene_ID};
    $c->req->params->{gene_name} = $gene{Gene_Name};
    
    my $get_ens_ott_e = $dbh->prepare( $q{get_ens_ott} );
    $get_ens_ott_e->execute( $gene{Gene_ID} );
        
    while ( my $rs = $get_ens_ott_e->fetchrow_arrayref() ) {
        if ( defined $rs->[1] ) {
            if ( $rs->[1] =~ /ens/i ) {
                $gene{Ensembl_ID}=$rs->[1];
            }
            else {
                $gene{Otter_ID}=$rs->[1];                    
            }
        }
    }

    return( \%gene, \@headers );
}

sub clean_row {
    my ( $array_ref ) = @_;
    for ( @$array_ref ) { 
        if ( ! defined ) { $_ = '-' }
    }
}
