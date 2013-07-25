#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use List::MoreUtils 'uniq';
use YAML;

GetOptions(
    'commit'     => \my $commit
) and @ARGV == 1
    or die "Usage: $0 [--commit] htgt.yml\n";

my $users = YAML::LoadFile( shift )->{ authentication }{ realms }{ ssso }{ store }{ users };

my @roles = uniq map @{ $_->{ roles } }, values %{ $users };

my $schema = HTGT::DBFactory->connect( 'eucomm_vector', {AutoCommit => 1} );

$schema->txn_do(
    sub {
        my %role_id_for;
        foreach my $role_name ( grep $_ ne 'none', @roles ) {
            warn "Creating role $role_name\n";
            my $role = $schema->resultset( 'HTGTDB::AuthRole' )
                ->create( { auth_role_name => $role_name } );
            $role_id_for{ $role_name } = $role->auth_role_id;
        }

        foreach my $user_name ( keys %{ $users } ) {
            warn "Creating user $user_name\n";
            my $user = $schema->resultset( 'HTGTDB::AuthUser' )
                ->create( { auth_user_name => $user_name } );
            foreach my $user_role ( grep $_ ne 'none', @{ $users->{$user_name}{roles} } ) {
                warn "Adding role $user_role for $user_name\n";
                $schema->resultset( 'HTGTDB::AuthUserRole' )->create(
                    {
                        auth_user_id => $user->auth_user_id,
                        auth_role_id => $role_id_for{ $user_role }
                    }
                );
            }
        }
        die "Rollback\n" unless $commit;
    }
);
