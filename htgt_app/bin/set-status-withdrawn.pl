#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Perl6::Slurp 'slurp';
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Getopt::Long;

{
    my $log_level = $WARN;

    GetOptions(
        debug   => sub { $log_level = $DEBUG },
        verbose => sub { $log_level = $INFO },
        commit  => \my $commit
    ) or die "Usage: $0 [--debug|--verbose|--commit] [ENSEMBL_GENE_ID ...]\n";

    my @ensembl_gene_ids = @ARGV ? @ARGV : slurp( \*STDIN, { chomp => 1 } );

    Log::Log4perl->easy_init( {
        level  => $log_level,
        layout => '%x %m%n'
    } );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my $init_status = $htgt->resultset( 'ProjectStatus' )->find( { name => 'VEGA Annotation Requested' } )
        or die 'failed to retrieve project status VEGA Annotation Requested';
    my $desired_status = $htgt->resultset( 'ProjectStatus' )->find( { name => 'Withdrawn From Pipeline' } )
        or die 'failed to retrieve project status Withdrawn From Pipeline';
    
    $htgt->txn_do(
        sub {
            for my $e ( @ensembl_gene_ids ) {
                Log::Log4perl::NDC->push( $e );
                update_project_status( $htgt, $e, $init_status, $desired_status );
                Log::Log4perl::NDC->pop;
            }
            unless ( $commit ) {
                warn "Rollback\n";
                $htgt->txn_rollback;
            }
        }
    );    
}

sub update_project_status {
    my ( $htgt, $ens_gene_id, $init_status, $desired_status ) = @_;

    my $mgi_gene_rs = $htgt->resultset( 'MGIGene' )->search( { ensembl_gene_id => $ens_gene_id } );
    unless ( $mgi_gene_rs->count > 0 ) {
        ERROR( "Failed to retrieve MGIGene" );
        return;
    }

    my $projects_rs = $mgi_gene_rs->search_related(
        'projects', {
            is_eucomm         => 1,
            project_status_id => $init_status->project_status_id
        }
    );
    unless ( $projects_rs->count > 0 ) {
        ERROR( "No projects with status " . $init_status->name );
        return;
    }

    while ( my $project = $projects_rs->next ) {
        INFO( "Setting status of project " . $project->project_id . " to " . $desired_status->name );        
        $project->update( {
            project_status_id => $desired_status->project_status_id,
            edit_user         => $ENV{USER},
            edit_date         => \'current_timestamp'
        } );
    }
}
