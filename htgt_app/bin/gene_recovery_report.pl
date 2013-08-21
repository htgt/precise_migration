#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/bin/gene_recovery_report.pl $
# $LastChangedRevision: 1712 $
# $LastChangedDate: 2010-05-13 11:33:30 +0100 (Thu, 13 May 2010) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use File::Temp;
use HTGT::DBFactory;
use HTGT::Utils::Recovery::Constants qw( @REPORTS );
use Log::Log4perl ':easy';
use CSV::Writer;

my $log_level = $WARN;
my $max_parallel = 10;

GetOptions(
    help     => sub { pod2usage( -verbose => 1 ) },
    man      => sub { pod2usage( -verbose => 2 ) },
    debug    => sub { $log_level = $DEBUG },
    verbose  => sub { $log_level = $INFO },
    parallel => \$max_parallel,
) or pod2usage( 2 );

Log::Log4perl->easy_init( $log_level );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my @todo;
if ( @ARGV ) {
    my %wanted = map { $_ => 1 } @ARGV;
    @todo = grep $wanted{ $_->{action} }, map @{ $_->{reports} }, @REPORTS;    
}
else {
    @todo = map @{ $_->{reports} }, @REPORTS;    
}

my $nfail = 0;
my $num_kids = 0;
while ( @todo ) {
    while ( @todo and $num_kids < $max_parallel ) {
        my $report = shift @todo;
        defined( my $pid = fork() )
            or die "fork: $!";        
        if ( $pid == 0 ) {
            generate_report( $report );
            exit;
        }
        $num_kids++;
        INFO( "$pid generating $report->{name}" );        
    }
    if ( ( my $pid = wait() ) > 0 ) {
        INFO( "$pid exit $?" );
        $nfail++ if $? >> 8;
        $num_kids--;
    }
}
while ( ( my $pid = wait() ) > 0 ) {
    INFO( "$pid exit $?" );
    $nfail++ if $? >> 8;
}

if ( $nfail ) {
    die "failed to generate $nfail reports\n";
}
else {
    exit 0;
}

sub generate_report {
    my $report = shift;

    warn "$$ generating $report->{name}\n";

    for ( qw(HUP INT PIPE TERM) ) {
        $SIG{$_} = sub { die "caught signal $_" };        
    }
    
    my $handler = $report->{class};
    
    eval "require $handler"
        or die "load $handler: $@";

    my $tmp = File::Temp->new( DIR => '.' )
        or die "create tmp file: $!";
    
    my $it = $handler->new( schema => $htgt );

    my @columns = $it->columns;

    my $csv = CSV::Writer->new( columns => \@columns, output => $tmp );

    $csv->write( \@columns );

    while ( $it->has_next ) {
        $csv->write( $it->next_record );
    }
    
    chmod 0644, $tmp
        or die "chmod $tmp: $!";

    $tmp->close
        or die "close $tmp: $!";

    rename $tmp, $report->{action} . '.csv'
        or die "rename $tmp to $report->{action}.csv: $!";

    warn "$$ done\n";
}

__END__
=pod

=head1 NAME

gene_recovery_report.pl

=head1 SYNOPSIS

  gene_recovery_report.pl [OPTIONS] REPORT

  Options:
    --help       Display a brief help message
    --man        Display the manual
    --debug      Log debug messages
    --verbose    Log informational messages
    --parallel   Number of processes to run in parallel (default 10)

=head1 DESCRIPTION

Produces the requested report in CSV format.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Genome Research Ltd

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
