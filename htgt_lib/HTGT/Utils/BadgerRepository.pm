package HTGT::Utils::BadgerRepository;

use Moose;
use HTGT::DBFactory::DBConnect;
use namespace::autoclean;

with 'HTGT::Utils::BadgerRepository::Pfind';

has _dbh => (
    is         => 'ro',
    isa        => 'DBI::db',
    lazy_build => 1,
);

sub _build__dbh {
    HTGT::DBFactory::DBConnect->dbi_connect_cached( 'badger_repository', { AutoCommit => 1 } );
}

sub dbh {
    shift->_dbh;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HTGT::Utils::BadgerRepository

=head1 SYNOPSIS

  require HTGT::Utils::BadgerRepository;

  my $br = HTGT::Utils::BadgerRepository->new;

  # Find all projects beginning 'PCS001'
  my $projects = $br->search( 'PCS001' );

  # Determine whether or not $project exists in the repository
  print "No such project $project" unless $br->exists( $project );

  # Find the online path (if any) for $project
  my $path = $br->path( $project );

=head1 DESCRIPTION

Utility module for looking up projects in the Badger repository
(modular implementation of B<pfind>).

=head1 METHODS

=head2 dbh

Returns a database handle connected to the I<badger_repository> database.

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
