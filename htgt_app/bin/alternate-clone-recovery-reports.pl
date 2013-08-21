#!/usr/bin/env perl
# alternate-clone-recovery-reports.pl --- Generate alternate clone recovery report data (CSV)
# Author: Ray Miller <rm7@htgt-web.internal.sanger.ac.uk>
# 
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/bin/alternate-clone-recovery-reports.pl $
# $LastChangedRevision: 1214 $
# $LastChangedDate: 2010-03-03 12:22:52 +0000 (Wed, 03 Mar 2010) $
# $LastChangedBy: rm7 $

use warnings FATAL => 'all';
use strict;

use File::Spec;
use IO::File;
use Getopt::Long;
use Log::Log4perl;
use Log::Log4perl::Level;
use Pod::Usage;
use Readonly;
use Text::CSV_XS;

use HTGT::Utils::Recovery::AlternateCloneRecovery;
use HTGT::BioMart::QueryFactory;
use HTGT::DBFactory;

Readonly my %IDCC_MART => (
    martservice => 'http://www.i-dcc.org/biomart/martservice',
);

Readonly my %REPORTS => (
    with_promoter    => {
        filename => 'alternate_clone_recovery_promoter.csv',
        columns  => HTGT::Utils::Recovery::AlternateCloneRecovery->RecoveryDataColumns
    },
    without_promoter => {
        filename => 'alternate_clone_recovery_promoterless.csv',
        columns  => HTGT::Utils::Recovery::AlternateCloneRecovery->RecoveryDataColumns
    },
    no_alternates    => {
        filename => 'alternate_clone_recovery_no_alternates.csv',
        columns  => [ grep !/^pgdgr_/, @{ HTGT::Utils::Recovery::AlternateCloneRecovery->RecoveryDataColumns } ]
    },
    in_recovery      => {
        filename => 'alternate_clone_recovery_in_recovery.csv',
        columns  => HTGT::Utils::Recovery::AlternateCloneRecovery->RecoveryDataColumns
    },
);

my $loglevel = $WARN;
GetOptions(
    'help'      => sub { pod2usage( -verbose => 1 ) },
    'man'       => sub { pod2usage( -verbose => 2 ) },
    'debug'     => sub { $loglevel = $DEBUG },
    'verbose'   => sub { $loglevel = $INFO },
    'destdir=s' => \my $destdir,
) or pod2usage( 2 );

$destdir = '.' unless defined $destdir;

Log::Log4perl->easy_init( level => $loglevel, layout => '%d %p %m%n' );

my $acr = HTGT::Utils::Recovery::AlternateCloneRecovery->new(
    htgtdb_schema => HTGT::DBConnect->connect( 'eucomm_vector' ),
    idcc_mart     => HTGT::BioMart::QueryFactory->new( \%IDCC_MART ),
);

my $data = $acr->get_recovery_data;

my $csv = Text::CSV_XS->new( { eol => "\n" } );

for my $report ( keys %REPORTS ) {

    my $columns = $REPORTS{ $report }->{columns};
    my $filename = File::Spec->catfile( $destdir, $REPORTS{ $report }->{filename} );
    my $tmpfile  = "$filename.new";

    my $tmp = IO::File->new( $tmpfile, O_RDWR|O_CREAT|O_EXCL, 0664 )
        or die "create $tmpfile: $!";

    $csv->print( $tmp, $columns )
        or die "write $tmpfile: $!";

    for my $row ( @{ $data->{ $report } } ) {
        $csv->print( $tmp, [ @{ $row }{ @{ $columns } } ] )
            or die "write $tmpfile: $!";
    }

    $tmp->close
        or die "close $tmpfile: $!";

    rename( $tmpfile, $filename )
        or die "rename $filename: $!";
}

__END__

=head1 NAME

alternate-clone-recovery-reports.pl - Describe the usage of script briefly

=head1 SYNOPSIS

alternate-clone-recovery-reports.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for alternate-clone-recovery-reports.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@htgt-web.internal.sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
