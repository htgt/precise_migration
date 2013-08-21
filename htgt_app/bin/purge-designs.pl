#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-design/trunk/bin/purge-designs.pl $
# $LastChangedRevision: 4754 $
# $LastChangedDate: 2011-04-14 14:49:05 +0100 (Thu, 14 Apr 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::Utils::Design::Delete 'delete_design';
use Log::Log4perl ':easy';
use Const::Fast;
use Try::Tiny;

const my $MGI_GENE_DESIGN_QUERY => <<'EOT';
select distinct mgi_gene.mgi_accession_id, design.design_id
from mig.gnm_gene_build_gene
join mig.gnm_gene_build
    on gnm_gene_build.id = gnm_gene_build_gene.build_id
join mig.gnm_transcript
    on gnm_gene_build_gene.id = gnm_transcript.build_gene_id
join mig.gnm_exon
    on gnm_exon.transcript_id = gnm_transcript.id
join design
    on design.start_exon_id = gnm_exon.id
   and design.gene_build_id = gnm_gene_build.id
join mgi_gene
    on ( mgi_gene.ensembl_gene_id = gnm_gene_build_gene.primary_name
        or mgi_gene.vega_gene_id  = gnm_gene_build_gene.primary_name
        or mgi_gene.entrez_gene_id = gnm_gene_build_gene.primary_name )
where design.start_exon_id is not null
and gnm_gene_build_gene.primary_name is not null
and design.created_user in ( 'rm7', 'vvi', 'wy1', 'dk3' )
order by mgi_gene.mgi_accession_id
EOT

const my $RECENT_DESIGN_TAG    => qr/rm7\.2010-11/;

const my $AUTOMATIC_DESIGN_TAG => qr/(?:rm7|DAN|design-finder)/; # XXX this needs to be generalized

{
    
    my $log_level = $WARN;

    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
        'commit'     => \my $commit,
    ) or pod2usage(2);

    Log::Log4perl->easy_init(
        {
            level  => $log_level,
            layout => '%p - %m%n'
        }
    );
    
    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    purge_unused_designs( $htgt, $commit );
}

sub purge_unused_designs {
    my ( $htgt, $commit ) = @_;

    my $sth = $htgt->storage->dbh->prepare( $MGI_GENE_DESIGN_QUERY );
    $sth->execute;
    
    my $row = $sth->fetchrow_arrayref;
    while ( $row ) {
        my ( $mgi_accession_id, @design_ids ) = @$row;
        $row = $sth->fetchrow_arrayref;
        while ( $row and $row->[0] eq $mgi_accession_id ) {
            push @design_ids, $row->[1];
            $row = $sth->fetchrow_arrayref;
        }
        $htgt->txn_do(
            sub {
                purge_unused_designs_for_gene( $htgt, $mgi_accession_id, \@design_ids );
                unless ( $commit ) {
                    INFO( "Rollback" );
                    $htgt->txn_rollback;
                }
            }
        );        
    }
}

sub purge_unused_designs_for_gene {
    my ( $htgt, $mgi_accession_id, $design_ids ) = @_;

    DEBUG( "purge unused designs: $mgi_accession_id (@$design_ids)" );
    
    my $designs_rs = $htgt->resultset( 'Design' )->search(
        {
            'me.design_id'                    => $design_ids,
            'design_parameter.parameter_name' => 'custom knockout'                
        },
        {
            join => 'design_parameter'
        }
    );
    
    my ( @recent, @automatic );
    while ( my $design = $designs_rs->next ) {        
        my $pv = $design->design_parameter->parameter_value || '';
        my ( $score ) = $pv =~ m/score=([^,]+)/;
        $score =~ s/\s+$//;
        if ( $score =~ $RECENT_DESIGN_TAG ) {
            DEBUG( "Design " . $design->design_id . " with score $score is recent" );
            push @recent, $design;
        }
        elsif ( $score =~ $AUTOMATIC_DESIGN_TAG ) {
            DEBUG( "Design " . $design->design_id . " with score $score is automatic" );
            if ( $design->projects_rs->count > 0 ) {
                DEBUG( "Design " . $design->design_id . " has been allocated to a project" );
            }
            elsif ( $design->design_instances_rs->count > 0 ) {
                DEBUG( "Design " . $design->design_id . " has design instances" );
            }
            else {
                push @automatic, $design;
            }
        }
        else {
            DEBUG( "Design " . $design->design_id . " with score $score is not an automatic design" );
        }
    }
    
    if ( @recent and @automatic ) {
        INFO( sprintf( '%s has %d recent designs: deleting %d old unallocated designs',
                       $mgi_accession_id, scalar @recent, scalar @automatic ) );
        for my $design ( @automatic ) {
            try {
                delete_design( $design );
            } catch {
                ERROR( $_ );
            };
        }
    }
    else {
        DEBUG( "$mgi_accession_id has no automatic designs to purge" );
    }
}

__END__

=head1 NAME

purge-designs.pl - Describe the usage of script briefly

=head1 SYNOPSIS

purge-designs.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for purge-designs.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
