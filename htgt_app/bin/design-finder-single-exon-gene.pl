#!/usr/bin/env perl

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-design/trunk/bin/design-finder-single-exon-gene.pl $
# $LastChangedRevision: 3963 $
# $LastChangedDate: 2011-02-11 10:50:24 +0000 (Fri, 11 Feb 2011) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use HTGT::Utils::DesignFinder::SingleExonGene;
use Try::Tiny;
use Log::Log4perl ':easy';
use YAML::Syck 'Dump';
use English qw( -no_match_vars );
use Getopt::Long;

{
    my $log_level = $WARN;
    my $max_designs = 3;
    
    GetOptions(
        'debug'         => sub { $log_level = $DEBUG },
        'verbose'       => sub { $log_level = $INFO },
        'max-designs=i' => \$max_designs,
    ) or die "Usage: $PROGRAM_NAME [OPTIONS]\n";

    Log::Log4perl->easy_init( {
        layout => '%p %x %m%n',
        level  => $log_level
    } );
    
    while ( <> ) {
        chomp( my $ensembl_gene_id = $_ );
        Log::Log4perl::NDC->push( $ensembl_gene_id );        
        try {
            my $df = HTGT::Utils::DesignFinder::SingleExonGene->new( ensembl_gene_id => $ensembl_gene_id,
                                                                     max_designs     => $max_designs );
            my $candidate_designs = $df->find_candidate_insertion_locations;
            print Dump( @{$candidate_designs} );
        }
        catch {
            ERROR( $_ );
        }
        finally {
            Log::Log4perl::NDC->pop;
        };
    }
}
