### TargetedTrap::DBSQL::Database
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Jessica Severin (jessica@sanger.ac.uk)
#

=pod
 
=head1 NAME - TargetedTrap::DBSQL::Database
 
=head1 DESCRIPTION
 
Generalized handle on an Oracle database. Used to provide
an instance which holds connection information and allows
a higher level get_connection/ disconnect logic that persists
above the specific DBI connections.
 
=cut

package TargetedTrap::DBSQL::Database;

use strict;
use warnings FATAL => 'all';

use DBI;

sub new {
    my ( $class, $param ) = @_;

    my $self = {};
    bless $self, $class;
    $self->{'_host'}     = $param->{'_host'};
    $self->{'_port'}     = $param->{'_port'};
    $self->{'_database'} = $param->{'_database'};
    $self->{'_user'}     = $param->{'_user'};
    $self->{'_password'} = $param->{'_password'};

    return $self;
}

sub get_connection {
    my ($self) = @_;

    my $dbc = $self->{DB_CONNECTION};

    if ( defined($dbc) ) {
        if ( $dbc->ping() ) {
            return $dbc;
        }
        else {
            warn "FAILED PING....";
            $dbc->disconnect();
        }
    }

    my $host     = $self->{'_host'};
    my $port     = $self->{'_port'};
    my $database = $self->{'_database'};
    my $user     = $self->{'_user'};
    my $password = $self->{'_password'};

    my $dsn = "DBI:Oracle:" . $self->{'_database'};
    $dbc =
      DBI->connect( $dsn, $user, $password,
        { LongReadLen => 96000, RaiseError => 1, AutoCommit => 1 } );

    $self->{DB_CONNECTION} = $dbc;

    return $dbc;
}

sub disconnect {
    my $self = shift;
    return unless ( $self->{'DB_CONNECTION'} );

    my $dbc = $self->{'DB_CONNECTION'};
    if ( $dbc->{ActiveKids} != 0 ) {
        warn( "Problem disconnect : kids=",
            $dbc->{Kids}, " activekids=", $dbc->{ActiveKids}, "\n" );
        return 1;
    }
    $dbc->disconnect();
    $self->{'DB_CONNECTION'} = undef;

    return $self;
}

sub DESTROY {
    my $self = shift;
}

1;
