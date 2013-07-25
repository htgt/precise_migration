package HTGT::Model::BadgerRepository;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/trunk/lib/HTGT/Model/BadgerRepository.pm $
# $LastChangedRevision: 4605 $
# $LastChangedDate: 2011-03-30 13:20:45 +0100 (Wed, 30 Mar 2011) $
# $LastChangedBy: rm7 $

use Moose;
use MooseX::NonMoose;
use HTGT::DBFactory::DBConnect;
use namespace::autoclean;

extends 'Catalyst::Model::DBI';
with 'HTGT::Utils::BadgerRepository::Pfind';

{   
    my @params = HTGT::DBFactory::DBConnect->params( 'badger_repository', { AutoCommit => 1 } );

    __PACKAGE__->config(
        dsn      => $params[0],
        username => $params[1],
        password => $params[2],
        options  => $params[3],
    );
}

1;

__END__

=head1 NAME

HTGT::Model::BadgerRepository - Catalyst Model

=head1 SYNOPSIS

  # Find all projects beginning 'PCS001'
  my $projects = $c->model( 'BadgerRepository' )->search( 'PCS001' );

  # Determine whether or not $project exists in the repository
  print "No such project $project" unless $c->model( 'BadgerRepository' )->exists( $project );

  # Find the online path (if any) for $project
  my $path = $c->model( 'BadgerRepository' )->path( $project );

=head1 DESCRIPTION

Catalyst Model.

=head1 SEE ALSO

L<Catalyst::Model::DBI>, L<HTGT::Utils::BadgerRepository::Pfind>, L<pfind>.

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
