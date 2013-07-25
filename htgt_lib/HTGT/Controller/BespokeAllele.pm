package HTGT::Controller::BespokeAllele;
use Moose;
use namespace::autoclean;
use HTGT::Utils::BespokeAlleleCheck;
use HTGT::Utils::BespokeStatus;
use HTGT::Utils::BespokeLanguishing;
use Const::Fast;

BEGIN {extends 'Catalyst::Controller'; }

const my %IMITS_TO_REDMINE_PRIORITY => (
    Low    => 'Low',
    Medium => 'Normal',
    High   => 'High'
);

const my %ADD_SPACES => (
    'PreInjectionQCCustom'      => 'Pre Injection QC Custom',
    'PreInjectionQCHT'          => 'Pre Injection QC HT',
    'ModelAcquisitionInitiated' => 'Model Acquisition Initiated',
    'ModelAcquisitionCompleted' => 'Model Acquisition Completed',
    'FacultyMicroInjection'     => 'Faculty_Micro-Injection',
    'Design'                    => 'Design',
    'VectorConstructionCustom'  => 'VectorConstructionCustom',
    'VectorConstructionHT'      => 'VectorConstructionHT',
    'TissueCultureCustom'       => 'TissueCultureCustom',
    'TissueCultureHT'           => 'TissueCultureHT',
    'New'                       => 'New',
    'Terminated'                => 'Terminated',
    'MGP'                       => 'MGP'
);

=head1 NAME

HTGT::Controller::BespokeAllele - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub view :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(template => 'bespokeallele/view.tt');
}

sub status_report :Local :Args(0){
    my ( $self, $c ) = @_;

    my $bespoke_status = HTGT::Utils::BespokeStatus->new_with_config();
    my ( $requestors, $counts ) = $bespoke_status->get_status_count();

    $c->stash( requestors => $requestors );
    $c->stash( counts => $counts );
    $c->stash( template => 'bespokeallele/status_report.tt' );
}

sub status_report_list :Local :Args(1){
    my ( $self, $c, $params ) = @_;

    my ( $status, $requestor ) = $params =~ /^(.+)___(.+)$/;
    $status = $ADD_SPACES{$status};

    my $bespoke_status = HTGT::Utils::BespokeStatus->new_with_config();
    my $status_report_list = $bespoke_status->get_status_report_list( $status, $requestor );

    $c->stash( column_heading => $status );
    $c->stash( row_heading => $requestor );
    $c->stash( allele_list => $status_report_list );
    $c->stash( template => 'bespokeallele/allele_list.tt' );
}

sub languishing_report :Local :Args(0){
    my ( $self, $c ) = @_;

    my $bespoke_languishing = HTGT::Utils::BespokeLanguishing->new_with_config();
    my ( $statuses, $durations, $counts, $issues ) = $bespoke_languishing->get_languishing_count();

    $c->stash( statuses => $statuses );
    $c->stash( durations => $durations );
    $c->stash( counts => $counts );
    $c->stash( issues => $issues );
    $c->stash( template => 'bespokeallele/languishing_report.tt' );
}

sub languishing_report_list :Local :Args(2){
    my ( $self, $c, $params, $issue_str ) = @_;

    my ( $status, $duration ) = $params =~ /^(.+)___(.+)$/;
    $issue_str =~ s/i/,/g;
    $issue_str = '(' . substr($issue_str,1) . ')';

    my $bespoke_languishing = HTGT::Utils::BespokeLanguishing->new_with_config();
    my $languishing_report_list = $bespoke_languishing->get_languishing_report_list( $issue_str );

    $c->stash( allele_list => $languishing_report_list );
    $c->stash( row_heading => $status );
    $c->stash( column_heading => $duration );
    $c->stash( template => 'bespokeallele/allele_list.tt' );
}

sub allele_tracker :Local :Args(0){
    my ( $self, $c ) = @_;

    my $allele_check = HTGT::Utils::BespokeAlleleCheck->new_with_config();
    my $alleles = $allele_check->get_allele_list;

    $c->stash(alleles => $alleles );

    $c->stash(template => 'bespokeallele/allele_tracker.tt');
}

sub create_ticket :Local :Args(1){
    my ( $self, $c, $param_string ) = @_;

    my ( $marker_symbol, $mgi_accession_id, $priority, $req_project ) = $param_string =~ /^(.+)-acc=(.+)-pr=(.+)-reqp=(.+)$/;

    my $allele;
    $allele->{marker_symbol} = $marker_symbol;
    $allele->{mgi_accession_id} = $mgi_accession_id;
    $allele->{priority} = $IMITS_TO_REDMINE_PRIORITY{$priority};
    $allele->{requesting_project} = $req_project;

    my $allele_check = HTGT::Utils::BespokeAlleleCheck->new_with_config();
    $allele_check->create_redmine_ticket( $allele );

    $c->stash( status_msg=> 'Created ticket for ' . $marker_symbol );
    $c->go('list');
}

=head1 AUTHOR

Mark Quinton-Tulloch

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

