package Catalyst::Authentication::Credential::SangerSSO;
#
# $HeadURL$
# $LastChangedDate$
# $LastChangedRevision$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use base 'Class::Accessor::Fast';

BEGIN {
    __PACKAGE__->mk_ro_accessors( qw( username_field ) );
}

=head2 new

Construct a Catalyst::Authentication::Credential::SangerSSO object.

=cut

sub new {
    my ( $class, $config, $app, $realm ) = @_;
    my %self = ( username_field => $config->{username_field} || 'username' );
    bless( \%self, $class );
}

=head2 authenticate

Retrieve the authenticated username from B<SangerWeb> and look up a
corresponding user via B<find_user>; returns the user object.

=cut

sub authenticate {
     my ( $self, $c, $realm, $authinfo ) = @_;
     
     my $auth_user = eval {
         local (*ENV) = $c->engine->env || \%ENV;
         # SangerWeb ignores SERVER_PORT
         if ( $ENV{HTGT_ENV} and $ENV{HTGT_ENV} ne 'Live' and $ENV{SERVER_PORT} and $ENV{SERVER_NAME} !~ /:/ ) {
              $ENV{SERVER_NAME} = $ENV{SERVER_NAME} . ':' . $ENV{SERVER_PORT};
         }
         $ENV{REQUEST_METHOD} = 'GET'; # SangerWeb hangs on a POST         
         require SangerWeb;
         SangerWeb->new->username;
     };
     if ( $@ ) {
         $c->log->error( "Failed to authenticate via SangerWeb: $@" );
         return;
     }
     unless ( $auth_user ) {
         $c->log->debug( "User not authenticated: no username from SangerWeb" );
         return;
     }
     
     $c->log->debug( "Got username $auth_user from SangerWeb" );
     
     my $user_obj = $realm->find_user( { $self->username_field => $auth_user, id => $auth_user }, $c );
     unless ( $user_obj ) {
         $c->log->error( "User '$auth_user' not found" );
         return;
     }
     
     return $user_obj;
}

1;

__END__
