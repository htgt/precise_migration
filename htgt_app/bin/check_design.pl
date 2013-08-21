#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use Const::Fast;
use Try::Tiny;
use Perl6::Slurp;

use HTGT::Utils::DesignCheckRunner;

const my $DEFAULT_ASSEMBLY => 101;

my $loglevel = $INFO;
my $schema   = HTGT::DBFactory->connect('eucomm_vector');

GetOptions(
    'help'          => sub { pod2usage( -verbose   => 1 ) },
    'man'           => sub { pod2usage( -verbose   => 2 ) },
    'debug'         => sub { $loglevel = $DEBUG },
    'commit'        => \my $commit,
    'design=s'      => \my $design_id,
    'check_class=s' => \my $check_class,
    'check=s'       => \my $check,
) or pod2usage(2);

Log::Log4perl->easy_init( { level => $loglevel, layout => '%d %p %x %m%n' } );

my @designs;
if ( $ARGV[0] ) {
    @designs = map{ chomp; $_ } slurp( $ARGV[0] );
}
else {
    LOGDIE('Must specify design (--design=)') unless $design_id;
    push @designs, $design_id;
}

for my $id ( @designs ) {
    Log::Log4perl::NDC->pop;
    Log::Log4perl::NDC->push( $id );

    my $design = try{ $schema->resultset('Design')->find( { design_id => $id } ) };

    unless ( $design ) {
        ERROR('Unable to find design');
        next;
    }

    my $design_checker = HTGT::Utils::DesignCheckRunner->new(
        schema             => $schema,
        design             => $design,
        assembly_id        => $DEFAULT_ASSEMBLY,
        build_id           => 69.38,
        update_annotations => 1,
    );

    $schema->txn_do(
        sub {
            try {
                run_check( $design_checker );

                $schema->txn_rollback unless $commit;
            }
            catch {
                $schema->txn_rollback;
                ERROR('Error checking design: ' . $_ );
            };
        }
    );
}

sub run_check {
    my $design_checker = shift;

    if ( $check_class ) {
        die ( "Design checker does not have $check_class attribute" )
            unless $design_checker->meta->has_attribute( $check_class );

        if ( $check ) {
            die ( " $check_class can not call $check " )
                unless $design_checker->$check_class->meta->has_method( $check );

            $design_checker->$check_class->$check;
        }
        else {
            $design_checker->$check_class->update_design_annotation_status;
        }
    }
    else {
        $design_checker->check_design;
    }

    return;
}

__END__

=head1 NAME

design_check.pl 

=head1 SYNOPSIS

 design_check.pl [options] input-file

      --help              Display a brief help message
      --man               Display the manual page
      --debug             Print debug messages
      --design            Specify single design to check
      --check_class       Only run design against specified class of checks
      --check             Only run this specific test in the specified check class
      --commit            Commit results to database

=head1 DESCRIPTION

Run design checked code against one or multiple designs.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=cut
