package HTGT::BioMart::QueryFactory;
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-biomart-query/trunk/lib/HTGT/BioMart/QueryFactory.pm $
# $LastChangedDate: 2011-01-25 10:31:02 +0000 (Tue, 25 Jan 2011) $
# $LastChangedRevision: 3762 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;
require URI;

with 'HTGT::BioMart::UserAgent';

has 'martservice' => (
    is      => 'ro',
    isa     => 'HTGT::BioMart::URI',
    coerce  => 1,
    default => sub { URI->new( 'http://www.sanger.ac.uk/htgt/biomart/martservice' ) }, 
);

has 'datasets' => (
    is         => 'rw',
    isa        => 'ArrayRef[Str]',
    lazy_build => 1,
);

has virtual_schema => (
    is        => 'ro',
    isa       => 'Str',
    default   => 'default'
);

has dataset_config_version => (
    is        => 'ro',
    isa       => 'Str',
    default   => '0.6'
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 and ref $_[0] ne 'HASH' ) {
        return $class->$orig( martservice => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }    
};

sub _build_datasets {
    my $self = shift;
    
    my $uri = $self->martservice->clone;
    $uri->query_form( type => 'registry' );
    
    my $response = $self->ua->get( $uri );
    die "GET $uri: " . $response->status_line
        unless $response->is_success;
    
    require XML::Records;
    my $parser = XML::Records->new( $response->content_ref );
    $parser->set_records( 'MartURLLocation' );
    
    my @datasets;
    while ( my $mart = $parser->get_record ) {
        push @datasets, $self->_datasets_for_mart( $mart->{name} );
    }
    
    return \@datasets;     
}

sub _datasets_for_mart {
    my $self = shift;
    my $mart = shift;
    
    my $uri = $self->martservice->clone;
    $uri->query_form( type => 'datasets', mart => $mart );
    
    my $response = $self->ua->get( $uri );
    die "GET $uri: " . $response->status_line
        unless $response->is_success;

    my @datasets;
    foreach my $row ( split "\n", $response->content ) {
        my ( $dsname, $visible ) = $row =~ qr/^TableSet\t(\S+)\t[^\t]+\t(\d)/
            or next;
        push @datasets, $dsname if $visible;
    }
    
    return @datasets;
}

sub validate_dataset {
    my $self = shift;
    my $dataset = shift;
    
    defined $dataset
        or Carp::croak( "Query dataset not specified" );
        
    grep { $dataset eq $_ } @{ $self->datasets }         
        or Carp::croak( "Dataset '$dataset' not recognized by this factory" );
        
    return $dataset;             
}

sub query {
    my $self = shift;

    my @queries;

    # Things that apply to *all* sub-queries:
    # - martservce
    # - schema
    # - dataset_config_version
    # - proxy
    # - timeout

    require HTGT::BioMart::Query;    
    my $query = HTGT::BioMart::Query->new(
        martservice            => $self->martservice->clone,
        virtual_schema         => $self->virtual_schema,
        dataset_config_version => $self->dataset_config_version,
        proxy                  => $self->proxy,
        timeout                => $self->timeout
    );
    
    # Things that apply to sub-queries    
    # - dataset
    # - attributes
    # - filter
    
    for my $args ( @_ ) {
        my $dataset = $self->validate_dataset( $args->{dataset} );

        my %ds = (            
            dataset     => $dataset,
        );
    
        foreach my $attr ( qw( attributes filter ) ) {
            $ds{ $attr } = $args->{ $attr }
                if defined $args->{ $attr };
        }

        $query->add_dataset( \%ds );
    }

    return $query;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__
