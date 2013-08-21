#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use HTGT::Utils::Plate::Delete 'delete_plate';
use Getopt::Long;
use Pod::Usage;
use Log::Log4perl ':easy';
use Term::Query 'query';

my $log_level = $WARN;

GetOptions(
    'help'            => sub { pod2usage( -verbose => 1 ) },
    'man'             => sub { pod2usage( -verbose => 2 ) },
    'debug'           => sub { $log_level = $DEBUG },
    'verbose'         => sub { $log_level = $INFO },
    'delete-iterates' => \my $delete_iterates,
    'commit'          => \my $commit,
) and @ARGV or pod2usage(2);

Log::Log4perl->easy_init(
    {
        level  => $log_level,
        layout => '%p %m%n',
    }
);

my %search;

if ( $delete_iterates ) {
    $search{ name } = [ map { like => $_.'_%' }, @ARGV ];
}
else {
    $search{ name } = \@ARGV   
}

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

$htgt->txn_do(
    sub {
        my @plates = $htgt->resultset( 'Plate' )->search( \%search );
        die "no matching plates found\n" unless @plates;
        for my $plate ( @plates ) {
            my $plate_name = delete_plate( $plate, $ENV{USER} );
            print "Deleted plate $plate_name\n";
        }
        unless ( $commit or query( "Commit?", 'N' ) eq 'yes' ) {
            warn "Rollback\n";
            $htgt->txn_rollback;
        }
    }
);


__END__

=pod

=head1 NAME

delete_plate.pl

=head1 SYNOPSIS

  delete_plate.pl [--delete-iterates] PLATE_NAME

=cut

