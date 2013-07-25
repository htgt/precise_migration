package Catalyst::Plugin::LogUtils;

use strict;
use warnings FATAL => 'all';

sub log_request {
    my ( $self ) = @_;
    
    my ( $caller ) = ( caller(1) )[3];

    my $user = $self->user ? $self->user->id : 'UNKNOWN';
    
    my %params = %{ $self->req->params };
    my $params_str = join q{ }, map {
        sprintf( '%s=%s', $_, defined( $params{$_} ) ? $params{$_} : '<undef>' )
    } sort keys %params;
    
    $self->log->debug( "$caller - $user $params_str" );
    
    return "$user $params_str";
}

sub audit_info {
    my ( $self, $mesg ) = @_;

    $self->audit( 'info', $mesg );
}

sub audit_error {
    my ( $self, $mesg ) = @_;

    $self->audit( 'error', $mesg );
}
        
sub audit {
    my ( $self, $level, $mesg ) = @_;
    
    my ( $caller ) = ( caller(2) )[3];

    ( my $remote_ip = $self->request->header( 'X-Forwarded-For' ) || '' ) =~ s/^.*,//;
    
    my $user = $self->user ? $self->user->id : 'UNKNOWN';
    
    $self->log->$level( sprintf( '%s [%s] %s - %s', $caller, $remote_ip, $user, $mesg ) );
    
    return "$user $mesg";
}

1;

__END__
