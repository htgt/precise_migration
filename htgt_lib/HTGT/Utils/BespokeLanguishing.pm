package HTGT::Utils::BespokeLanguishing;

use Moose;
use DBI;
use DateTime;
use DateTime::Duration;
use DateTime::Format::MySQL;
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

sub get_languishing_count {
    my $self = shift;

    my $dbh = DBI->connect( 'DBI:mysql:' . $self->redmine_db, $self->redmine_db_username, $self->redmine_db_password );

    my $sth = $dbh->prepare(
        "SELECT issues.id as issue, issue_statuses.name, issues.created_on, journal_details.prop_key, journals.created_on as modified_on  FROM issues join projects on projects.id = issues.project_id join issue_statuses on issues.status_id = issue_statuses.id left outer join journals on issues.id = journals.journalized_id left outer join journal_details on journals.id = journal_details.journal_id WHERE projects.name = 't87 bespoke targeting'"
    );
    $sth->execute();

    my ( %statuses, %last_status_dates);
    my $r = $sth->fetchrow_hashref;

    while ($r){
        $statuses{ $r->{issue} } = $REMOVE_SPACES{ $r->{ name } };

        unless ( defined $last_status_dates{ $r->{issue} } ){
            $last_status_dates{ $r->{issue} } = $r->{created_on};
        }

        unless ( $r->{prop_key} eq 'status_id' ){
            $r = $sth->fetchrow_hashref;
            next;
        }

        my $time_in_hash = DateTime::Format::MySQL->parse_datetime( $last_status_dates{ $r->{issue} } );
        my $time_from_db = DateTime::Format::MySQL->parse_datetime( $r->{modified_on} );

        $last_status_dates{ $r->{issue} } = $r->{modified_on}
            if DateTime::Format::MySQL->parse_datetime( $last_status_dates{ $r->{issue} } )
                < DateTime::Format::MySQL->parse_datetime( $r->{modified_on} );

        $r = $sth->fetchrow_hashref;
    }

    my $current_time = DateTime->now;
    my %months_at_status;
    for my $issue( keys %last_status_dates ){
        $last_status_dates{$issue}
            = DateTime::Format::MySQL->parse_datetime( $last_status_dates{$issue} );

        my $duration = $current_time->subtract_datetime_absolute( $last_status_dates{$issue} );
        $months_at_status{$issue} = $duration->in_units('months');
    }

    my ( %status_durations, %status_duration_issues );
    for my $issue( keys %statuses ){
        my $bin;
        if ( $months_at_status{ $issue } < 3 ){
            $bin = '0-3 months';
        }
        elsif ( $months_at_status{ $issue } < 6 ){
            $bin = '3-6 months';
        }
        elsif ( $months_at_status{ $issue} < 9 ){
            $bin = '7-9 months';
        }
        elsif ( $months_at_status{ $issue } < 12 ){
            $bin = '10-12 months';
        }
        else{
            $bin = '>12 months';
        }

        $status_durations{ $statuses{$issue} }{$bin}++;
        $status_duration_issues{ $statuses{$issue} }{$bin} = $status_duration_issues{ $statuses{$issue} }{$bin} . 'i' . $issue;
    }

    my @bins = ( '0-3 months', '3-6 months', '7-9 months', '10-12 months', '>12 months' );
    my @statuses = qw ( New Design VectorConstructionCustom TissueCultureCustom
                        VectorConstructionHT TissueCultureHT PreInjectionQCCustom
                        PreInjectionQCHT FacultyMicroInjection ModelAcquisitionInitiated
                        ModelAcquisitionCompleted MGP Terminated );

    return ( \@statuses, \@bins, \%status_durations, \%status_duration_issues );
}

sub get_languishing_report_list{
    my ( $self, $issue_str ) = @_;

    my $dbh = DBI->connect( 'DBI:mysql:' . $self->redmine_db, $self->redmine_db_username, $self->redmine_db_password );

    my $sth = $dbh->prepare(
        "SELECT issues.id, issues.subject, users.firstname, users.lastname, issue_statuses.name, custom_values.value, issues.description FROM issues join projects on projects.id = issues.project_id left outer join users on users.id = issues.assigned_to_id join issue_statuses on issues.status_id = issue_statuses.id join custom_fields_trackers on issues.tracker_id = custom_fields_trackers.tracker_id join custom_fields on custom_fields_trackers.custom_field_id = custom_fields.id join custom_values on custom_values.custom_field_id = custom_fields.id WHERE issues.id in $issue_str and projects.name = 't87 bespoke targeting' and custom_fields.name = 'Requestor' and custom_values.customized_id = issues.id"
    );
    $sth->execute;

    my %reports;
    my $r = $sth->fetchrow_hashref;
    while ($r){
        $reports{ $r->{subject} } = {
            issue => $r->{id},
            marker_symbol => $r->{subject},
            assignee => $r->{firstname} . ' ' . $r->{lastname},
            status => $r->{name},
            requestor => $r->{value},
            description => $r->{description}
        };
        $r = $sth->fetchrow_hashref;
    }

    my @report_list;
    for my $marker_symbol ( sort keys %reports ){
        push @report_list, $reports{ $marker_symbol };
    }

    return \@report_list;
}
__PACKAGE__->meta->make_immutable;
