package HTGT::BioMart::Dataset;

#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-biomart-query-perl/trunk/lib/HTGT/BioMart/Query.pm $
# $LastChangedDate: 2009-11-19 13:22:24 +0000 (Thu, 19 Nov 2009) $
# $LastChangedRevision: 344 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;
use List::MoreUtils 'zip';

with 'HTGT::BioMart::UserAgent';

has 'martservice' => (
    is      => 'ro',
    isa     => 'HTGT::BioMart::URI',
    coerce  => 1,
    default => sub { URI->new( 'http://www.sanger.ac.uk/htgt/biomart/martservice' ) }, 
);

has 'dataset' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_dataset_config' => (
    is         => 'ro',
    isa        => 'ScalarRef',
    lazy_build => 1,
);

has 'filter' => (
    is       => 'rw',
    isa      => 'HashRef',
    default  => sub { {} }
);

has 'attributes' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => 'default_attributes',
);

has '_attributes' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build__dataset_config {
    my $self = shift;
    
    my $uri = $self->martservice->clone;
    $uri->query_form( type => 'configuration', dataset => $self->dataset );    
    
    my $response = $self->ua->get( $uri );
    die "GET $uri: " . $response->status_line
        unless $response->is_success;
        
    return $response->content_ref;                
}

sub _dataset_config_parser {
    my $self = shift;
    
    require XML::Records;
    my $parser = XML::Records->new( $self->_dataset_config );
    $parser->set_records( @_ ) if @_;
    return $parser;
}

sub _build__attributes {
    my $self = shift;
    
    my $parser = $self->_dataset_config_parser( 'AttributeDescription' );
    
    my %attributes;
    while ( my $attr = $parser->get_record ) {
        my $is_default = 0;
        if ( $attr->{default} and $attr->{default} eq 'true' ) {
            $is_default = 1;
        }
        $attributes{ $attr->{internalName} } = $is_default;
    }
    
    return \%attributes;
}

sub available_attributes {
    my $self = shift;
    [ keys %{ $self->_attributes } ];
}

sub default_attributes {
    my $self = shift;
    my $attrs = $self->_attributes;
    [ grep $attrs->{$_}, keys %{ $attrs } ];
}

1;

__END__
