package HTGT::Utils::ESDistributionCheck;

use Moose;
use HTGT::Utils::RESTClient;
use namespace::autoclean;
use Const::Fast;
use DBI;
use HTGT::DBFactory;

with qw( MooseX::SimpleConfig MooseX::Log::Log4perl );

has '+configfile' => ( default => $ENV{ES_DISTRIBUTE_CHECK_CONF} );

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

const my %STATUS_MAP => (
    'Conflict'                          => 'on_hold',
    'Aborted - ES Cell QC Failed'       => 'qc_failed',
    'Assigned - ES Cell QC In Progress' => 'qc_started',
    'Inspect - MI Attempt'              => 'on_hold',
    'Inspect - GLT Mouse'               => 'on_hold',
    'Inspect - Conflict'                => 'on_hold',
    'Interest'                          => 'qc_not_started',
    'Inactive'                          => 'inactive',
    'Withdrawn'                          => 'inactive',
    'Assigned'                          => 'qc_not_started',
    'Assigned - ES Cell QC Complete'    => 'qc_complete'
);

const my %ESCELL_PIPELINE_MAP => (
    1 => 'KOMP_CSD',
    2 => 'KOMP_REGENERON',
    3 => 'NorCOMM',
    4 => 'EUCOMM',
    5 => 'mirKO',
    6 => 'SangerMGP',
    7 => 'EUCOMMTools',
    8 => 'EUCOMMToolsCre'
);

const my $MAX_GENES_IN_REST_CALL => 5;
const my @CONSORTIA => ( 'MGP', 'BaSH', 'MRC' );
const my @GROUPS    => ( 'BCM', 'Harwell', 'WTSI', 'Unspecified',
                         'MGPinterest', 'WTSI_Blood_A', 'WTSI_Bone_A',
                         'WTSI_Cancer_A', 'WTSI_Cre', 'WTSI_Fat_A',
                         'WTSI_Hear_A', 'WTSI_IBD_A', 'WTSI_Infection_A',
                         'WTSI_MGPcollab_A', 'WTSI_Malaria_A', 'WTSI_Metabolism_A',
                         'WTSI_Rarediseases_A', 'WTSI_Sense_A' );

sub get_gene_info{
    my ( $self, $dbh, $genes_with_attempts ) = @_;

    my $sth = $dbh->prepare(
        qq[
        SELECT intermediate_report.mgi_accession_id, intermediate_report.gene as marker_symbol,
        intermediate_report.consortium, intermediate_report.production_centre, intermediate_report.sub_project,
        intermediate_report.priority, intermediate_report.mi_plan_status, mi_plan_statuses.name as status,
        mi_plan_status_stamps.updated_at as status_datetime
        from intermediate_report left outer join mi_plan_status_stamps on mi_plan_status_stamps.mi_plan_id = intermediate_report.mi_plan_id join
        mi_plan_statuses on mi_plan_statuses.id = mi_plan_status_stamps.status_id join mi_plans on mi_plans.id = intermediate_report.mi_plan_id
        where (intermediate_report.consortium = 'BaSH' or intermediate_report.consortium = 'MGP' or intermediate_report.consortium = 'MRC')
        and intermediate_report.mi_plan_id is not null and mi_plans.is_active = '1' and mi_plans.phenotype_only is not true
        ]
    );

    $sth->execute();

    my ( $gene_info, $qc_started, $qc_not_started );
    my $r = $sth->fetchrow_hashref;
    while ($r) {
        next unless defined $r->{mgi_accession_id};

        my $group = $r->{consortium} eq 'MGP' ? $r->{sub_project} : $r->{production_centre};
        $group = 'Unspecified' unless defined $group and $group ne '';

        my $key = $r->{mgi_accession_id} . '_' . $r->{consortium} . '_' . $group;

        $gene_info->{$key} = {
            mgi_accession_id => $r->{mgi_accession_id},
            marker_symbol    => $r->{marker_symbol},
            consortium       => $r->{consortium},
            priority         => $r->{priority},
            group            => $group,
            mi_plan_status   => $r->{mi_plan_status}
        };

        $gene_info->{$key}{has_mi_attempt} = 1 if defined $genes_with_attempts->{$key};

        if ( defined $r->{status} ){
            my ( $status_date ) = $r->{status_datetime} =~ /^(\d\d\d\d-\d\d-\d\d)/;
            $gene_info->{$key}{status_dates}{ $r->{status} } = $status_date;
        }

        ( $gene_info, $qc_started, $qc_not_started ) = $self->add_gene_status( $gene_info, $key, $r->{mi_plan_status}, $qc_started, $qc_not_started );

        $r = $sth->fetchrow_hashref;
    }

    my @qcs = keys %{$qc_started};
    my @qcns = keys %{$qc_not_started};
    return ( $gene_info, \@qcs, \@qcns );
}

sub get_gene_info_list {
    my ( $self, $schema ) = @_;


    my $imits_dbh = DBI->connect( 'DBI:Pg:' . $self->imits_db, $self->imits_db_username, $self->imits_db_password );

    my $genes_with_attempts = $self->get_mi_attempts_gene_list( $imits_dbh );

    my ( $gene_info, $qc_started, $qc_not_started ) = $self->get_gene_info( $imits_dbh, $genes_with_attempts );

    my ( $escell_details, $escell_project_ids ) = $self->get_escell_details($gene_info, $imits_dbh);

    $gene_info = $self->add_clone_availability_data( $schema, $gene_info, $escell_details, $escell_project_ids );

    my $piq_counts;
    ($gene_info, $piq_counts) = add_picked_clone_data( $schema, $escell_details, $gene_info );

    $gene_info = add_qc_started_statuses( $schema, $qc_started, $gene_info, $escell_details, $piq_counts );

    $gene_info = add_qc_not_started_statuses( $qc_not_started, $gene_info, $escell_details );

    my @gene_info_list = values %{$gene_info};

    return \@gene_info_list;
}

sub create_lists_from_reports {
    my ( $bash_report, $mgp_report, $mrc_report ) = @_;

    my ( @bash_list, @mgp_list, @mrc_list );

    for my $bash_group ( sort keys %{$bash_report} ) {
        push @bash_list, $bash_report->{$bash_group} unless $bash_group eq 'Unspecified';
    }
    push @bash_list, $bash_report->{Unspecified} if defined $bash_report->{Unspecified};

    for my $mgp_group ( sort keys %{$mgp_report} ) {
        push @mgp_list, $mgp_report->{$mgp_group} unless $mgp_group eq 'Unspecified';
    }
    push @mgp_list, $mgp_report->{Unspecified} if defined $mgp_report->{Unspecified};

    for my $mrc_group ( sort keys %{$mrc_report} ) {
        push @mrc_list, $mrc_report->{$mrc_group} unless $mrc_group eq 'Unspecified';
    }
    push @mrc_list, $mrc_report->{Unspecified} if defined $mrc_report->{Unspecified};

    return ( \@bash_list, \@mgp_list, \@mrc_list );
}

sub get_mi_attempts_gene_list {
    my ($self, $dbh) = @_;

    my $sth
        = $dbh->prepare(
        "SELECT genes.mgi_accession_id, intermediate_report.consortium, intermediate_report.production_centre, intermediate_report.sub_project from mi_attempts join es_cells on mi_attempts.es_cell_id = es_cells.id join genes on genes.id = es_cells.gene_id join intermediate_report on intermediate_report.mi_plan_id = mi_attempts.mi_plan_id where mi_attempts.report_to_public = '1' and mi_attempts.es_cell_id is not null and (intermediate_report.consortium = 'BaSH' or intermediate_report.consortium = 'MGP' or intermediate_report.consortium = 'MRC')"
        );
    $sth->execute();

    my %genes;
    my $r = $sth->fetchrow_hashref;
    while ($r) {
        my $group = $r->{consortium} eq 'MGP' ? $r->{sub_project} : $r->{production_centre};
        $group = 'Unspecified' unless defined $group and $group ne '';

        $genes{ $r->{mgi_accession_id} . '_' . $r->{consortium} . '_' . $group }++;
        $r = $sth->fetchrow_hashref;
    }

    return \%genes;
}

sub add_gene_status{
    my ( $self, $gene_info, $key, $mi_plan_status, $qc_started, $qc_not_started ) = @_;

    my $status = $STATUS_MAP{ $mi_plan_status };

    if ( defined $gene_info->{$key}{has_mi_attempt} ){
        return ( $gene_info, $qc_started, $qc_not_started );
    }

    if ( $status !~/_started$/ ){
        $gene_info->{$key}{$status} = 1;
        return ( $gene_info, $qc_started, $qc_not_started );
    }

    if ( $status eq 'qc_started' ){
        $qc_started->{$key}++;
        return ( $gene_info, $qc_started, $qc_not_started );
    }

    $qc_not_started->{$key}++;
    return ( $gene_info, $qc_started, $qc_not_started );
}

sub add_gene_status_old {
    my ( $self, $plan, $qc_started, $qc_not_started, $schema, $gene ) = @_;

    my $group = $plan->{consortium_name} eq 'MGP' ? $plan->{sub_project_name} : $plan->{production_centre_name};
    $group = 'Unspecified' unless defined $group and $group ne '';
    $gene->{group} = $group;

    my $status = $STATUS_MAP{ $plan->{status_name} };

    if ( defined $gene->{has_mi_attempt} or $status !~ /_started$/ ) {
        $gene->{$status} = 1;
        return ( $qc_started, $qc_not_started, $gene );
    }

    if ( $status eq 'qc_started' ) {
        push @{$qc_started}, $plan->{mgi_accession_id} . '_' . $plan->{consortium_name}
            if defined $plan->{mgi_accession_id};
        return ( $qc_started, $qc_not_started, $gene );
    }

    push @{$qc_not_started}, $plan->{mgi_accession_id} . '_' . $plan->{consortium_name}
        if defined $plan->{mgi_accession_id};

    return ( $qc_started, $qc_not_started, $gene );
}

sub get_genes_from_compound_key {
    my ( $list, $gene_info ) = @_;

    my @mgi_accession_ids;
    for my $key ( @{$list} ) {
        push @mgi_accession_ids, $gene_info->{$key}{mgi_accession_id};
    }

    return \@mgi_accession_ids;
}

sub add_qc_started_statuses {
    my ( $schema, $qc_started, $gene_info, $escell_details, $piq_counts ) = @_;

    for my $ck ( @{$qc_started} ) {
        my ($mgi_acc_id) = $ck =~ /^(MGI:\d+)_/;
        my $piq_well_count = $piq_counts->{$mgi_acc_id};
        if ( defined $piq_well_count ) {
            my $clone_picked_status = $piq_well_count < 6 ? 'qc_started_' . $piq_well_count : 'qc_started_more_than_5';
            $gene_info->{$ck}{$clone_picked_status} = 1;
        }
        else {
            $gene_info->{$ck}{qc_started_0} = 1;
        }
    }

    return $gene_info;
}

sub add_clone_availability_data {
    my ( $self, $schema, $gene_info, $escell_details, $escell_project_ids ) = @_;

    my $invalid_project_ids = $self->get_projects_failed_by_annotation( $schema, $escell_project_ids );

    for my $ck ( keys %{$gene_info} ) {
        my ($mgi_acc_id) = $ck =~ /^(MGI:\d+)_/;

        my ( @clone_names, %cell_lines, @clones_at_wtsi, @clones_at_wtsi_MGP, @invalid_clones );
        my $has_non_JM8A1_N3_clone     = 0;
        my $clones_available_count     = 0;
        my $clones_available_count_MGP = 0;
        my $has_valid_clones           = 0;
        for my $es_cell ( @{ $escell_details->{$mgi_acc_id} } ) {
            if ( defined $invalid_project_ids->{ $es_cell->{project_id} } ) {
                push @invalid_clones, $es_cell->{name} . ' (' . $es_cell->{pipeline} . ')';
                next;
            }
            $has_valid_clones = 1;

            push @clone_names, $es_cell->{name} . ' (' . $es_cell->{pipeline} . ')';
            $cell_lines{ $es_cell->{cell_line} }++;
            $has_non_JM8A1_N3_clone = 1 unless $es_cell->{cell_line} eq 'JM8A1.N3';

            if ( $es_cell->{name} =~ /^EPD/ ) {
                $clones_available_count++;
                push @clones_at_wtsi, $es_cell->{name} . ' (' . $es_cell->{pipeline} . ')';
                unless ( $es_cell->{cell_line} eq 'JM8A1.N3' ) {
                    $clones_available_count_MGP++;
                    push @clones_at_wtsi_MGP, $es_cell->{name} . ' (' . $es_cell->{pipeline} . ')';
                }
            }
        }

        if ( $has_valid_clones == 0 and scalar @invalid_clones > 0 ){
            $gene_info->{$ck}{no_valid_clones} = 1;
        }
        if ( $has_non_JM8A1_N3_clone == 0 and $has_valid_clones == 1 ){
            $gene_info->{$ck}{JM8A1_N3_flag} = 1;
        }

        $gene_info->{$ck}{clone_names} = join( '; ', @clone_names );
        $gene_info->{$ck}{parental_cell_lines} = join( '; ', keys %cell_lines );
        $gene_info->{$ck}{invalid_clones} = join( '; ', @invalid_clones );
        if ( $gene_info->{$ck} eq 'MGP' ){
            $gene_info->{$ck}{clones_available_count} = $clones_available_count_MGP;
            $gene_info->{$ck}{clones_at_wtsi} = join( '; ', @clones_at_wtsi_MGP );
        }
        else{
            $gene_info->{$ck}{clones_available_count} = $clones_available_count;
            $gene_info->{$ck}{clones_at_wtsi} = join( '; ', @clones_at_wtsi );
        }
    }

    return $gene_info;
}

sub add_picked_clone_data {
    my ( $schema, $escell_details, $gene_info ) = @_;

    my ( $piq_well_statuses, $piq_counts, $piq_wells, $parent_wells ) = get_piq_well_statuses( $schema, $gene_info );

    for my $gene ( keys %{$piq_wells} ) {
        my ( @fp_ancestor_wells, @epd_ancestor_wells, %epd_wells_picked, @pw_statuses );

        for my $piq_well ( @{ $piq_wells->{$gene} } ) {
            my $well = $schema->resultset('Well')->find( { well_id => $parent_wells->{$piq_well} } );
            while ( $well->well_name !~ /^\w?EPD/ ) {
                push @fp_ancestor_wells, $well->well_name if $well->well_name =~ /^\w?FP/;
                $well = $schema->resultset('Well')->find( { well_id => $well->parent_well_id } );
            }
            push @epd_ancestor_wells, $well->well_name;
            $epd_wells_picked{ $well->well_name }++;

            push @pw_statuses, $piq_well . ' - ' . $piq_well_statuses->{$piq_well};
        }

        my @available_clones = @{ $escell_details->{$gene} };
        my ( @picked_epd_wells,           @unpicked_epd_wells );
        my ( @unpicked_epd_wells_at_wtsi, @unpicked_epd_wells_at_wtsi_MGP );
        for my $clone (@available_clones) {
            if ( defined $epd_wells_picked{ $clone->{name} } ) {
                push @picked_epd_wells, $clone->{name} . ' (' . $clone->{cell_line} . ')';
            }
            else {
                push @unpicked_epd_wells, $clone->{name} . ' (' . $clone->{cell_line} . ')';
                if ( $clone->{name} =~ /^EPD/ ) {
                    push @unpicked_epd_wells_at_wtsi,     $clone->{name} . ' (' . $clone->{pipeline} . ')';
                    push @unpicked_epd_wells_at_wtsi_MGP, $clone->{name} . ' (' . $clone->{pipeline} . ')'
                        unless $clone->{cell_line} eq 'JM8A1.N3';
                }
            }
        }

        for my $consortium( @CONSORTIA ){
            for my $group ( @GROUPS ){
                my $ck = $gene . '_' . $consortium . '_' . $group;
                next unless defined $gene_info->{$ck};

                $gene_info->{$ck}{piq_wells} = join( '; ', @{ $piq_wells->{$gene} } );
                $gene_info->{$ck}{fp_ancestors} = join( '; ', @fp_ancestor_wells );
                $gene_info->{$ck}{epd_ancestors} = join( '; ', @epd_ancestor_wells );
                $gene_info->{$ck}{piq_well_statuses} = join( '; ', @pw_statuses );
                $gene_info->{$ck}{unpicked_epd_wells} = join( '; ', @unpicked_epd_wells );
                $gene_info->{$ck}{picked_epd_wells} = join( '; ', @picked_epd_wells );
                if ( $consortium eq 'MGP' ){
                    $gene_info->{$ck}{unpicked_epd_wells_at_wtsi} = join ( '; ', @unpicked_epd_wells_at_wtsi_MGP );
                }
                else{
                    $gene_info->{$ck}{unpicked_epd_wells_at_wtsi} = join( '; ', @unpicked_epd_wells_at_wtsi )
                }
            }
        }
    }

    return ( $gene_info, $piq_counts );
}

sub get_piq_well_statuses{
    my ( $schema, $gene_info ) = @_;

    my @gi_keys = keys %{$gene_info};
    my $gene_ids = get_genes_from_compound_key( \@gi_keys, $gene_info );
    my %gene_ids_hash = map { $_ => 1 } @{$gene_ids};

    my ( %piq_counts, $piq_wells, $parent_wells, %piq_well_statuses, %piq_well_seen );

    my $sth = $schema->storage->dbh->prepare(
        'select distinct mgi_gene.mgi_accession_id, plate.name, well.well_name, well.parent_well_id, '
        . 'well_data.data_type, well_data.data_value '
        . 'from plate '
        . 'join well on plate.plate_id = well.plate_id '
        . 'join project on project.design_instance_id = well.design_instance_id '
        . 'join mgi_gene on mgi_gene.mgi_gene_id = project.mgi_gene_id '
        . 'join well_data on well.well_id = well_data.well_id '
        . 'where plate.type = \'PIQ\''
    );
    $sth->execute();

    my $r = $sth->fetchrow_hashref;
    while ($r) {
        if ( defined $gene_ids_hash{ $r->{MGI_ACCESSION_ID} } ){
            $piq_well_statuses{ $r->{WELL_NAME} } = 'In TC' unless defined $piq_well_statuses{ $r->{WELL_NAME} };
            unless ( defined $piq_well_seen{ $r->{WELL_NAME} } ) {
                $piq_counts{ $r->{MGI_ACCESSION_ID} }++;
                push @{ $piq_wells->{ $r->{MGI_ACCESSION_ID} } }, $r->{WELL_NAME};
                push @{ $parent_wells->{ $r->{WELL_NAME} } },     $r->{PARENT_WELL_ID};
                $piq_well_seen{ $r->{WELL_NAME} }++;
            }
            if ( $r->{DATA_TYPE} eq 'COMMENTS' ) {
                $piq_well_statuses{ $r->{WELL_NAME} } = 'Died';
            }
            elsif ( $r->{DATA_TYPE} eq 'targeting_pass' ) {
                $piq_well_statuses{ $r->{WELL_NAME} } = $r->{DATA_VALUE} =~ /^pass/ ? 'Pass' : 'Fail';
            }
        }
        $r = $sth->fetchrow_hashref;
    }

    return ( \%piq_well_statuses, \%piq_counts, $piq_wells, $parent_wells );
}

sub add_qc_not_started_statuses {
    my ( $qc_not_started, $gene_info, $escell_details ) = @_;

    for my $ck ( @{$qc_not_started} ) {
        my ($mgi_acc_id, $consortium) = $ck =~ /^(MGI:\d+)_(.+)_.+$/;
        my $qc_not_started_status;
        $qc_not_started_status = 'no_clones' unless scalar @{ $escell_details->{$mgi_acc_id} } > 0;
        for my $es_cell ( @{ $escell_details->{$mgi_acc_id} } ) {
            my $pl = $es_cell->{pipeline};
            if ( $pl eq 'KOMP_CSD' or $pl =~ /^EUCOMM/ or $pl eq 'SangerMGP' ) {
                if ( $es_cell->{name} =~ /^EPD/ ) {
                    $qc_not_started_status = 'clones_available';
                    last;
                }
                else {
                    $qc_not_started_status = 'clones_elsewhere';
                }
            }
            else {
                if ( $pl eq 'mirKO' ) {
                    $qc_not_started_status = 'mirKO_clones';
                }
                else {
                    $qc_not_started_status = 'clones_elsewhere'
                        unless defined $qc_not_started_status
                            and $qc_not_started_status eq 'mirKO_clones';
                }
            }
        }
        $qc_not_started_status = 'no_valid_clones' if defined $gene_info->{$ck}{no_valid_clones};

        if ( $consortium eq 'MGP' and defined $gene_info->{$ck}{JM8A1_N3_flag} ) {
            $qc_not_started_status = 'all_JM8A1_N3_clones';
        }

        $gene_info->{$ck}{$qc_not_started_status} = 1;
    }

    return $gene_info;
}

sub get_projects_failed_by_annotation {
    my ( $self, $schema, $escell_project_ids ) = @_;

    my ( %invalid_project_ids, @pid_strings );
    my @espids = @{$escell_project_ids};

    while ( my @espids_slice = splice @espids, 0, 1000 ) {
        my $project_ids_str = join( "','", @espids_slice );
        $project_ids_str = "'" . $project_ids_str . "'";
        push @pid_strings, $project_ids_str;
    }

    for my $pid_string (@pid_strings) {
        my $check_validated_by_annotation_query
            = 'select distinct project.project_id, design.validated_by_annotation '
            . 'from project '
            . 'join design_instance on project.design_instance_id = design_instance.design_instance_id '
            . 'join design on design.design_id = design_instance.design_id '
            . 'where project.project_id in ('
            . $pid_string . ')';

        my $sth = $schema->storage->dbh->prepare($check_validated_by_annotation_query);
        $sth->execute();

        my $r = $sth->fetchrow_hashref;
        while ($r) {
            if ( defined $r->{VALIDATED_BY_ANNOTATION} and $r->{VALIDATED_BY_ANNOTATION} eq 'no' ) {
                $invalid_project_ids{ $r->{PROJECT_ID} }++;
            }
            $r = $sth->fetchrow_hashref;
        }
    }

    return \%invalid_project_ids;
}

sub get_escell_details {
    my ( $self, $gene_info, $imits_dbh ) = @_;

    my @gi_keys = keys %{$gene_info};
    my $gene_list = get_genes_from_compound_key( \@gi_keys, $gene_info );

    my $gene_str = join( "','", @{$gene_list} );
    $gene_str = "('" . $gene_str . "')";

    my $sql =
          qq[
            SELECT genes.mgi_accession_id, targ_rep_es_cells.name, targ_rep_es_cells.parental_cell_line, 
            targ_rep_es_cells.pipeline_id, targ_rep_es_cells.ikmc_project_id
            FROM genes join targ_rep_alleles on genes.id = targ_rep_alleles.gene_id
            join targ_rep_es_cells on targ_rep_es_cells.allele_id = targ_rep_alleles.id
            join targ_rep_mutation_types
            on (
             targ_rep_mutation_types.id = targ_rep_alleles.mutation_type_id
             and (targ_rep_mutation_types.name = 'Conditional Ready' or targ_rep_mutation_types.name = 'Deletion')
             )
            where mgi_accession_id in  $gene_str
            and targ_rep_es_cells.report_to_public = true
         ];
    my $sth = $imits_dbh->prepare($sql);
    $sth->execute();

    my ( %escell_details, %project_ids );

    my $r = $sth->fetchrow_hashref;
    while ($r) {
        my %details = (
            name       => $r->{name},
            pipeline   => $ESCELL_PIPELINE_MAP{ $r->{pipeline_id} },
            cell_line  => $r->{parental_cell_line},
            project_id => $r->{ikmc_project_id}
        );
        push @{ $escell_details{ $r->{mgi_accession_id} } }, \%details;
        $project_ids{ $r->{ikmc_project_id} }++ if $r->{ikmc_project_id} =~ /^\d+$/;
        $r = $sth->fetchrow_hashref;
    }

    my @escell_project_ids = keys %project_ids;

    return ( \%escell_details, \@escell_project_ids );
}

sub get_reports_from_gene_info_list {
    my ( $self, $gene_info_list ) = @_;
    my ( $bash_report, $mgp_report, $mrc_report );
    for my $gene ( @{$gene_info_list} ) {
        if ( $gene->{consortium} eq 'BaSH' ) {
            $bash_report = process_gene_info_entry( $bash_report, $gene );
        }
        elsif ( $gene->{consortium} eq 'MGP' ) {
            $mgp_report = process_gene_info_entry( $mgp_report, $gene );
        }
        else {
            $mrc_report = process_gene_info_entry( $mrc_report, $gene );
        }
    }

    my ( $bash_list, $mgp_list, $mrc_list ) = create_lists_from_reports( $bash_report, $mgp_report, $mrc_report );

    return ( $bash_list, $mgp_list, $mrc_list );
}

sub process_gene_info_entry {
    my ( $report, $gene ) = @_;

    $report->{ $gene->{group} }{group} = $gene->{group};
    $report->{ $gene->{group} }{all}++;
    for my $status ( qw(
        mirKO_clones     clones_available       clones_elsewhere    no_clones
        on_hold          qc_complete            qc_failed           qc_started_0
        qc_started_1     qc_started_2           qc_started_3        qc_started_4
        qc_started_5     qc_started_more_than_5 all_JM8A1_N3_clones no_valid_clones
        )) {
        if ( defined $gene->{$status} ){
                $report->{ $gene->{group} }{$status}++;
                last;
            }
        }

        $report->{ $gene->{group} }{has_mi_attempt}++ if defined $gene->{has_mi_attempt};

    return $report;
}

__PACKAGE__->meta->make_immutable;
