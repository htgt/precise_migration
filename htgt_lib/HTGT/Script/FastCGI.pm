package HTGT::Script::FastCGI;

use Moose;
use MooseX::Types::Moose qw/Int/;
use namespace::autoclean;

extends 'Catalyst::Script::FastCGI';

has '+manager' => (
    default => 'FCGI::ProcManager::MaxRequests'
);

has max_requests => (
    traits        => [qw(Getopt)],
    cmd_aliases   => 'm',
    isa           => Int,
    is            => 'ro',
    default       => 0,
    documentation => 'Specify the maximum number of requests to be handled by a worker',
);

sub BUILD {
    my $self = shift;
    $ENV{PM_MAX_REQUESTS} = $self->max_requests;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTGT::Script::FastCGI - The FastCGI Script for HTGT

=head1 SYNOPSIS

  myapp_fastcgi.pl [options]

 Options:
   -? --help          display this help and exits
   -l --listen        Socket path to listen on
                      (defaults to standard input)
                      can be HOST:PORT, :PORT or a
                      filesystem path
   -n --nproc         specify number of processes to keep
                      to serve requests (defaults to 1,
                      requires -listen)
   -p --pidfile       specify filename for pid file
                      (requires -listen)
   -d --daemon        daemonize (requires -listen)
   -M --manager       specify alternate process manager
                      (FCGI::ProcManager sub-class)
                      or empty string to disable
   -e --keeperr       send error messages to STDOUT, not
                      to the webserver
   -m --max_requests  specify the maximum number of requests
                      to be handled by a worker

=head1 DESCRIPTION

Run a Catalyst application as FastCGI. This is a simple subclass of
Catalyst::Script::FastCGI that uses FCGI::ProcManager::MaxRequests
instead of the usual FCGI::ProcManager, and adds a B<--max_requests>
command-line option.

=head1 SEE ALSO

L<Catalyst::Script::FastCGI>, L<FCGI::ProcManager::MaxRequests>.

=head1 AUTHORS

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
