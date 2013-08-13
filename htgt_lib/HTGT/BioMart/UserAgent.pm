package HTGT::BioMart::UserAgent;
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-biomart-query/trunk/lib/HTGT/BioMart/UserAgent.pm $
# $LastChangedDate: 2009-11-18 12:17:36 +0000 (Wed, 18 Nov 2009) $
# $LastChangedRevision: 342 $
# $LastChangedBy: rm7 $
#

use Moose::Role;
use Moose::Util::TypeConstraints;
require URI;

subtype 'HTGT::BioMart::URI' => as class_type( 'URI' );

coerce 'HTGT::BioMart::URI'
    => from 'Str'
    => via { URI->new( $_ ) }; 

has 'proxy' => (
    is      => 'ro',
    isa     => 'HTGT::BioMart::URI',
    coerce  => 1,
    default => sub { URI->new( 'http://wwwcache.sanger.ac.uk:3128/' ) },
);

has 'timeout' => (
    is      => 'rw',
    isa     => 'Int',
    default => 10,
);

sub ua {
    my $self = shift;
    
    require LWP::UserAgent;
    
    my $ua = LWP::UserAgent->new();
    $ua->timeout( $self->timeout )
        if defined $self->timeout;
    $ua->proxy( http => $self->proxy )
        if defined $self->proxy;        
    
    return $ua;
}

1;

__END__
