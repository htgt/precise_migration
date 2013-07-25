package FCGI::Engine::Manager::Server::HTGT;

use Moose;
use namespace::autoclean;

extends 'FCGI::Engine::Manager::Server';

has max_requests => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

override construct_command_line => sub {
    ( super(), '--max_requests', shift->max_requests );
};

__PACKAGE__->meta->make_immutable;

__END__
