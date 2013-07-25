package HTGT::Utils::RESTClient;

use JSON qw( to_json from_json);
use LWP::UserAgent;
use Moose;
use MooseX::Types::URI qw( Uri );
use HTTP::Request;
use URI;
use namespace::autoclean;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

has base_url => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1
);

has proxy_url => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1
);

has username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has realm => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has ua => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    lazy_build => 1
);

sub _build_ua{
    my ( $self ) = @_;

    my $ua = LWP::UserAgent->new;

    $ua->proxy( 'http', $self->proxy_url );

    $ua->credentials( $self->base_url, $self->realm, $self->username, $self->password );

    return $ua;
}

sub GET {
    my ( $self, $url ) = @_;

    $self->_wrap_request( 'GET', $url, [content_type => 'application/json'] );
}

sub POST{
    my ( $self, $url, $data ) = @_;

    $self->_wrap_request( 'POST', $url, [content_type => 'application/json'], to_json($data) );
}

sub _wrap_request{
    my $self = shift;

    my $request = HTTP::Request->new( @_ );
    my $method  = $request->method;
    my $uri     = $request->uri;

    $self->log->debug( "$method request for $uri" );
    if ( $request->content ){
        $self->log->debug( "Request data: " . $request->content );
    }

    my $response = $self->ua->request( $request );

    if ( $response->is_success ){
        return from_json( $response->content );
    }

    my $err_msg = "$method $uri: " . $response->status_line;

    if ( my $content = $response->content ){
        $err_msg .= "\n $content ";
    }

    confess $err_msg;
}

__PACKAGE__->meta->make_immutable;


