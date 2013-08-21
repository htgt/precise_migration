#!/usr/bin/env perl

use strict; 
use warnings FATAL => 'all';

use HTGT::DBFactory;
use HTGT::Utils::Recovery::StateUpdater;
use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use Readonly;

my ( $htgt, $commit, $parallel ) = init();

my $updater = HTGT::Utils::Recovery::StateUpdater->new( schema => $htgt, commit => $commit );

if ( @ARGV ) {
    for my $mgi_gene_id ( map mgi_gene_id( $_ ), @ARGV ) {
        $updater->update_gene( $mgi_gene_id );
    }
}
elsif ( $parallel > 1 ) {
    run_in_parallel( $updater, $parallel );
}
else {
    $updater->update_all_genes;
}

sub run_in_parallel {
    my ( $updater, $num_procs ) = @_;

    for my $n ( 1 .. $num_procs ) {
        defined( my $pid = fork )
            or die "fork failed: $!";
        if ( $pid == 0 ) { # child
            exit $updater->update_all_genes( sub { $_[0] % $num_procs == $n - 1 } );
        }
    }

    my $exit_code = 0;
    while ( ( my $pid = wait ) > 0 ) {
        my $child_exit_code = $? >> 8;
        warn "Process $pid exit $child_exit_code\n";
        $exit_code ||= $child_exit_code;
    }
    exit $exit_code;
}

sub init {

    my $log_level = $WARN;

    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
        'parallel=i' => \my $parallel,
        'commit'     => \my $commit,
    ) or pod2usage(2);

    Log::Log4perl->easy_init( {
        level  => $log_level,
        layout => '[%P] mgi_gene_id=%X{mgi_gene_id}, inital_state=%X{initial_state} %p %m%n',
    } );

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );
    DEBUG( "Connected to " . $htgt->storage->dbh->{Name} );

    return ( $htgt, $commit, $parallel || 0 );
}

sub mgi_gene_id {
    my $search_term = shift;

    if ( $search_term =~ qr/^\d+$/ ) {
        return $search_term;
    }

    my %query;
    if ( $search_term =~ qr/^MGI:\d+$/ ) {
        $query{ mgi_accession_id } = $search_term;
    }
    else {
        $query{ marker_symbol } = $search_term;
    }
    
    my @mgi_genes = $htgt->resultset( 'MGIGene' )->search( \%query );

    unless ( @mgi_genes == 1 ) {
        die sprintf( 'found %d match%s for %s', scalar @mgi_genes, @mgi_genes == 1 ? '' : 's', $search_term );
    }

    (shift @mgi_genes)->mgi_gene_id;
}


__END__

=head1 NAME

update_gene_recovery_state.pl - update gr_gene_status and related tables

=head1 SYNOPSIS

   update_gene_recovery_state.pl [OPTIONS]

   Options:

     --help          Show a brief help message
     --man           Display the manual page
     --debug         Log debug messages
     --verbose       Log info messages
     --parallel=NUM  Run NUM processes in parallel
     --commit        Commit changes to the database (default is to rollback)

=head1 DESCRIPTION

This script determines the current state of genes for recovery and
updates the gr_gene_status and related tables.

=head1 AUTHOR

Ray Miller, E<lt>rm7@hpgen-1-14.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
