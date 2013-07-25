package HTGT::Controller::Design::Design;

use strict;
use warnings;
use List::MoreUtils qw(uniq);
use base 'Catalyst::Controller';
use HTGT::Utils::RegeneronGeneStatus;
use HTGT::Utils::AllocateDesignsToPlate qw( allocate_designs_to_plate );

=head1 NAME

HTGT::Controller::Design::Design - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched HTGT::Controller::Design::Design in Design::Design.');
}

=head2 list

Method for listing designs based on query

=cut

sub list : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles("edit") ) {
        $c->forward('/welcome');
    }
    else {

        my $filter_info = {};
        my $designs;

        my $projects = $self->get_project_list($c);
        $c->stash->{projects} = $projects;

        my $plates = $self->get_plate_list($c);
        $c->stash->{plates} = $plates;

        my $project           = $c->request->param('project');
        my $design_type       = $c->request->param('design_type');
        my $art_intron_status = $c->request->param('art_intron_status');
        my $plate             = $c->request->param('plate_number');
        my $final_plate       = $c->request->param('final_plate');

        $filter_info->{project}           = $project;
        $filter_info->{design_type}       = $design_type;
        $filter_info->{art_intron_status} = $art_intron_status;
        $filter_info->{plate}             = $plate;
        $filter_info->{final_plate}       = $final_plate;
        $c->stash->{filter_info}          = $filter_info;

        my $design_rows
            = $self->get_design_rows( $c, $project, $design_type, $art_intron_status, $plate, $final_plate );

        # get the number of rows return
        my @design_rows    = @{$design_rows};
        my $number_of_rows = scalar(@design_rows);

        # set a flag to indicate whether it is from existing plate
        if ( $plate and $plate ne "Null" ) {
            $c->stash->{exist_plate} = 1;
        }

        $c->stash->{number_of_rows} = $number_of_rows;
        $c->stash->{designs}        = $design_rows;
        $c->stash->{template}       = 'design/list.tt2';
    }
}

=head2 get_design_rows 

Method for retrieving designs

=cut

=head2 get_design_rows 

Method for retrieving designs

=cut

sub get_design_rows : Private {
    my ( $self, $c, $program, $design_type, $art_intron_status, $plate, $final_plate ) = @_;

    my $regeneron_status = eval { HTGT::Utils::RegeneronGeneStatus->new( $c->model('IDCCMart') ); };
    if ($@) {
        $c->log->error("failed to create HTGT::Utils::RegeneronGeneStatus: $@");
    }

    my $sql;
    my $sql_a = "";
    my $sql_b = "";
    my $sql_c = "";
    my $sql_d = "";
    my $sql_e = "";
    my $sql_f = "";
    my $sql_g = "";

    $sql_a = qq [
            select distinct
            design.design_id,
            design.created_date,
            design.design_type,
            coalesce(design.phase,exon1.phase) as phase,
            mgi_gene.marker_symbol,
            design.final_plate,
            design.well_loc,
            mgi_gene.mgi_accession_id
            from
            design
            join project on project.design_id = design.design_id
            join mgi_gene on project.mgi_gene_id = mgi_gene.mgi_gene_id
            left outer join mig.gnm_exon exon1 on exon1.id = design.start_exon_id];
    

    $program ||= q{};
    my $params_used = 1;
    if ( $program eq "EUCOMM" ) {
        $sql_c = " where project.is_eucomm = 1";
    }
    elsif ( $program eq "KOMP" ) {
        $sql_c = " where project.is_komp_csd = 1";
    }
    elsif ( $program eq "NORCOMM" ) {
        $sql_c = " where project.is_norcomm = 1";
    }
    elsif ( $program eq "MGP" ) {
        $sql_c = " where project.is_mgp = 1";
    }
    elsif ( $program eq "EUTRACC" ) {
        $sql_c = " where project.is_eutracc = 1";
    }
    elsif ( $program eq "EUCOMM-Tools" ) {
        $sql_c = " where project.is_eucomm_tools = 1";
    }
    elsif ( $program eq "SWITCH" ) {
        $sql_c = " where project.is_switch = 1";
    }
    elsif ( $program eq "EUCOMM-Tools-Cre" ) {
        $sql_c = " where project.is_eucomm_tools_cre = 1";
    }
    elsif ( $program eq "TPP" ) {
        $sql_c = " where project.is_tpp = 1";
    }
    elsif ( $program eq "MGP-Bespoke" ) {
        $sql_c = " where project.is_mgp_bespoke = 1";
    }
    else {
        $params_used = 0;
    }

    $plate ||= q{};
    if ( $plate eq "Null" ) {

    #$sql_d = " and design.design_id not in (select design_id from design_instance) and project.project_status_id = 10";
        if ( $params_used == 1 ) {
            $sql_d = " and project.project_status_id = 10";
        }
        else {
            $sql_d = " where project.project_status_id = 10";
        }
        if ( $final_plate ne "" ) {
            $sql_e = " and design.final_plate = '$final_plate'";
        }
        $params_used = 1;
    }
    elsif ( $plate eq "All" ) {
        $sql_d = "";
    }
    else {
        $sql_b = " join design_instance on design_instance.design_id = design.design_id";
        if ( $params_used == 1 ) {
            $sql_d = " and design_instance.plate = '$plate'";
        }
        else {
            $sql_d = " where design_instance.plate = '$plate'";
        }
        $params_used = 1;
    }

    $design_type ||= q{};
    my $clause;
    if ( $params_used == 1 ) {
        $clause = " and";
    }
    else {
        $clause = " where";
    }

    if ( $design_type eq "Knockout first" ) {
        $sql_f       = $clause . " (design.design_type like 'KO%' OR design.design_type is null )";
        $params_used = 1;
    }
    elsif ( $design_type eq "Deletion" ) {
        $sql_f       = $clause . " design.design_type like 'Del%' ";
        $params_used = 1;
    }
    elsif ( $design_type eq "Insertion" ) {
        $sql_f       = $clause . " design.design_type like 'Ins%' ";
        $params_used = 1;
    }

    $art_intron_status ||= q{};
    if ( $params_used == 1 ) {
        $clause = " and";
    }
    else {
        $clause = " where";
    }
    my $art_intron_sql = qq[
      select distinct 
      design.design_id
      from design
      join design_user_comments 
      on design_user_comments.design_id = design.design_id
      join design_user_comment_categories
      on design_user_comment_categories.category_id = design_user_comments.category_id
      where design_user_comment_categories.category_name = 'Artificial intron design' ];

    if ( $art_intron_status eq "Yes" ) {
        $sql_g = $clause . ' design.design_id in( ' . $art_intron_sql . ')';
    }
    elsif ( $art_intron_status eq "No" ) {
        $sql_g = $clause . ' design.design_id not in( ' . $art_intron_sql . ')';
    }

    $sql = $sql_a . $sql_b . $sql_c . $sql_d . $sql_e . $sql_f . $sql_g . " order by well_loc";

    $c->log->debug( "SQL: " . $sql . "\n" );
    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
    $sth->execute();
    my @design_list;
    my $design;
    while ( my $result = $sth->fetchrow_hashref() ) {
        my $design_ref = {};

        $design_ref->{design_id}    = $result->{DESIGN_ID};
        $design_ref->{design_type}  = $result->{DESIGN_TYPE};
        $design_ref->{phase}        = $result->{PHASE};
        $design_ref->{final_plate}  = $result->{FINAL_PLATE};
        $design_ref->{well_loc}     = $result->{WELL_LOC};
        $design_ref->{created_date} = $result->{CREATED_DATE};
        $design_ref->{gene}         = $result->{MARKER_SYMBOL};

        #find regeneron status
        if ($regeneron_status) {
            $design_ref->{regeneron_status} = $regeneron_status->status_for( $result->{MGI_ACCESSION_ID} ) || '';
        }
        else {
            $design_ref->{regeneron_status} = 'ERROR: lookup failed!';
        }

        # find the program.
        my @projects = $c->model('HTGTDB::Project')->search( { design_id => $result->{DESIGN_ID} } );

        $design_ref->{project} = join '/', uniq map $_->sponsors, @projects;

        $design = $c->model('HTGTDB::Design')->find( { design_id => $result->{DESIGN_ID} } );

        my $start_exon = $design->start_exon;
        my $start_exon_name;
        if ($start_exon) {
            $start_exon_name = $design->start_exon->primary_name;
        }

        my $end_exon = $design->end_exon;
        my $end_exon_name;
        if ($end_exon) {
            $end_exon_name = $design->end_exon->primary_name;
        }
        if ( $start_exon_name eq $end_exon_name ) {
            $design_ref->{target} = $start_exon_name;
        }
        else {
            $design_ref->{target} = "${start_exon_name}-${end_exon_name}";
        }

        push @design_list, $design_ref;
    }
    return \@design_list;

}

=head2 get_project_list

a list of the projects/programs

=cut

sub get_project_list : Private {
    my ( $self, $c ) = @_;

    my @programs = (
        'EUCOMM', 'EUCOMM-Tools', 'KOMP',   'NORCOMM',
        'MGP',    'EUTRACC',      'SWITCH', 'EUCOMM-Tools-Cre',
        'TPP',    'MGP-Bespoke'
    );

    return \@programs;

}

=head2 get_plate_list

Method for returning a list of existing plates

=cut

sub get_plate_list : Private {
    my ( $self, $c ) = @_;

    my $sth = $c->model('HTGTDB')->schema->storage->dbh->prepare("select distinct plate from design_instance");
    $sth->execute();
    my @plates;
    while ( my @result = $sth->fetchrow_array ) {
        push @plates, $result[0];
    }

    @plates = sort { $a cmp $b } @plates;

    return \@plates;
}

=head2 _update_design

Method for updating the designs when user edit the table

=cut

sub _update_design : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{error_msg} = "You are not authorised to perform this function";
        $c->response->redirect( $c->uri_for('/design/design/list') );
    }
    else {

        if ( $c->req->params->{field} eq "final_plate" ) {

            # edit the final_plate field
            my $final_plate = $self->trim( $c->req->params->{value} );

            # check the value before update, if something wrong, give error message.
            if ( $self->check_plate( $c, $final_plate ) == 1 ) {

                # check if the the plate is the same as in the db, if so, no update needed
                my $design_id         = $c->req->params->{id};
                my $row               = $c->model('HTGTDB::Design')->find( { design_id => $c->req->params->{id} } );
                my $final_plate_in_db = $row->final_plate;
                $c->log->debug( "Final_plate_in_db is: " . $final_plate_in_db );
                if ( $final_plate eq $final_plate_in_db ) {
                    $c->res->body( $c->req->params->{value} );
                }
                else {
                    $c->stash->{error_msg} = "The plate has been used, please specify another plate!";
                    $c->res->body(
                        '<span style="color: red; font-weight: bold;">Please specify another final plate.</span>');
                }
            }
            elsif ( $final_plate eq "" ) {
                my $design_id = $c->req->params->{id};
                my $sql       = "update design set final_plate = null where design_id = $design_id ";
                my $sth       = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
                $sth->execute();

                $c->res->body(" ");
            }
            else {

                # update database
                $c->model('HTGTDB::Design')->find( { design_id => $c->req->params->{id} } )
                    ->update( { final_plate => $final_plate } );
                $c->res->body( $c->req->params->{value} );
            }
        }
        else {

            # edit well loc, trim the value and check before update db
            if ( $self->trim( $c->req->params->{value} ) eq "" ) {
                my $design_id = $c->req->params->{id};
                my $sql       = "update design set well_loc = null where design_id = $design_id ";
                my $sth       = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
                $sth->execute();

                $c->res->body(" ");
            }
            else {
                $c->model('HTGTDB::Design')->find( { design_id => $c->req->params->{id} } )
                    ->update( { well_loc => $self->trim( $c->req->params->{value} ) } );
                $c->res->body( $c->req->params->{value} );
            }
        }

    }
}

=head2 assign_plate

method for assigning 96 designs to plate

=cut

sub assign_plate : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{error_msg} = "You are not authorised to perform this function";
        $c->response->redirect( $c->uri_for('/design/design/list') );
    }
    else {

        # read the parameters, get a list of the designs
        my $filter_info = {};
        my $designs;

        my $projects = $self->get_project_list($c);
        $c->stash->{projects} = $projects;

        my $plates = $self->get_plate_list($c);
        $c->stash->{plates} = $plates;

        my $project           = $c->request->param('project');
        my $design_type       = $c->request->param('design_type');
        my $plate             = $c->request->param('plate_number');
        my $final_plate       = $c->request->param('final_plate');
        my $art_intron_status = $c->request->param('art_intron_status');

        $filter_info->{project}           = $project;
        $filter_info->{design_type}       = $design_type;
        $filter_info->{plate}             = $plate;
        $filter_info->{final_plate}       = $final_plate;
        $filter_info->{art_intron_status} = $art_intron_status;
        $c->stash->{filter_info}          = $filter_info;

        # check if existing plate has been specified
        if ( $plate ne "Null" ) {
            my $message
                = "You have specified the existing plate! To perform this operation, 'Existing plate' must be 'Null'.";

            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        # check if final_plate specify and if it is a number
        if ( $final_plate eq "" || !$self->is_a_number( $c, $final_plate ) ) {
            my $message = "Please specify an integer plate number!";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        # check if the final_plate is in existing plate list
        if ( $self->check_plate( $c, $final_plate ) == 1 ) {
            my $message = "This plate has been used. Please specify another final plate!";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        # check how many designs available
        my $available_designs
            = $self->get_design_rows( $c, $project, $design_type, $art_intron_status, 'Null', '' );

        my @designs = $c->model( 'HTGTDB' )->resultset( 'Design' )->search( { design_id => [ map $_->{design_id}, @{$available_designs} ] } );

        allocate_designs_to_plate( $final_plate, \@designs );

        $c->forward('/design/design/list');
    }
}

=head2 assign_well

Method for assigning the well loc to the designs

=cut

sub assign_well : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{error_msg} = "You are not authorised to perform this function";
        $c->response->redirect( $c->uri_for('/design/design/list') );
    }
    else {

        my $filter_info = {};
        my $designs;

        my $projects = $self->get_project_list($c);
        $c->stash->{projects} = $projects;

        my $plates = $self->get_plate_list($c);
        $c->stash->{plates} = $plates;

        my $project = $c->request->param('project');

        #my $fulfills_request = $c->request->param('fulfills_request');
        my $plate       = $c->request->param('plate_number');
        my $final_plate = $c->request->param('final_plate');

        $filter_info->{project} = $project;

        #$filter_info->{fulfills_request} = $fulfills_request;
        $filter_info->{plate}       = $plate;
        $filter_info->{final_plate} = $final_plate;
        $c->stash->{filter_info}    = $filter_info;

        # check if existing plate has been specified
        if ( $plate ne "Null" ) {
            my $message
                = "You have specified the existing plate! To perform this operation, 'Existing plate' must be 'Null'.";

            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        # check if final_plate specify
        if ( $final_plate eq "" ) {
            my $message = "Please specify the final plate!";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        # check if the final_plate is in existing plate list
        if ( $self->check_plate( $c, $final_plate ) == 1 ) {
            my $message = "This plate has been used. Please specify another final plate!";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }

        my @designs = $c->model( 'HTGTDB' )->resultset( 'Design' )->search( { final_plate => $final_plate } );

        if ( @designs != 96 ) {
            my $message = "You have " . @designs . " designs for plate $final_plate! Should be 96 designs.";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }   

        allocate_designs_to_plate( $final_plate, \@designs );
        $c->forward('/design/design/list');
    }
}

=head2 make_plate

Method for making plate

=cut

sub make_plate : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles("edit") ) {
        $c->flash->{error_msg} = "You are not authorised to perform this function";
        $c->response->redirect( $c->uri_for('/design/design/list') );
    }
    else {
        my $plate_name = $c->model('HTGTDB')->storage->txn_do( sub { $self->_do_make_plate($c) } );
        if ($plate_name) {
            $c->flash->{status_msg} = "Created plate $plate_name";
            return $c->response->redirect(
                $c->uri_for( '/plate/view', { plate_name => $plate_name, plate_type => 'DESIGN' } ) );

        }
        return;
    }
}

sub _do_make_plate {
    my ( $self, $c ) = @_;

    my $plate       = $c->request->param('plate_number');
    my $final_plate = $c->request->param('final_plate');

    #check if existing plate has been specified
    if ( $plate and $plate ne "Null" ) {
        my $message
            = "You have specified the existing plate! To perform this operation, 'Existing plate' must be 'Null'.";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    # check if final_plate specify
    if ( $final_plate eq "" ) {
        my $message = "Please specify the final plate!";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    # check if the final_plate is in existing plate list
    if ( $self->check_plate( $c, $final_plate ) == 1 ) {
        my $message = "This plate has been used. Please specify another final plate!";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    ## check if 96 plates
    #my $assign_plates = $self->check_number_of_plates( $c, $final_plate );
    #if ( $assign_plates != 96 ) {
    #    my $message = "You have $assign_plates design for plate $final_plate! Should be 96 designs.";
    #    $c->stash->{error_msg} = $message;
    #    $c->forward('/design/design/list');
    #    return;
    #}

    # get the designs
    my $sql = qq [
                select distinct
                design.design_id,
                design.FINAL_PLATE,
                design.WELL_LOC,
                design.DESIGN_TYPE,
                design.DESIGN_NAME,
                (select design_user_comment_categories.category_name
                from design_user_comment_categories
                join design_user_comments on design_user_comment_categories.category_id = design_user_comments.category_id
                where design_user_comment_categories.category_name = 'Artificial intron design'
                and design_user_comments.design_id = design.design_id) as art_intron
                from
                design
                where
                design.FINAL_PLATE = '$final_plate'
                and design.well_loc is not null
              ];

    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
    $sth->execute();

    my @design_list;
    my %art_intron_or_not;
    while ( my $result = $sth->fetchrow_hashref() ) {
        if ( $result->{ART_INTRON} eq 'Artificial intron design' ) {
            $art_intron_or_not{'Yes'}++;
        }
        else {
            $art_intron_or_not{'No'}++;
        }
        my $design_ref = {};
        $design_ref->{design_id}   = $result->{DESIGN_ID};
        $design_ref->{final_plate} = $result->{FINAL_PLATE};
        $design_ref->{well_loc}    = $result->{WELL_LOC};
        $design_ref->{design_type} = $result->{DESIGN_TYPE};
        $design_ref->{design_name} = $result->{DESIGN_NAME};
        push @design_list, $design_ref;
    }
    my $designs_list_ref = \@design_list;

    if ( scalar( keys %art_intron_or_not ) > 1 ) {
        my $message = "Plate contains both artificial intron and standard designs";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    my @feature_type_ids = ( 7,    8,    9,    12,   11,   10 );
    my @data_type        = ( "G5", "G3", "U5", "D3", "D5", "U3" );

    # check each design feature available
    $c->log->debug("Checking features...");

    # check if each design has all the features
    foreach my $design (@design_list) {

        my $design_id = $design->{design_id};
        if ( $design->{design_type} eq 'KO' || $design->{design_type} eq '' ) {
            for ( my $i = 0; $i < 6; $i++ ) {
                my $get_feature_sql = qq [
                        select count(feature_data_id) 
                        from feature, feature_data
                        where feature.feature_id = feature_data.feature_id
                        and feature_data.feature_data_type_id = 3
                        and feature_type_id = $feature_type_ids[$i]
                        and feature.design_id = $design_id
                       ];

                my $sth_feature = $c->model('HTGTDB')->storage()->dbh()->prepare($get_feature_sql);
                $sth_feature->execute();

                my @feature           = $sth_feature->fetchrow_array();
                my $number_of_feature = $feature[0];

                if ( $number_of_feature != 1 ) {
                    $c->log->debug("No $data_type[$i] feature available. ");
                    my $message = "There is no $data_type[$i] for design $design_id. !";
                    $c->stash->{error_msg} = $message;
                    $c->forward('/design/design/list');
                    return;
                }
            }
        }
        elsif ( $design->{design_type} eq 'Del_Block' || $design->{design_type} eq 'Ins_Block' ) {
            for ( my $i = 0; $i < 4; $i++ ) {
                my $get_feature_sql = qq [
                        select count(feature_data_id) 
                        from feature, feature_data
                        where feature.feature_id = feature_data.feature_id
                        and feature_data.feature_data_type_id = 3
                        and feature_type_id = $feature_type_ids[$i]
                        and feature.design_id = $design_id
                       ];

                my $sth_feature = $c->model('HTGTDB')->storage()->dbh()->prepare($get_feature_sql);
                $sth_feature->execute();

                my @feature           = $sth_feature->fetchrow_array();
                my $number_of_feature = $feature[0];

                if ( $number_of_feature != 1 ) {
                    $c->log->debug("No $data_type[$i] feature available. ");
                    my $message = "There is no $data_type[$i] for design $design_id. !";
                    $c->stash->{error_msg} = $message;
                    $c->forward('/design/design/list');
                    return;
                }
            }
        }
        elsif ( $design->{design_type} eq 'Del_Location' || $design->{design_type} eq 'Ins_Location' ) {
            for ( my $i = 0; $i < 2; $i++ ) {
                my $get_feature_sql = qq [
                            select count(feature_data_id) 
                            from feature, feature_data
                            where feature.feature_id = feature_data.feature_id
                            and feature_data.feature_data_type_id = 3
                            and feature_type_id = $feature_type_ids[$i]
                            and feature.design_id = $design_id
                           ];

                my $sth_feature = $c->model('HTGTDB')->storage()->dbh()->prepare($get_feature_sql);
                $sth_feature->execute();

                my @feature           = $sth_feature->fetchrow_array();
                my $number_of_feature = $feature[0];

                if ( $number_of_feature != 1 ) {
                    $c->log->debug("No $data_type[$i] feature available. ");
                    my $message = "There is no $data_type[$i] for design $design_id. !";
                    $c->stash->{error_msg} = $message;
                    $c->forward('/design/design/list');
                    return;
                }

            }

        }
    }

    $c->log->debug("Checking features OK.");

    # check if design has design name, well & plate
    $c->log->debug("Checking design name, well, & plate...");
    foreach my $design (@design_list) {
        unless ( $design->{design_name} ) {
            $c->model( 'HTGTDB::Design' )->find( { design_id => $design->{design_id} } )->find_or_create_name;
        }        
        if (   $design->{well_loc} eq ""
            || $design->{final_plate} eq "" )
        {

            my $message = "Design $design->{design_id} has an invalid plate or well location";
            $c->stash->{error_msg} = $message;
            $c->forward('/design/design/list');
            return;
        }
    }

    $c->log->debug("Checking design name , well & plate OK.");
    $c->log->debug("Designs has been validated.");

    # check if the plate exist or not
    $c->log->debug("Checking if the plate exist ...");

    $plate = $c->model('HTGTDB::Plate')->find(
        {   name => $final_plate,
            type => 'DESIGN'
        }
    );

    if ($plate) {
        $c->log->debug( "cannot create the plate " . $plate . ", the plate already exists." );
        my $message = "Cannot create the plate. The plate " . $final_plate . " already exists";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    $c->log->debug("checking ok, start to make design instance and plate.");

    my @design_instances;

    foreach my $design (@design_list) {
        my $design_id = $design->{design_id};

        my $design_instance = $c->model('HTGTDB::DesignInstance')->create(
            {   design_id => $design->{design_id},
                plate     => $design->{final_plate},
                well      => $design->{well_loc}
            }
        );

        # get the gene name from mgi_gene table

        my $gene = $c->model('HTGTDB::Project')->search( { design_id => $design_id } )->first->mgi_gene->marker_symbol;

        # store gene name to design_instance
        $design_instance->{gene} = $gene;

        # get the design name
        $design_instance->{design_name} = $design->{design_name};

        # store design_instance & send it to template later
        push @design_instances, $design_instance;

        # get the bac_clone_id from design_bac table where allocate_to_instance = 1

        my $bac_ids = $self->get_allocated_bac( $c, $design_instance->design_id );
        my @bac_ids = @{$bac_ids};

        # assign bac_plate
        my $number_of_bac = scalar(@bac_ids);

        my $plate = $design->{final_plate};

        my @plateLabel = ( "a", "b", "c", "d" );
        my $counter = 0;
        my $bac_plate;

        foreach my $bac_id (@bac_ids) {

            # assign the bac plate
            $bac_plate = $plate . $plateLabel[$counter];
            $counter   = $counter + 1;

            # insert into design_instance_bac table
            my $design_instance_bac = $c->model('HTGTDB::DesignInstanceBAC')->create(
                {   design_instance_id => $design_instance->design_instance_id,
                    bac_clone_id       => $bac_id,
                    bac_plate          => $bac_plate
                }
            );
        }
    }

    # create a plate with the final plate number
    $plate = $c->model('HTGTDB::Plate')->create(
        {   name         => $final_plate,
            type         => 'DESIGN',
            created_user => $c->user->id
        }
    );
    my $plate_id = $plate->plate_id;

# get the well names, for each well name, create the well with the well name, then fill in the design instance id in the well , that is done.
    my @wells = HTGTDB::Plate::get_default_well_names('DESIGN');
    foreach my $well_name (@wells) {
        my $well = $c->model('HTGTDB::Well')->find_or_create(
            {   plate_id  => $plate_id,
                well_name => $well_name,
                edit_user => $c->user->id
            },
            { key => 'plate_id_well_name' }
        );

        # work out what the design_instance should be ...
        my $design_instance = $c->model('HTGTDB::DesignInstance')->find(
            {   plate => $plate->name,
                well  => $well_name
            },
            { key => 'design_instance_plate_well' }
        );

        # check that we don't have a mismatch...
        if ($design_instance) {
            if ( $well->design_instance_id and $well->design_instance_id != $design_instance->design_instance_id ) {
                if ( $well->design_instance_id =~ /^$/ ) {

                    # Ignore this - there is no di in the first place...
                }
                else {
                    my $message
                        = "Failed in making plate: the well "
                        . $well->well_name
                        . " has DI :"
                        . $well->design_instance_id
                        . ", but should be "
                        . $design_instance->design_instance_id
                        . "design instance id mismatch well design instance id. The plate "
                        . $plate->name
                        . " may already exist.";
                    $c->stash->{error_msg} = $message;
                    $c->forward('/design/design/list');
                    return;
                }
            }
            $well->update( { design_instance_id => $design_instance->design_instance_id } );

            if ( $design_instance->design->is_recovery_design ) {
                $well->well_data_rs->create(
                    {   data_type  => 'redesign_recovery',
                        data_value => 'yes',
                        edit_user  => $c->user->id,
                        edit_date  => \'current_timestamp'
                    }
                );
            }

# at this point, we know what design instance to stamp in the well, so stamp the desgin instance in the project at the same time
            my $project = $self->stamp_project_for_design_instance( $c, $design_instance );
            ( my $sponsor = $project->sponsor ) =~ s/:MGP//;

            my $sponsor_data = $well->well_data_rs->find( { data_type => 'sponsor' } );
            if ($sponsor_data) {
                if ( $sponsor_data->data_value ne $sponsor ) {
                    $self->log->warn( 'Existing sponsor ' . $sponsor_data->data_value . ', expected ' . $sponsor );
                }
            }
            else {
                $well->well_data_rs->create(
                    {   data_type  => 'sponsor',
                        data_value => $sponsor,
                        edit_user  => $c->user->id,
                        edit_date  => \'current_timestamp'
                    }
                );
            }
        }
        else {

            # log that we are creating a well and leaving it blank
            $c->log->debug("Well ".$well->well_name." has no matching design instance - leaving blank");
        }
    }

    # update design status table,

    foreach my $design (@design_list) {

        my $design_id      = $design->{design_id};
        my $get_status_sql = qq [
                select design_status_id 
                from design_status 
                where design_id = $design_id 
                and is_current = 1
             ];

        my $get_status_sth = $c->model('HTGTDB')->storage()->dbh()->prepare($get_status_sql);
        $get_status_sth->execute();

        my @status_id = $get_status_sth->fetchrow_array();
        my $status_id = $status_id[0];

        # if status is not 'ordered', update the record which is 'is_current' to 0,
        # insert a record with status 'ordered'.
        if ( $status_id != 10 ) {
            if ( $status_id != "" ) {
                my $update_sql = qq [
                    update design_status 
                    set is_current = '0' 
                    where design_id = $design_id 
                    and design_status_id = $status_id
                   ];

                my $update_sth = $c->model('HTGTDB')->storage()->dbh()->prepare($update_sql);
                $update_sth->execute();

                my $insert_sql = qq [
                        insert into design_status(design_id, design_status_id, is_current) values($design_id,10,'1') 
                          ];

                my $insert_sth = $c->model('HTGTDB')->storage()->dbh()->prepare($insert_sql);
                $insert_sth->execute();
            }
            else {
                my $insert_sql = qq [
                     insert into design_status(design_id, design_status_id, is_current) values($design_id,10,'1') 
                    ];

                my $insert_sth = $c->model('HTGTDB')->storage()->dbh()->prepare($insert_sql);
                $insert_sth->execute();
            }
        }
    }

    return $final_plate;
}

sub stamp_project_for_design_instance {

    my ( $self, $c, $design_instance ) = @_;

    my $design_id = $design_instance->design_id;

    #########

    # update project status & design_instance_id

    ##########

    my @projects = $c->model('HTGTDB::Project')->search( { design_id => $design_id } );
    $c->log->debug( "size of the projects: " . scalar(@projects) . "\n" );
    my $project;

    # filter out the project which already has design instance
    foreach my $possible_project (@projects) {
        if ( $possible_project->design_instance_id ) {
            $c->log->debug("this project has di already. \n");

            #next;
        }
        else {
            $project = $possible_project;
            $c->log->debug("find a project to stamp. \n");
            last;
        }
    }

    if ( !$project ) {
        die "cant find project matching design $design_id that hasn't already been plated";
    }

    my $design_instance_id = $design_instance->design_instance_id;

    $project->update(
        {   project_status_id  => 11,
            design_instance_id => $design_instance_id
        }
    );

    return $project;
}

=head2 print_ordersheet 

Method to print out the oligos & bac order sheet

=cut 

sub print_ordersheet : Local {
    my ( $self, $c ) = @_;

    my $plate = $c->request->param('plate_number');

    # check the value of plate
    if ( $plate eq "Null" || $plate eq "All" ) {
        my $message = "Please specify the existing plate.";
        $c->stash->{error_msg} = $message;
        $c->forward('/design/design/list');
        return;
    }

    my $csv;
    $csv = $self->print_oligo_order( $c, $plate, $csv );

    # get distinct bac_plate
    my $bac_plates = $self->get_distinct_bac_plate( $c, $plate );
    my @bac_plates = @$bac_plates;

    foreach my $bac_plate (@bac_plates) {
        $csv = $self->generate_bacs_order_1( $c, $plate, $bac_plate, $csv );
    }

    foreach my $bac_plate (@bac_plates) {
        $csv = $self->generate_bacs_order_2( $c, $plate, $bac_plate, $csv );
    }

    $c->res->content_type('application/ms-excel');
    my $filename = "order_sheet.csv";
    $c->res->header( 'Content-Disposition', qq[attachment; filename="$filename"] );
    $c->res->body($csv);
}

=head2 print_oligo_order

Method for printing oligo order sheet. Given the plate number, this method find the sequences and print out oligo order sheet.

=cut

sub print_oligo_order : Private {
    my ( $self, $c, $plate, $file ) = @_;

    my $plate_object
        = $c->model('HTGTDB::Plate')->find( { name => $plate, type => 'DESIGN' }, { prefetch => 'plate_data' } );
    die " cant find htgt plate $plate\n " unless $plate_object;

    my @wells = $c->model( 'HTGTDB' )->resultset( 'Well' )->search(
        {
            'plate.name' => $plate,
        },
        {
            join     => 'plate',
            prefetch => { design_instance => 'design' },
            order_by => { -asc => 'me.well_name' }
        }
    );

    # The conditional is in case there are empty wells - the undef gets skipped in the next iterate
    my @designs = map { $_->design_instance ? $_->design_instance->design : undef } @wells;

    for my $feature_type (  "G5", "G3", "U5", "U3", "D5", "D3" ) {
        my $feature_type_obj = $c->model( 'HTGTDB' )->resultset( 'FeatureType' )->find( { description => $feature_type } )
            or die "Failed to retrieve $feature_type from FeatureTypeDict";

        my ( @sequences, @wells, @design_names, @design_phases );   

        for my $design ( @designs ) {
            #If there were empty wells then the array will have an undef here
            next unless $design;
            my $sequence = $self->get_sequence( $c, $design->design_id, $feature_type_obj->feature_type_id );
            push @sequences, $self->get_order_oligo_seq( $c, $design, $feature_type, $sequence, $design->is_artificial_intron );
            push @wells, $design->well_loc;
            push @design_names, $design->design_name;
            push @design_phases, $design->phase;
        }

        $file = $self->generate_oligo_ordersheet( $c, $file, $plate, $feature_type, 
                                                  \@sequences, \@wells,
                                                  \@design_names, \@design_phases );
    }
    
    return $file;
}

=head2 get_sequence 

Method to retrieve sequence for a given design_id

=cut

sub get_sequence : Private {
    my ( $self, $c, $design_id, $feature_type ) = @_;

    my $sql = qq [
      select feature.feature_type_id, feature_data.data_item
      from feature, feature_data
      where feature.design_id = $design_id
      and feature.feature_type_id = $feature_type
      and feature.feature_id = feature_data.feature_id
      and feature_data.feature_data_type_id = 1
      and feature.feature_id in 
      (
       select feature.feature_id from feature, feature_data
       where feature.design_id = $design_id
       and feature.feature_id = feature_data.feature_id
       and feature_data.feature_data_type_id = 3
      ) 
    ];

    my $sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($sql);

    $sth->execute();

    my $sequence;

    while ( my $result = $sth->fetchrow_hashref() ) {
        $sequence = $result->{DATA_ITEM};
    }

    return $sequence;
}

=head2 get_order_oligo_sequence 

Method to manipulate the given sequence and return the order oligo sequence  

=cut

sub get_order_oligo_seq : Private {

    my ( $self, $c, $design, $data_type, $sequence, $artificial_intron ) = @_;

    # define appends for different type of designs
    my %appends_for_KO                   = %HTGTDB::Design::appends_for_KO;
    my %appends_for_KO_artificial_intron = %HTGTDB::Design::appends_for_KO_artificial_intron;
    my %appends_for_Block_specified      = %HTGTDB::Design::appends_for_Block_specified;
    my %appends_for_location_specified   = %HTGTDB::Design::appends_for_location_specified;

    my $strand = $design->start_exon->locus->chr_strand;
    my $ResultSeq;

    if ( 
	    $design->design_type eq 'Del_Block' || $design->design_type eq 'Ins_Block'  
	    || $design->design_type eq 'Ins_Location' || $design->design_type eq 'Del_Location' 
    ) {

        # The edges of the cassette are formed by U5 and D3, so they receive the cassette appends seqs
        if ( $strand == 1 ) {
            if ( $data_type eq "G5" || $data_type eq "D3" ) {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                $ResultSeq = $RevSeq . $appends_for_Block_specified{$data_type};
            }
            elsif ( $data_type eq "U5" || $data_type eq "G3" ) {
                $ResultSeq = $sequence . $appends_for_Block_specified{$data_type};
            }
        }
        else {
            if ( $data_type eq "G5" || $data_type eq "D3" ) {
                $ResultSeq = $sequence . $appends_for_Block_specified{$data_type};
            }
            elsif ( $data_type eq "U5" || $data_type eq "G3" ) {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                $ResultSeq = $RevSeq . $appends_for_Block_specified{$data_type};
            }
        }
    }
    elsif ( $design->design_type eq 'KO' || $design->design_type eq "" ) {
        if ( $strand == 1 ) {
            if (   $data_type eq "G5"
                || $data_type eq "D3"
                || $data_type eq "U3" )
            {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                $ResultSeq = $RevSeq . $appends_for_KO{$data_type};
            }
            else {
                $ResultSeq = $sequence . $appends_for_KO{$data_type};
            }
        }
        else {
            if (   $data_type eq "G5"
                || $data_type eq "D3"
                || $data_type eq "U3" )
            {
                $ResultSeq = $sequence . $appends_for_KO{$data_type};
            }
            else {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                $ResultSeq = $RevSeq . $appends_for_KO{$data_type};
            }
        }
    }
    elsif ( $design->design_type =~ /Location/ ) {
        if ( $strand == 1 ) {
            if ( $data_type eq "G5" || $data_type eq "D3" || $data_type eq "U3" ) {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                if ( !$artificial_intron ) {
                    $ResultSeq = $RevSeq . $appends_for_location_specified{$data_type};
                }
                else {
                    $ResultSeq = $RevSeq . $appends_for_KO_artificial_intron{$data_type};
                }
            }
            else {
                if ( !$artificial_intron ) {
                    $ResultSeq = $sequence . $appends_for_location_specified{$data_type};
                }
                else {
                    $c->log->debug("Using artifical intron appends");
                    $ResultSeq = $sequence . $appends_for_KO_artificial_intron{$data_type};
                }
            }
        }
        else {
            if (   $data_type eq "G5"
                || $data_type eq "D3"
                || $data_type eq "U3" )
            {
                if ( !$artificial_intron ) {
                    $ResultSeq = $sequence . $appends_for_location_specified{$data_type};
                }
                else {
                    $ResultSeq = $sequence . $appends_for_KO_artificial_intron{$data_type};
                }
            }
            else {
                my $RevSeq = $self->reverse_complement( $c, $sequence );
                if ( !$artificial_intron ) {
                    $ResultSeq = $RevSeq . $appends_for_location_specified{$data_type};
                }
                else {
                    $ResultSeq = $RevSeq . $appends_for_KO_artificial_intron{$data_type};
                }
            }
        }
    }
    else {
        die "design type " . $design->design_type . " not expected\n";
    }

    return $ResultSeq;

}

=head2

Method to reverse complement

=cut

sub reverse_complement : Private {

    my ( $self, $c, $seq ) = @_;
    my $retSeq;

    my $seq_len = length $seq;
    for ( my $i = $seq_len; $i > 0; $i-- ) {
        my $retChar = $self->get_complement( $c, substr( $seq, $i - 1, 1 ) );
        $retSeq = $retSeq . $retChar;
    }
    return $retSeq;
}

=head2 get_complement 

Method to get complement

=cut

sub get_complement : Private {
    my ( $self, $c, $char ) = @_;

    my $retVal;

    if ( $char eq "T" ) {
        $retVal = "A";
    }

    if ( $char eq "A" ) {
        $retVal = "T";
    }

    if ( $char eq "G" ) {
        $retVal = "C";
    }

    if ( $char eq "C" ) {
        $retVal = "G";
    }
    return $retVal;
}

=head2 get_distinct_bac_plate

Method to get distinct bac plate for a given plate

=cut

sub get_distinct_bac_plate : Private {
    my ( $self, $c, $plate ) = @_;

    my $sql = qq [
     select distinct(bac_plate) 
     from design_instance, design_instance_bac
     where design_instance.plate = '$plate'
     and design_instance_bac.design_instance_id = design_instance.design_instance_id
   ];

    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
    $sth->execute();

    my @bac_plates;
    while ( my @row = $sth->fetchrow_array ) {
        push @bac_plates, $row[0];
    }

    return \@bac_plates;
}

=head2 generate_oligo_ordersheet

Method to generate oligo order sheet

=cut

sub generate_oligo_ordersheet : Private {

    my ( $self, $c, $file, $plate, $data, $seq_ref, $wells_ref, $designs_ref, $design_phases_ref ) = @_;

    my @oligos           = @$seq_ref;
    my @wells            = @$wells_ref;
    my @designs          = @$designs_ref;
    my @design_phases    = @$design_phases_ref;
    
    my $number_of_design = scalar(@designs);
    my $number_of_oligos = scalar(@oligos);
    $c->log->debug( " number of design: " . $number_of_design );

    return if $number_of_oligos == 0;

    $file .= "Temp_plate_" . $plate . "_" . $data . "\n\n";

    for ( my $i = 0; $i < $number_of_design; $i++ ) {
        my $colA = "plate_" . $plate . "_" . $data;
        my $colB = substr( $wells[$i], 0, 1 );
        my $colC = substr( $wells[$i], 1, 2 );
        my $colD = $wells[$i] . "_" . $designs[$i] . "_" . $data;
        my $colE = $design_phases[$i];
        my $colF = $oligos[$i];

        $file .= "$colA,$colB,$colC,$colD,$colE,$colF\n";
    }

    $file .= "\n";
    return $file;
}

=head2 generate_bacs_order_2

Method to print bac ordersheet 2

=cut

sub generate_bacs_order_2 : Private {
    my ( $self, $c, $plate, $bac_plate, $file ) = @_;

    my $bacs = $self->get_bacs_2( $c, $plate, $bac_plate );
    my @bacs = @$bacs;

    $file .= $bac_plate . "_BAC2\n\n";

    foreach my $bac (@bacs) {

        $file .= $bac_plate . "_BAC2," . $bac . "\n";
    }
    $file .= "\n\n";
    return $file;
}

=head2 generate_bacs_order_1

Method to print bac ordersheet 1

=cut

sub generate_bacs_order_1 : Private {
    my ( $self, $c, $plate, $bac_plate, $file ) = @_;

    my $bacs_ref = $self->get_bacs_1( $c, $plate, $bac_plate );
    my %bacs = %$bacs_ref;

    $file .= $bac_plate . "_BAC1\n\n";
    $file .= " ,01,02,03,04,05,06,07,08,09,10,11,12\n";
    $file
        .= "A" . ","
        . $bacs{"A01"} . ","
        . $bacs{"A02"} . ","
        . $bacs{"A03"} . ","
        . $bacs{"A04"} . ","
        . $bacs{"A05"} . ","
        . $bacs{"A06"} . ","
        . $bacs{"A07"} . ","
        . $bacs{"A08"} . ","
        . $bacs{"A09"} . ","
        . $bacs{"A10"} . ","
        . $bacs{"A11"} . ","
        . $bacs{"A12"} . "\n";
    $file
        .= "B" . ","
        . $bacs{"B01"} . ","
        . $bacs{"B02"} . ","
        . $bacs{"B03"} . ","
        . $bacs{"B04"} . ","
        . $bacs{"B05"} . ","
        . $bacs{"B06"} . ","
        . $bacs{"B07"} . ","
        . $bacs{"B08"} . ","
        . $bacs{"B09"} . ","
        . $bacs{"B10"} . ","
        . $bacs{"B11"} . ","
        . $bacs{"B12"} . "\n";
    $file
        .= "C" . ","
        . $bacs{"C01"} . ","
        . $bacs{"C02"} . ","
        . $bacs{"C03"} . ","
        . $bacs{"C04"} . ","
        . $bacs{"C05"} . ","
        . $bacs{"C06"} . ","
        . $bacs{"C07"} . ","
        . $bacs{"C08"} . ","
        . $bacs{"C09"} . ","
        . $bacs{"C10"} . ","
        . $bacs{"C11"} . ","
        . $bacs{"C12"} . "\n";
    $file
        .= "D" . ","
        . $bacs{"D01"} . ","
        . $bacs{"D02"} . ","
        . $bacs{"D03"} . ","
        . $bacs{"D04"} . ","
        . $bacs{"D05"} . ","
        . $bacs{"D06"} . ","
        . $bacs{"D07"} . ","
        . $bacs{"D08"} . ","
        . $bacs{"D09"} . ","
        . $bacs{"D10"} . ","
        . $bacs{"D11"} . ","
        . $bacs{"D12"} . "\n";
    $file
        .= "E" . ","
        . $bacs{"E01"} . ","
        . $bacs{"E02"} . ","
        . $bacs{"E03"} . ","
        . $bacs{"E04"} . ","
        . $bacs{"E05"} . ","
        . $bacs{"E06"} . ","
        . $bacs{"E07"} . ","
        . $bacs{"E08"} . ","
        . $bacs{"E09"} . ","
        . $bacs{"E10"} . ","
        . $bacs{"E11"} . ","
        . $bacs{"E12"} . "\n";
    $file
        .= "F" . ","
        . $bacs{"F01"} . ","
        . $bacs{"F02"} . ","
        . $bacs{"F03"} . ","
        . $bacs{"F04"} . ","
        . $bacs{"F05"} . ","
        . $bacs{"F06"} . ","
        . $bacs{"F07"} . ","
        . $bacs{"F08"} . ","
        . $bacs{"F09"} . ","
        . $bacs{"F10"} . ","
        . $bacs{"F11"} . ","
        . $bacs{"F12"} . "\n";
    $file
        .= "G" . ","
        . $bacs{"G01"} . ","
        . $bacs{"G02"} . ","
        . $bacs{"G03"} . ","
        . $bacs{"G04"} . ","
        . $bacs{"G05"} . ","
        . $bacs{"G06"} . ","
        . $bacs{"G07"} . ","
        . $bacs{"G08"} . ","
        . $bacs{"G09"} . ","
        . $bacs{"G10"} . ","
        . $bacs{"G11"} . ","
        . $bacs{"G12"} . "\n";
    $file
        .= "H" . ","
        . $bacs{"H01"} . ","
        . $bacs{"H02"} . ","
        . $bacs{"H03"} . ","
        . $bacs{"H04"} . ","
        . $bacs{"H05"} . ","
        . $bacs{"H06"} . ","
        . $bacs{"H07"} . ","
        . $bacs{"H08"} . ","
        . $bacs{"H09"} . ","
        . $bacs{"H10"} . ","
        . $bacs{"H11"} . ","
        . $bacs{"H12"}
        . "\n\n\n";

    return $file;
}

=head2 get_bacs_1

Method to get bacs of a plate for printing bac1 ordersheet.

=cut

sub get_bacs_1 : Private {

    my ( $self, $c, $plate, $bacPlate ) = @_;
    my $sql;

    if ( $bacPlate ne "" ) {
        $sql = qq [
        select well, remote_clone_id
        from   design_instance, design_instance_bac, bac
        where design_instance.plate = '$plate'  
	and design_instance_bac.bac_plate = '$bacPlate'
        and    design_instance_bac.design_instance_id = design_instance.design_instance_id
        and    design_instance_bac.bac_clone_id = bac.bac_clone_id
       ];
    }
    else {
        $sql = qq [
         select well, remote_clone_id
	 from   design_instance, design_instance_bac, bac
         where design_instance.plate = '$plate'  
	 and design_instance_bac.bac_plate is null
         and    design_instance_bac.design_instance_id = design_instance.design_instance_id        
	 and    design_instance_bac.bac_clone_id = bac.bac_clone_id
       ];
    }
    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);

    $sth->execute();

    my %map;

    while ( my $result = $sth->fetchrow_hashref() ) {
        my $well = $result->{WELL};
        my $bac  = $result->{REMOTE_CLONE_ID};
        $map{$well} = $bac;
    }
    return \%map;
}

=head2 get_bacs_2

Method to get the bac of a plate for printing bac2 ordersheet.

=cut

sub get_bacs_2 : Private {
    my ( $self, $c, $plate, $bacPlate ) = @_;

    my $sql;

    if ( $bacPlate ne "" ) {
        $sql = qq [
         select distinct(remote_clone_id) 
         from   design_instance, design_instance_bac, bac
         where design_instance.plate = '$plate'  
	 and design_instance_bac.bac_plate = '$bacPlate'
         and    design_instance_bac.design_instance_id = design_instance.design_instance_id
         and    design_instance_bac.bac_clone_id = bac.bac_clone_id
      ];
    }
    else {
        $sql = qq [
         select distinct(remote_clone_id)
	 from   design_instance, design_instance_bac, bac
	 where design_instance.plate = '$plate'  
	 and design_instance_bac.bac_plate is null
	 and    design_instance_bac.design_instance_id = design_instance.design_instance_id
	 and    design_instance_bac.bac_clone_id = bac.bac_clone_id
	];
    }

    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);

    $sth->execute();

    my @bacs;

    while ( my $result = $sth->fetchrow_hashref() ) {
        push @bacs, $result->{REMOTE_CLONE_ID};
    }
    return \@bacs;

}

=head2 check_plate

Method for checking if the assigned final plate has already been used

=cut

sub check_plate : Private {
    my ( $self, $c, $final_plate ) = @_;

    my $existing_plates = $self->get_plate_list($c);

    foreach my $plate ( @{$existing_plates} ) {
        if ( $final_plate eq $plate ) {
            return 1;
        }
    }
    return 0;
}

=head2 check_number_of_plates

Method for checking how many designs for a given final plate

=cut

sub check_number_of_plates : Private {
    my ( $self, $c, $final_plate ) = @_;
    my $sql = "select count(final_plate) from design where final_plate = '$final_plate'";
    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
    $sth->execute();

    my @number_of_plate = $sth->fetchrow_array();
    my $number_of_plate = $number_of_plate[0];
    return $number_of_plate;
}

=head2 get_allocated_bac 

Method for getting bac which has been allocated to design instance 

=cut

sub get_allocated_bac : Private {
    my ( $self, $c, $design_id ) = @_;

    my $sql = "select distinct bac_clone_id from design_bac where design_id = $design_id and allocate_to_instance = 1";

    my $sth = $c->model('HTGTDB')->storage()->dbh()->prepare($sql);
    $sth->execute();

    my @bac_ids;

    while ( my @bacs = $sth->fetchrow_array ) {
        push @bac_ids, $bacs[0];
    }

    return \@bac_ids;
}

=head2 trim

Method for triming the space of form value

=cut

sub trim : Private {
    my ( $self, $string ) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

=head2 is_a_number

Method to check if it is a number

=cut

sub is_a_number : Private {
    my ( $self, $c, $number ) = @_;

    #$c->log->debug("checking number for: $number");
    if ( $number =~ /^\d+$/ ) {
        return 1;
    }
    return 0;
}

=head1 AUTHOR

Wanjuan Yang wy1@sanger.ac.uk

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

