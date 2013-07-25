package HTGT::Controller::ESDistribution;
use Moose;
use HTGT::Utils::ESDistributionCheck;
use HTGT::Utils::ESPickLists;
use namespace::autoclean;
use Const::Fast;
use Catalyst qw/
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    /;

BEGIN { extends 'Catalyst::Controller'; }

const my %CAT_HEADINGS => (
    no_clones              => 'QC Not Started - No Clones',
    all_JM8A1_N3_clones    => 'QC Not Started - Only JM8A1.N3 Clones',
    clones_available       => 'QC Not Started - Clones at WTSI',
    clones_elsewhere       => 'QC Not Started - Clones Available (Not at WTSI)',
    mirKO_clones           => 'QC Not Started - mirKO Clones',
    on_hold                => 'On Hold',
    qc_complete            => 'QC Complete',
    qc_failed              => 'QC Failed',
    inactive               => 'Inactive',
    qc_started_0           => 'QC Started - No Clones Picked',
    qc_started_1           => 'QC Started - 1 Clone Picked',
    qc_started_2           => 'QC Started - 2 Clones Picked',
    qc_started_3           => 'QC Started - 3 Clones Picked',
    qc_started_4           => 'QC Started - 4 Clones Picked',
    qc_started_5           => 'QC Started - 5 Clones Picked',
    qc_started_more_than_5 => 'QC Started - >5 Clones Picked',
    has_mi_attempt         => 'Genes with MI Attempt',
    no_valid_clones        => 'QC Not Started - No Valid Clones'
);

=head1 NAME

HTGT::Controller::ESDistribution - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 view

=cut

sub view : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $distribution_check = HTGT::Utils::ESDistributionCheck->new_with_config();

    my $gene_info_list;
    if ( defined $c->session->{gene_info_list} ) {
        $gene_info_list = $c->session->{gene_info_list};
    }
    else {
        $gene_info_list = $distribution_check->get_gene_info_list( $c->model('HTGTDB')->schema );
        $c->session->{gene_info_list} = $gene_info_list;
    }

    my ( $bash_report, $mgp_report, $mrc_report )
        = $distribution_check->get_reports_from_gene_info_list($gene_info_list);

    $c->stash( bash_report => $bash_report );
    $c->stash( mgp_report  => $mgp_report );
    $c->stash( mrc_report  => $mrc_report );
    $c->stash( template => 'esdistribution/view.tt' );
}

sub pick_list : Local : Args(1) {
    my ( $self, $c, $consortium ) = @_;

    my $gene_info_list;
    if ( defined $c->session->{gene_info_list} ) {
        $gene_info_list = $c->session->{gene_info_list};
    }
    else {
        my $distribution_check = HTGT::Utils::ESDistributionCheck->new_with_config();
        $gene_info_list = $distribution_check->get_gene_info_list( $c->model('HTGTDB')->schema );
        $c->session->{gene_info_list} = $gene_info_list;
    }

    my $es_pick_lists = HTGT::Utils::ESPickLists->new_with_config();
    my ( $unpicked, $failed, $all_aborted )
        = $es_pick_lists->get_pick_lists( $gene_info_list, $consortium );

    $c->stash( unpicked => sort_by_marker_symbol($unpicked) );
    $c->stash( failed => sort_by_marker_symbol($failed) );
    $c->stash( aborted => sort_by_marker_symbol($all_aborted) );
    $c->stash( consortium => $consortium );
    $c->stash( template => 'esdistribution/pick_list.tt' );
}

sub basic : Local : Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $category, $consortium, $group ) = $params =~ /^(.+)___(.+)___(.+)$/;
    my %group_info = (
        category   => $CAT_HEADINGS{$category},
        consortium => $consortium,
        group      => $group
    );

    my $genes;
    for my $gene ( @{ $c->session->{gene_info_list} } ) {
        if (    defined $gene->{$category}
            and $gene->{consortium} eq $consortium
            and $gene->{group} eq $group )
        {

            my @status_dates;
            for my $date ( keys %{ $gene->{status_dates} } ) {
                push @status_dates, $date . ' = ' . $gene->{status_dates}{$date};
            }
            my $status_date_string = join( '; ', @status_dates );

            my %details = (
                mgi_accession_id => $gene->{mgi_accession_id},
                marker_symbol    => $gene->{marker_symbol},
                status_dates     => $status_date_string
            );
            push @{$genes}, \%details;
        }
    }
    $c->stash( group_info => \%group_info );
    $c->stash( genes      => sort_by_marker_symbol($genes) );
    $c->stash( template   => 'esdistribution/basic.tt' );
}

sub invalid_clones : Local : Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $consortium, $group ) = $params =~ /^(.+)___(.+)$/;
    my %group_info = (
        category   => $CAT_HEADINGS{no_valid_clones},
        consortium => $consortium,
        group      => $group
    );

    my $genes;
    for my $gene ( @{ $c->session->{gene_info_list} } ) {
        if (    defined $gene->{no_valid_clones}
            and $gene->{consortium} eq $consortium
            and $gene->{group} eq $group )
        {

            my @status_dates;
            for my $date ( keys %{ $gene->{status_dates} } ) {
                push @status_dates, $date . ' = ' . $gene->{status_dates}{$date};
            }
            my $status_date_string = join( '; ', @status_dates );

            my %details = (
                mgi_accession_id => $gene->{mgi_accession_id},
                marker_symbol    => $gene->{marker_symbol},
                status_dates     => $status_date_string,
                invalid_clones   => $gene->{invalid_clones}
            );
            push @{$genes}, \%details;
        }
    }
    $c->stash( group_info => \%group_info );
    $c->stash( genes      => sort_by_marker_symbol($genes) );
    $c->stash( template   => 'esdistribution/invalid_clones.tt' );
}

sub clones_available : Local : Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $category, $consortium, $group ) = $params =~ /^(.+)___(.+)___(.+)$/;
    my %group_info = (
        category   => $CAT_HEADINGS{$category},
        consortium => $consortium,
        group      => $group
    );

    my $genes;
    for my $gene ( @{ $c->session->{gene_info_list} } ) {
        if (    defined $gene->{$category}
            and $gene->{consortium} eq $consortium
            and $gene->{group} eq $group )
        {

            my @status_dates;
            for my $date ( keys %{ $gene->{status_dates} } ) {
                push @status_dates, $date . ' = ' . $gene->{status_dates}{$date};
            }
            my $status_date_string = join( '; ', @status_dates );

            my %details = (
                mgi_accession_id    => $gene->{mgi_accession_id},
                marker_symbol       => $gene->{marker_symbol},
                status_dates        => $status_date_string,
                clone_names         => $gene->{clone_names},
                parental_cell_lines => $gene->{parental_cell_lines}
            );
            push @{$genes}, \%details;
        }
    }
    $c->stash( group_info => \%group_info );
    $c->stash( genes      => sort_by_marker_symbol($genes) );
    $c->stash( template   => 'esdistribution/clones_available.tt' );
}

sub clones_picked : Local : Args(1) {
    my ( $self, $c, $params ) = @_;

    my ( $category, $consortium, $group ) = $params =~ /^(.+)___(.+)___(.+)$/;
    my %group_info = (
        category   => $CAT_HEADINGS{$category},
        consortium => $consortium,
        group      => $group
    );

    my $gene_info_list = $c->session->{gene_info_list};

    my $genes;
    for my $gene ( @{ $c->session->{gene_info_list} } ) {
        if (    defined $gene->{$category}
            and $gene->{consortium} eq $consortium
            and $gene->{group} eq $group )
        {

            my @status_dates;
            for my $date ( keys %{ $gene->{status_dates} } ) {
                push @status_dates, $date . ' = ' . $gene->{status_dates}{$date};
            }
            my $status_date_string = join( '; ', @status_dates );

            my %details = (
                mgi_accession_id => $gene->{mgi_accession_id},
                marker_symbol    => $gene->{marker_symbol},
                status_dates     => $status_date_string,
                picked_clones    => $gene->{piq_wells},
                epd_ancestors    => $gene->{epd_ancestors},
                unpicked_clones  => $gene->{unpicked_epd_wells}
            );
            push @{$genes}, \%details;
        }
    }
    $c->stash( group_info => \%group_info );
    $c->stash( genes      => sort_by_marker_symbol($genes) );
    $c->stash( template   => 'esdistribution/clones_picked.tt' );
}

sub sort_by_marker_symbol{
    my ( $gene_list ) = @_;

    my %marker_symbol_to_gene_map;
    for my $gene ( @{ $gene_list } ){
        $marker_symbol_to_gene_map{ $gene->{marker_symbol} } = $gene;
    }

    my @sorted_gene_list;
    for my $marker_symbol( sort keys %marker_symbol_to_gene_map ){
        push @sorted_gene_list, $marker_symbol_to_gene_map{ $marker_symbol };
    }

    return \@sorted_gene_list;
}

=head1 AUTHOR

Mark Quinton-Tulloch

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

