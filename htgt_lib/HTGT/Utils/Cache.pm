package HTGT::Utils::Cache;

use base 'Exporter';

use strict;
use warnings FATAL => 'all';

BEGIN {
    our @EXPORT      = qw( get_or_update_cached );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
    
}

use JSON;
use MIME::Base64;

sub get_or_update_cached {
    my ( $c, $cache_key, $get_data_sub_ref, %opts ) = @_;
    
    $c->log->debug( "get_or_update_cached: " . $cache_key );
    
    my ( $encode, $decode );
    if ( $opts{base64} ) {
        $encode = sub { encode_base64( $_[0], '') };
        $decode = sub { decode_base64( $_[0] ) };
    }
    else {
        $encode = sub { to_json( $_[0] ) }; 
        $decode = sub { from_json( $_[0] ) };
    }
    
    my $force_refresh = $c->req->params->{force_refresh};
    
    my ( $cached, $data );

    unless ( $force_refresh ) {
        $cached = $c->cache->get( $cache_key );
    }
    
    if ( $cached ) {
        $c->log->debug( "get_or_update_cached: using cached value for $cache_key" );
        $data = $decode->( $cached );
    }
    else { 
        $c->log->debug( "get_or_update_cached: updating cached value for $cache_key");
        $data = $get_data_sub_ref->();
        $c->cache->set( $cache_key, $encode->( $data ) );       
    }
    
    return $data;
}

1;

__END__
