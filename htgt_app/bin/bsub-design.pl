#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Path::Class;
use Getopt::Long;
use Pod::Usage;
use IPC::Run ();
use HTGT::DBFactory;
use Time::HiRes 'gettimeofday';
use Const::Fast;

{
    const my $DESIGN_HOME   => dir( '/lustre/scratch103/sanger/team87/designs' );
    my $group        = '/team87/design';
    my $max_parallel = 10;
    my $tag          = undef;

    GetOptions(
        'help'           => sub { pod2usage( -verbose => 1 ) },
        'man'            => sub { pod2usage( -verbose => 2 ) },
        'group=s'        => \$group,
        'max-parallel=i' => \$max_parallel,
        'tag=s'          => \$tag,
    ) or pod2usage(2);
    
    my @todo;
    
    if ( defined $tag ) {
        @todo = get_designs_for_tag( $tag );
    }
    elsif ( @ARGV ) {
        @todo = @ARGV;
    }
    else {
        @todo = map { chomp; $_ } <STDIN>;
    }

    # check_bsub_group( $group, $max_parallel );
    
    for my $design_id ( @todo ) {
        my $dirname = sprintf( 'd_%d.%d.%d.%d', $design_id, $$, Time::HiRes::gettimeofday() );
        bsub_design( $DESIGN_HOME->subdir( $dirname ), $group, $design_id );
    }
}

sub check_bsub_group {
    my ( $group, $max_parallel ) = @_;

    my $bjgroup = run_cmd( 'bjgroup', '-s', $group );

    if ( defined $bjgroup and $bjgroup =~ /No job group found/ ) {
        run_cmd( 'bgadd', $group );
    }

    if ($max_parallel) {
        run_cmd( 'bgmod', '-L', $max_parallel, $group );
    }
}

sub bsub_design {
    my ( $design_home, $group, $design_id ) = @_;

    print "Running bsub for $design_id\n";

    run_cmd(
        'bsub',
        '-o', ''.$design_home->file( "bjob_output" ),
        '-e', ''.$design_home->file( "bjob_error" ),
        '-q', ' normal',
        '-P', ' team87',
        '-g', ''.$group,
        '-M','1000000',
        '-R', "'select[mem>1000] rusage[mem=1000]'",
        'create_design.pl',
        '-design_home', ''.$design_home,
        '-design_id', $design_id
    );
}

sub run_cmd {
    my @cmd = @_;

    my $output;
    eval {
        IPC::Run::run( \@cmd, '<', \undef, '>&', \$output )
                or die "$output\n";
    };
    if ( my $err = $@ ) {
        chomp $err;
        die "$cmd[0] failed: $err";
    }

    chomp $output;
    return  $output;    
}

sub get_designs_for_tag {
    my $tag = shift;

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my $design_rs = $htgt->resultset( 'Design' )->search(
        {
            'design_parameter.parameter_value' => { like => '%' . $tag . '%' }
        },
        {
            join     => 'design_parameter',
            columns  => [ 'design_id' ],
            distinct => 1,
        }
    );

    die "Found no designs for tag: $tag"
        unless $design_rs->count;

    map $_->design_id, $design_rs->all;
}

__END__

=pod

=head1 NAME

bsub-design.pl

=head1 SYNOPSIS

  bsub-design.pl [OPTIONS] DESIGN_ID ...

  Options:

    --tag=TAG            Fetch designs with parameter_value mathing TAG
    --group=NAME         Name of batch job group (default /team87/design)
    --max-parallel=NUM   Maximum number of batch jobs to run in parallel (default 10)

=head1 DESCRIPTION

This script submits bsub jobs to search for oligos for the specified
designs. If the I<--tag> option is given, designs are created for all
designs in the system with a parameter_value matching I<TAG>.
Otherwise, if any arguments are given, they are assumed to be design
ids, and bsub jobs are submitted for these designs. If I<--tag> is not
specified and no arguments are given, desgin ids are read from STDIN.

=cut
