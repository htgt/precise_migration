package HTGT::Utils::ESPickLists;

use Moose;
use namespace::autoclean;

with qw( MooseX::Log::Log4perl MooseX::SimpleConfig );

has '+configfile' => ( default => $ENV{ES_DISTRIBUTE_CHECK_CONF} );

has imits_db => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_db_username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has imits_db_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

sub get_pick_lists {
    my ($self, $gene_info, $consortium) = @_;

    my $consortium_genes = get_consortium_genes( $gene_info, $consortium );

    my ( $unpicked, $failed, $all_aborted ) = $self->categorise_genes( $consortium, $consortium_genes );

    return ( $unpicked, $failed, $all_aborted );
}

sub categorise_genes {
    my ( $self, $consortium, $consortium_genes ) = @_;

    my $aborted_genes = $self->get_all_aborted_genes( $consortium );
    my $mip_genes = $self->get_all_mi_in_progress_genes( $consortium );
    my $bespoke_genes = $self->get_all_bespoke_genes( $consortium );

    my ( @unpicked, @failed, @all_aborted );
    for my $gene ( @{ $consortium_genes } ) {
        $gene->{bespoke_status} = defined $bespoke_genes->{ $gene->{mgi_accession_id} } ? 'Bespoke' : '';

        if ( defined $aborted_genes->{ $gene->{mgi_accession_id} } ){
            push @all_aborted, $gene;
            next;
        }
        next if defined $mip_genes->{ $gene->{mgi_accession_id} };
        next if $gene->{mi_plan_status} =~ /^Inspect/;
        if ( $gene->{mi_plan_status} eq 'Aborted - ES Cell QC Failed' ) {
            push @failed, $gene;
        }
        if ( defined $gene->{clones_available} ) {
            next if $gene->{mi_plan_status} eq 'Conflict';
            next if $gene->{clones_available_count} < 2;
            push @unpicked, $gene;
            next;
        }
        if ( defined $gene->{qc_started_0} ) {
            push @unpicked, $gene;
            next;
        }
        if ( defined $gene->{piq_well_statuses} ) {
            next if $gene->{piq_well_statuses} =~ /\s-\sIn\sTC/;
            next if $gene->{piq_well_statuses} =~ /\s-\sPass/;
            push @failed, $gene;
        }
    }

    return ( \@unpicked, \@failed, \@all_aborted );
}

sub get_consortium_genes {
    my ($gene_info, $consortium) = @_;

    my ( @consortium_genes );
    for my $gene ( @{ $gene_info } ) {
        if ( $gene->{consortium} eq $consortium ) {
            push @consortium_genes, $gene;
        }
    }

    return ( \@consortium_genes );
}

sub get_all_aborted_genes{
    my ($self, $consortium) = @_;

    my $dbh = DBI->connect( 'DBI:Pg:' . $self->imits_db, $self->imits_db_username, $self->imits_db_password );

    my $sth
        = $dbh->prepare(
        "SELECT distinct intermediate_report.mgi_accession_id FROM intermediate_report WHERE intermediate_report.consortium = '$consortium' AND intermediate_report.overall_status = 'Micro-injection aborted'"
        );
    $sth->execute();

    my %aborted_genes;

    my $r = $sth->fetchrow_hashref;
    while ($r) {
        $aborted_genes{ $r->{mgi_accession_id} }++;
        $r = $sth->fetchrow_hashref;
    }

    return \%aborted_genes;
}

sub get_all_mi_in_progress_genes{
    my ( $self, $consortium ) = @_;

    my $dbh = DBI->connect( 'DBI:Pg:' . $self->imits_db, $self->imits_db_username, $self->imits_db_password );

    my $sth
        = $dbh->prepare(
        "SELECT distinct intermediate_report.mgi_accession_id FROM intermediate_report WHERE intermediate_report.consortium = '$consortium' AND intermediate_report.micro_injection_in_progress_date is not null"
        );
    $sth->execute();

    my %mip_genes;

    my $r = $sth->fetchrow_hashref;
    while ($r) {
        $mip_genes{ $r->{mgi_accession_id} }++;
        $r = $sth->fetchrow_hashref;
    }

    return \%mip_genes;
}

sub get_all_bespoke_genes{
    my ( $self, $consortium ) = @_;

    my $dbh = DBI->connect( 'DBI:Pg:' . $self->imits_db, $self->imits_db_username, $self->imits_db_password );

    my $sth
        = $dbh->prepare( "SELECT distinct mgi_accession_id FROM genes JOIN mi_plans on mi_plans.gene_id = genes.id JOIN consortia on mi_plans.consortium_id = consortia.id WHERE mi_plans.is_bespoke_allele is true AND consortia.name = 'MGP'" );
    $sth->execute();

    my %bespoke_genes;

    my $r = $sth->fetchrow_hashref;
    while ( $r) {
        $bespoke_genes{ $r->{mgi_accession_id} }++;
        $r = $sth->fetchrow_hashref;
    }

    return \%bespoke_genes;
}

__PACKAGE__->meta->make_immutable;
