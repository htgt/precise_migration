package HTGT::Utils::BespokeStatus;

use Moose;
use DBI;
use namespace::autoclean;
use Const::Fast;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

has '+configfile' => (
    default => $ENV{BESPOKE_ALLELE_CHECK_CONF}
);

has redmine_db => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_db_username => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has redmine_db_password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

const my %REMOVE_SPACES => (
    'Pre Injection QC Custom'     => 'PreInjectionQCCustom',
    'Pre Injection QC HT'         => 'PreInjectionQCHT',
    'Model Acquisition Initiated' => 'ModelAcquisitionInitiated',
    'Model Acquisition Completed' => 'ModelAcquisitionCompleted',
    'Faculty_Micro-Injection'     => 'FacultyMicroInjection',
    'Design'                      => 'Design',
    'VectorConstructionCustom'    => 'VectorConstructionCustom',
    'VectorConstructionHT'        => 'VectorConstructionHT',
    'TissueCultureCustom'         => 'TissueCultureCustom',
    'TissueCultureHT'             => 'TissueCultureHT',
    'New'                         => 'New',
    'Terminated'                  => 'Terminated',
    'MGP_Micro-injection'         => 'MGP',
    'MGP_Chimaera'                => 'MGP',
    'MGP_Germline genotype'       => 'MGP'
);

sub get_status_count {
    my $self = shift;

    my $dbh = DBI->connect( 'DBI:mysql:' . $self->redmine_db, $self->redmine_db_username, $self->redmine_db_password );

    my $sth = $dbh->prepare(
        "SELECT issues.id, issue_statuses.name, custom_values.value FROM issues join projects on projects.id = issues.project_id join issue_statuses on issues.status_id = issue_statuses.id join custom_fields_trackers on issues.tracker_id = custom_fields_trackers.tracker_id join custom_fields on custom_fields_trackers.custom_field_id = custom_fields.id join custom_values on custom_values.custom_field_id = custom_fields.id WHERE projects.name = 't87 bespoke targeting' and custom_fields.name = 'Requestor' and custom_values.customized_id = issues.id"
    );
    $sth->execute();

    my ( %requestors, %status_counts );
    my $r = $sth->fetchrow_hashref;
    while ($r){
        my $requestor = $r->{value};
        my $status = $r->{name};
        $status = $REMOVE_SPACES{$status};

        $requestors{ $requestor }++;
        $status_counts{ $status }{ $requestor }++;
        $status_counts{ $status }{Total}++;
        $status_counts{All}{ $requestor }++;
        $status_counts{All}{Total}++;
        $r = $sth->fetchrow_hashref;
    }

    my @requestors = sort keys %requestors;
    push @requestors, 'Total';

    return ( \@requestors, \%status_counts );

}

sub get_status_report_list{
    my ( $self, $status, $requestor ) = @_;

    my $dbh = DBI->connect( 'DBI:mysql:' . $self->redmine_db, $self->redmine_db_username, $self->redmine_db_password );

    my $sql;
    if ( $status eq 'All' ){
        $sql = "SELECT issues.id, issues.subject, users.firstname, users.lastname, issue_statuses.name, custom_fields.name as custom_field, custom_values.value as custom_field_value, issues.description FROM issues join projects on projects.id = issues.project_id left outer join users on users.id = issues.assigned_to_id join issue_statuses on issues.status_id = issue_statuses.id join custom_fields_trackers on issues.tracker_id = custom_fields_trackers.tracker_id join custom_fields on custom_fields_trackers.custom_field_id = custom_fields.id join custom_values on custom_values.custom_field_id = custom_fields.id WHERE projects.name = 't87 bespoke targeting' and custom_values.customized_id = issues.id";
    }
    else{
        $sql = "SELECT issues.id, issues.subject, users.firstname, users.lastname, issue_statuses.name, custom_fields.name as custom_field, custom_values.value as custom_field_value, issues.description FROM issues join projects on projects.id = issues.project_id left outer join users on users.id = issues.assigned_to_id join issue_statuses on issues.status_id = issue_statuses.id join custom_fields_trackers on issues.tracker_id = custom_fields_trackers.tracker_id join custom_fields on custom_fields_trackers.custom_field_id = custom_fields.id join custom_values on custom_values.custom_field_id = custom_fields.id WHERE projects.name = 't87 bespoke targeting' and issue_statuses.name like '$status\%' and custom_values.customized_id = issues.id";
    }

    my $sth = $dbh->prepare( $sql );
    $sth->execute;

    my %reports;
    my $r = $sth->fetchrow_hashref;
    while ($r){
        $reports{ $r->{id} } = {
            issue => $r->{id},
            subject => $r->{subject},
            assignee => $r->{firstname} . ' ' . $r->{lastname},
            status => $status,
            description => $r->{description}
        } unless defined $reports{ $r->{id} };

        my ( $cf, $cfv ) = ( $r->{custom_field}, $r->{custom_field_value} );
        $reports{ $r->{id} }{requestor} = $cfv if $cf eq 'Requestor';
        $reports{ $r->{id} }{allele_type} = $cfv if $cf eq 'Allele_Type';
        $reports{ $r->{id} }{marker_symbol} = $cfv if $cf eq 'Marker_Symbol';
        $reports{ $r->{id} }{requestor} = $cfv if $cf eq 'Requestor';
        $reports{ $r->{id} }{ensembl_id} = $cfv if $cf eq 'Ensembl_Gene_ID';
        $reports{ $r->{id} }{mgi_acc_id_link} = $cfv if $cf eq 'MGI_accession_id_link';
        $reports{ $r->{id} }{ikmc_gene_page} = $cfv if $cf eq 'IKMC Gene Page';
        $reports{ $r->{id} }{htgt_recovery_project} = $cfv if $cf eq 'htgt Recovery Project';
        $reports{ $r->{id} }{project_origin} = $cfv if $cf eq 'Project Origin';
        $reports{ $r->{id} }{es_cell_clone_injection_id} = $cfv if $cf eq 'ES cell clone_injection ID';
        $reports{ $r->{id} }{secondary_recovery_activity} = $cfv if $cf eq 'Secondary Recovery Activity';
        $reports{ $r->{id} }{owner} = $cfv if $cf eq 'Owner';
        $r = $sth->fetchrow_hashref;
    }

    return get_report_list( $requestor, \%reports );
}

sub get_report_list{
    my ( $requestor, $reports ) = @_;

    my %reports_keyed_by_ms;
    for my $issue ( keys %{$reports} ){
        $reports_keyed_by_ms{ $reports->{$issue}{marker_symbol} } = $reports->{$issue};
    }

    my @filtered_report_list;
    for my $marker_symbol( sort keys %reports_keyed_by_ms ){
        push @filtered_report_list, $reports_keyed_by_ms{$marker_symbol}
            if $requestor eq 'Total'
                or $requestor eq $reports_keyed_by_ms{$marker_symbol}{requestor};
    }

    return \@filtered_report_list;
}

__PACKAGE__->meta->make_immutable;
