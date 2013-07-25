package HTGT::Utils::BadgerRepository::Pfind;

use Moose::Role;
use namespace::autoclean;

requires 'dbh';

sub search {
    my ( $self, $project ) = @_;

    return unless defined $project;

    $self->dbh->selectcol_arrayref( 'select projectname from project where projectname like ?', undef, $project . '%' );
}

sub exists {
    my ( $self, $project ) = @_;

    return unless defined $project;
    
    my $projects = $self->dbh->selectcol_arrayref( 'select projectname from project where projectname = ?', undef, $project );

    return @{ $projects } ? 1 : 0;
}

sub path {
    my ( $self, $project ) = @_;

    return unless $self->exists( $project );

    my ( $path ) = $self->dbh->selectrow_array(<<'EOT', undef, $project );
select online_data.online_path
from   online_data, project
where  project.id_online = online_data.id_online
and    project.projectname = ?
EOT

    return $path;    
}

1;

__END__

=pod

=head1 NAME

HTGT::Utils::BadgerRepository::Pfind

=head1 SYNOPSIS

  use Moose;
  with 'HTGT::Utils::BadgerRepository::Pfind';

=head1 DESCRIPTION

Moose role that provides B<search>, B<exists>, and B<path> methods to
query the Badger repository.

Classes that use this role should implement an B<dbh> method that
returns a database handle for a connection to the Badger repository
database.

=head1 METHODS

=head2 search( I<$str> )

Returns a list (array ref) of projects in the Badger repository with names
beginning I<$str>. List will be empty if no matching projects are
found.

=head2 exists( I<$project> )

Returns true if I<$project> exists in the Badger repository, otherwise false.

=head2 path( I<$project> )

Returns the online path (if any) for I<$project>. Returns undef if
I<$project> does not exist or has no online path.

=head1 AUTHOR

Ray Miller

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
