package HTGT::Utils::Design::DesignServer;

use strict;
use warnings;

use Path::Class;
use Time::HiRes;

=head1 NAME

Utility methods that USED to be on the old design-server standalone instance

=cut

=head2 index

=cut

sub new
{
  my $self = {};
  bless $self;
  return $self;
}

sub design_only {
    my ( $self, $c, $design_id )    = @_;

    my $dirname = sprintf( 'd_%d.%d.%d.%d', $design_id, $$, Time::HiRes::gettimeofday() );
    my $design_home = dir( $c->config->{design_home} )->subdir( $dirname );    
    
    my @run_design_command = ( 'bsub',
                               '-o' => "$design_home/bjob_output",
                               '-e' => "$design_home/bjob_error",
                               '-q' => 'normal',
                               '-R' => "'select[mem>1000] rusage[mem=1000]'",
                               '-M' => '1000000',
                               'create_design.pl',
                               '-design_home' => $design_home,
                               '-design_id'   => $design_id
                           );

    $c->log->info( "submiting command to farm: ". join( q{ }, @run_design_command ) );

    system( @run_design_command ) == 0
        or $c->log->error( "Failed to run bsub command: $! (exit $?)" );
}

=head1 AUTHOR

Vivek Iyer

Wanjuan Yang

=cut

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
