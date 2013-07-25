package HTGT::Utils::BespokeAlleleCheck;

use Moose;
use HTGT::Utils::RESTClient;
use namespace::autoclean;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

has '+configfile' => (
    default => $ENV{BESPOKE_ALLELE_CHECK_CONF}
);

has imits_get_genes_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_base_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_realm => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_rest_client => (
    is         => 'ro',
    isa        => 'HTGT::Utils::RESTClient',
    init_arg   => undef,
    lazy_build => 1
);

has redmine_get_genes_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_post_issues_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_base_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1

);

has redmine_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_realm => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has proxy_url => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_rest_client => (
    is         => 'ro',
    isa        => 'HTGT::Utils::RESTClient',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_imits_rest_client{
    my $self = shift;

    my $imits_rest_client = HTGT::Utils::RESTClient->new(
        base_url  => $self->imits_base_url,
        proxy_url => $self->proxy_url,
        realm     => $self->imits_realm,
        username  => $self->imits_username,
        password  => $self->imits_password
    );

    return $imits_rest_client;
}

sub _build_redmine_rest_client{
    my $self = shift;

    my $redmine_rest_client = HTGT::Utils::RESTClient->new(
        base_url  => $self->redmine_base_url,
        proxy_url => $self->proxy_url,
        realm     => $self->redmine_realm,
        username  => $self->redmine_username,
        password  => $self->redmine_password
    );

    return $redmine_rest_client;
}

sub get_bespoke_allele_list{
    my $self = shift;

    my $redmine_response = $self->redmine_rest_client->GET( $self->redmine_get_genes_url );

    my %genes_with_tickets;
    for my $issue( @{ $redmine_response->{issues} } ){
        for my $cf( @{ $issue->{custom_fields} } ){
            if ( $cf->{name} eq 'Marker_Symbol' ){
                my $ms = $cf->{value};
                $ms =~ s/\s//g;
                $genes_with_tickets{ $ms }++;
            }
        }
    }

    return \%genes_with_tickets;
}

sub get_allele_list{
    my $self = shift;

    my $imits_response = $self->imits_rest_client->GET( $self->imits_get_genes_url );

    my $genes_with_tickets = $self->get_bespoke_allele_list;

    my @genes_without_tickets;
    for my $plan( @$imits_response ){
        my $marker_symbol = $plan->{marker_symbol};
        push @genes_without_tickets, $plan unless defined $genes_with_tickets->{$marker_symbol};
    }

    return \@genes_without_tickets;
}

sub create_redmine_ticket{
    my ( $self, $allele ) = @_;

    my $mgi_link = 'http://www.informatics.jax.org/marker/' . $allele->{mgi_accession_id};

    my $issue;
    $issue->{subject} = $allele->{marker_symbol};
    $issue->{project_id} = 1;
    $issue->{tracker} = 'allele';
    $issue->{priority} = $allele->{priority};
    $issue->{custom_field_values} = {
    #    '1' => '',                            #IKMC project ID
        '2' => $allele->{mgi_accession_id},    #MGI accession ID
    #    '3' => '',                            #HTGT design ID
        '4' => '---',                            #Allele type
        '5' => $allele->{marker_symbol},      #Marker symbol
    #    '6' => '',                            #EnsEMBL gene ID
        '14' => $allele->{requesting_project}, #Requesting project
        '8' => $mgi_link                      #MGI accession ID link
    };

    my $data;
    $data->{issue} = $issue;

    $self->redmine_rest_client->POST( $self->redmine_post_issues_url, $data );

}

__PACKAGE__->meta->make_immutable;
