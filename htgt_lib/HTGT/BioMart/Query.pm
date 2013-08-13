package HTGT::BioMart::Query;

#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-biomart-query/trunk/lib/HTGT/BioMart/Query.pm $
# $LastChangedDate: 2011-01-24 16:40:39 +0000 (Mon, 24 Jan 2011) $
# $LastChangedRevision: 3753 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use Moose;
use Carp;
use List::MoreUtils 'zip';
use HTGT::BioMart::Dataset;
use XML::Writer;

with 'HTGT::BioMart::UserAgent';

has 'martservice' => (
    is      => 'ro',
    isa     => 'HTGT::BioMart::URI',
    coerce  => 1,
    default => sub { URI->new( 'http://www.sanger.ac.uk/htgt/biomart/martservice' ) }, 
);

has 'schema' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'default',
);

has 'dataset_config_version' => (
    is      => 'ro',
    isa     => 'Str',
    default => '0.6'
);

has 'datasets' => (
    isa     => 'ArrayRef[HTGT::BioMart::Dataset]',
    traits  => [ 'Array' ],
    handles => {
        add_dataset => 'push',
        datasets    => 'elements',
        dataset     => 'get',
    },
    default => sub { [] }
);

around add_dataset => sub {
    my ( $orig, $self, $arg ) = @_;

    unless ( UNIVERSAL::isa( $arg, 'HTGT::BioMart::Dataset' ) ) {
        $arg = HTGT::BioMart::Dataset->new( $arg );        
    }

    $self->$orig( $arg );
};


sub attributes {
    my $self = shift;

    [ map @{ $_->attributes }, $self->datasets ];
}

sub to_xml {
    my $self = shift;
    
    my $query_xml;
    
    my $xml = XML::Writer->new( OUTPUT => \$query_xml, ENCODING => 'utf-8' );
    $xml->xmlDecl;
    $xml->doctype( 'Query' );
    $xml->startTag( 'Query',
                    virtualSchemaName    => $self->schema, 
                    datasetConfigVersion => $self->dataset_config_version,
                    uniqueRows           => 1
                );    

    for my $q ( $self->datasets ) {    
        $xml->startTag( 'Dataset', name => $q->dataset, interface => 'default' );
        foreach my $attr ( @{ $q->attributes } ) {
            $xml->emptyTag( 'Attribute', name => $attr );
        }
        while ( my ( $name, $value) = each %{ $q->filter } ) {
            if ( ref $value eq 'ARRAY' ) {
                $value = join q{,}, @{ $value };
            }
            $xml->emptyTag( 'Filter', name => $name, value => $value );
        }
        $xml->endTag( 'Dataset' );
    }    

    $xml->endTag( 'Query' );
    $xml->end;
        
    return $query_xml;
}

sub results {
    my $self = shift;
    
    my $query_xml = $self->to_xml;
    my $uri = $self->martservice;
    
    my $response = $self->ua->post( $uri, { query => $query_xml } );

    die "POST $uri: " . $response->status_line
        unless $response->is_success;

    if ( $response->content =~ /BioMart::Exception/ ) {
        chomp( my $err_str = $response->content );
        Carp::croak( $err_str );
    }
        
    my @results;

    foreach my $row ( split "\n", $response->content ) {
        my @cols = split "\t", $row;        
        push @results, { zip @{ $self->attributes }, @cols };
    }
        
    return \@results;
}

1;

__END__
