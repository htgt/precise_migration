#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;
use Pod::Usage;
use Const::Fast;

GetOptions(
    'help'       => sub { pod2usage( verbose => 1 ) },
    'man'        => sub { pod2usage( verbose => 2 ) },
    'commit'     => \my $commit,
    'list-roles' => \my $list_roles,
    'role=s@'    => \my @roles,
) or pod2usage(2);
    
my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

const my %AVAILABLE_ROLES => map { $_->auth_role->auth_role_name => $_->auth_role_id } $htgt->resultset( 'AuthUserRole' )->search( {} );

my $username = shift @ARGV;

if ( $list_roles ) {
    if ( defined $username ) {
        list_roles_for_user( $username );
    }
    else {
        list_all_roles();
    }
}
else {
    pod2usage( "Username must be specified" ) unless defined $username;
    for ( @roles ) {
        pod2usage( "Invalid role '$_'" )
            unless exists $AVAILABLE_ROLES{$_};
    }
    $htgt->txn_do(
        sub {
            create_user( $username, @roles );
            unless ( $commit ) {
                warn "Rollback\n";
                $htgt->txn_rollback;
            }
        }
    );    
}

exit 0;

sub list_all_roles {
    print "Available roles:\n";
    print "  $_\n" for sort keys %AVAILABLE_ROLES;
}

sub list_roles_for_user {
    my $username = shift;
    
    my $user = $htgt->resultset( 'AuthUser' )->find( { auth_user_name => $username } )
        or die "Failed to retrieve user $username\n";
    print "Roles for $username:\n";
    print "  $_\n" for map $_->auth_role_name, $user->roles;
}

sub create_user {
    my ( $username, @roles ) = @_;

    my $user = $htgt->resultset( 'AuthUser' )->find_or_create( { auth_user_name => $username } )
        or die "Failed to find/create user $username\n";
    print "User $username has id " . $user->auth_user_id . "\n";
    
    my %user_roles = map { $_->auth_role_name => 1 } $user->roles;
    for ( grep !$user_roles{$_}, @roles ) {
        $user->user_roles_rs->find_or_create( { auth_role_id => $AVAILABLE_ROLES{$_} } )
            or die "Failed to find/create role $_";
        print "Added role $_ to user $username\n";
    }
}

__END__

=head1 NAME

create_user -  create a user in HTGT with the specified roles

=head1 SYNOPSIS

  create_user.pl --list-roles [USERNAME]

  create_user.pl [--commit] [--role=ROLENAME ...] USERNAME

=head1 DESCRIPTION

Create a user in HTGT with the specified roles. If the user already exists, add
the requested role to the user.

=cut

