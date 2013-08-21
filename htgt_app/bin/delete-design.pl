#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use HTGT::Utils::Design::Delete 'delete_design_by_id';
use Log::Log4perl ':levels';

GetOptions(
    help   => sub { pod2usage( -verbose => 1 ) },
    man    => sub { pod2usage( -verbose => 2 ) },
    commit => \my $commit
) or pod2usage(2);

Log::Log4perl->easy_init( $INFO );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my @design_ids = @ARGV ? @ARGV : map { chomp; $_ } <STDIN>;

$htgt->txn_do(
    sub {
        for ( @design_ids ) {
            delete_design_by_id( $htgt, $_ );
        }
        unless ( $commit ) {
            print "Rollback...\n";
            $htgt->txn_rollback;
        }
    }
);

__END__

=pod

=head1 NAME

delete-design.pl

=head1 SYNOPSIS

  delete-design.pl [--commit] [DESIGN_ID ...]

=head1 DESCRIPTION

Delete design I<DESIGN_ID> and related rows from the database.  This
script will refuse to delete a design with related design_instance
rows.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
