package HTGT::Utils::MGIWebService;

use Moose;
use namespace::autoclean;
use SOAP::Lite;
use List::MoreUtils qw(uniq);
use Try::Tiny;
use Readonly;
with 'MooseX::Log::Log4perl';

has proxy => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'http://services.informatics.jax.org/mgiws'
);

has timeout => (
    is      => 'ro',
    isa     => 'Int',
    default => 10,
);

has email => (
    is      => 'ro',
    isa     => 'Str',
    default => 'htgt@sanger.ac.uk',
);


Readonly my @DEFAULT_GENE_INFO_ATTRIBUTES => ('ensembl', 'vega');
Readonly my %ATTRIBUTE_TO_RESPONSE => (
    mgi => 'mgiGeneMarkerID',
    ensembl => 'ensemblID',
    vega => 'vegaID',
    entrezGene => 'entrezGeneID',
    nomenclature => ['symbol','name','featureType'],
    location => ['chr','strand','start','end'],
);

#output method for ensemble, vega and both
sub get_mgi_gene_info {
    my ( $self, $gene_id, @requested_attributes  ) = @_;
    
    return unless $gene_id;
    my $attributes = $self->_set_attributes(\@requested_attributes);
    return unless $attributes;
    
    my $gene_info;
    try {
        my ($request, $soap) = $self->_create_request($gene_id, $attributes ) or die;
        $gene_info = $self->_dispatch_request($request, $soap, $attributes) or die;
    } catch {
        $self->log->error("caught error: $_");
        $gene_info = undef;
    };
    return $gene_info;
}

sub _set_attributes {
    my ( $self, $requested_attributes ) = @_;
    my @attributes;
    if ( @{$requested_attributes} ) {
        foreach my $attribute ( @{$requested_attributes} ) {
            next if exists $ATTRIBUTE_TO_RESPONSE{$attribute};
            $self->log->error(
                'Use of unsupported attribute: '
                    . $attribute
                    . ' - Supported attributes: '
                    . join '|',( keys %ATTRIBUTE_TO_RESPONSE )
            );
            return 0;
        }
        if ( scalar( @{$requested_attributes} ) == 1 && $requested_attributes->[0] eq 'mgi' ) {
            $self->log->error(
                'Cannot ask for just mgi as return value,
                specify another attribute as well'
            );
            return 0;
        }
        @attributes = @{$requested_attributes};
    }
    else {
        @attributes = @DEFAULT_GENE_INFO_ATTRIBUTES;
    }

    return \@attributes;
}


sub _create_request {
    my ( $self, $gene_id, $attributes ) = @_;
    
    # mgi is already returned by default so cant pass with value in request
    my @attributes = grep{!/mgi/} @$attributes;

    my %params;
    my $http_proxy = $ENV{HTTP_PROXY} || $ENV{http_proxy};
    if ( defined $http_proxy ) {
        $params{proxy} = [ http => $http_proxy ];
    }
    $params{timeout} = $self->timeout;
    
    my $soap = SOAP::Lite->proxy( $self->proxy, %params )->autotype(0);

    # Construct an idSet with our MGI accession id
    my @idSetValues = SOAP::Data->name( id => $gene_id )->prefix('bt');

    my $idSet
        = SOAP::Data->name( "IDSet" => \SOAP::Data->value(@idSetValues) )
        ->prefix('req');

    my $requestorEmail
        = SOAP::Data->name( requestorEmail => $self->email )->prefix('req');

    my @returnSetValues
        = map { SOAP::Data->name( attribute => $_ )->prefix('bt') } @attributes;

    my $returnSet = SOAP::Data->name(
        "returnSet" => \SOAP::Data->value(@returnSetValues) )->prefix('req');

    # add the requestorEmail, IDSet and resultSet to a batchMarkerRequest element
    my $request
        = SOAP::Data->name( 'batchMarkerRequest' =>
            \SOAP::Data->value( $requestorEmail, $idSet, $returnSet ) )
        ->attr( { 'xmlns:bt' => 'http://ws.mgi.jax.org/xsd/batchType' } )
        ->prefix('req')->uri('http://ws.mgi.jax.org/xsd/request');

    return ($request,$soap);
}


sub _dispatch_request {
    my ( $self, $request, $soap, $attributes ) = @_;

    # submit the request to the submitDocument method
    my $result = $soap->submitDocument($request);

    if ( $result->fault ) {
        $self->log->error("SOAP Fault: " . $result->faultcode . $result->faultstring );
        return;
    }
    
    my @result_data;
    for my $r ( $result->paramsout ) {
        my %row_data;
        for my $attribute ( @$attributes ) {
            my $response = $ATTRIBUTE_TO_RESPONSE{$attribute};
            # some attributes return multiple values, need to deal with theses
            if ( ref ($response) eq 'ARRAY') {
                my %response_values;
                foreach my $response_type ( @$response ) {
                    $response_values{$response_type} = $r->{$response_type} if $r->{$response_type};
                }
                $row_data{$attribute} = \%response_values;
            }
            else {
                $row_data{$attribute} = $r->{$response} if $r->{$response};
            }
        }
        push @result_data, \%row_data;
    }
    return \@result_data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__