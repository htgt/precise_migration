#!/usr/bin/env perl

use warnings FATAL => 'all';
use strict;

use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use Try::Tiny;
use HTGT::Utils::EnsEMBL;
use HTGT::Utils::DesignPhase qw( compute_and_set_phase );
use Bio::Location::Simple;
use Perl6::Slurp;

{
    
    my $loglevel = $WARN;
    my $schema   = HTGT::DBFactory->connect('eucomm_vector');

    GetOptions(
        'help' => sub { pod2usage( -verbose => 1 ) },
        'man'  => sub { pod2usage( -verbose => 2 ) },
        'debug'   => sub { $loglevel = $DEBUG },
        'verbose' => sub { $loglevel = $INFO },
        'trace'   => sub { $loglevel = $TRACE },
        'commit'  => \my $commit,
    ) or pod2usage(2);
    
    Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %x %m%n' } );

    my @design_ids = @ARGV ? @ARGV : slurp \*STDIN, { chomp => 1 };

    $schema->txn_do(            
        sub {
            for my $design_id (@design_ids) {
                Log::Log4perl::NDC->push($design_id);
                try {
                    update_design_phase( $schema, $design_id );
                }
                catch {
                    ERROR($_);
                };
                Log::Log4perl::NDC->pop;
            }
            if ( ! $commit ) {
                warn "Rollback\n";
                $schema->txn_rollback;3
            }
        }
    );
}

sub update_design_phase {
    my ( $schema, $design_id ) = @_;

    my $design = $schema->resultset('Design')->find( { design_id => $design_id } )
        or die "Failed to retrieve design\n";

    compute_and_set_phase( $design );

    return;
}

__END__

=head1 NAME

add-design-phase.pl - Add computed phase to the design table

=head1 SYNOPSIS

add-design-phase.pl [options]

      --help            Display a brief help message
      --man             Display the manual page
      --debug           Print debug messages
      --verbose         Print informational messages
      --commit          Commit updates to database, by default rolls back changes

Acts on designs specifed in @ARGV or, if @ARGV is empty, from STDIN.

=head1 DESCRIPTION

Computes the phase of specified designs and, if this does not match
design.phase, updates the value stored in the database.

=head1 BUGS

None reported... yet.

=cut
