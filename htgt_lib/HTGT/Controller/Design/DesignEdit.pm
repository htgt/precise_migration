package HTGT::Controller::Design::DesignEdit;
use HTGT::Utils::Design::DesignServer;
use HTGT::Controller::Design::TargetFinder;

use strict;
use warnings;
use DateTime;
use base 'Catalyst::Controller';

#use HTTP::Lite;
#use LWP::Simple;
use Bio::Perl;
use Data::Dumper;
use HTGT::Utils::DesignPhase qw( get_phase_from_transcript_id_and_U5_oligo
                                 create_U5_oligo_loc_from_cassette_coords );

=head1 NAME

HTGT::Controller::Design::DesignEdit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/design/designedit/show_create') );
}

sub show_create : Local {
    my ( $self, $c ) = @_;

    my $user_name = $self->check_authorised($c);

    $c->log->debug("got user name: $user_name");
    if ( !$user_name ) {
        $c->forward('/welcome');
    }
    else {
        $c->stash->{design_comment_categories}
            = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
            $c->stash->{template} = 'design/edit.tt';
    }
}

sub load_design_form : Local {
    my ( $self, $c ) = @_;

    my $design_info;    #store info to send back to template
    my $design_type_info;

    # read the parameters
    $design_info->{design_type}              = $c->request->param('design_type');
    $design_info->{oligo_select_method}      = $c->request->param('oligo_select_method');
    $design_info->{artificial_intron_design} = $c->request->param('artificial_intron_design');

    my $user_name = $self->check_authorised($c);
    if ( !$user_name ) {
        $c->forward('/welcome');
    }
    else {
        $design_info->{created_user} = $user_name;
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);

        #The perl on this mac is returning unusual offsets for these time values.
        $mon++;
        $year = $year - 100 + 2000;
        $c->log->debug("$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst");
        $design_info->{score} = $user_name . "_${mday}_${mon}_${year}";
        $c->log->debug( "Design info - score: " . $design_info->{score} );

        $c->log->debug("writing new design-create screen");

        # get gene build list
        my $gene_builds = $self->get_gene_build_list($c);
        my @gene_builds_for_dropdown;
        foreach my $gene_build (@$gene_builds) {
            push @gene_builds_for_dropdown, $gene_build->version . " : " . $gene_build->name;
        }

        # sort the dropdown list
        @gene_builds_for_dropdown = sort @gene_builds_for_dropdown;
        $design_info->{gene_build_list} = \@gene_builds_for_dropdown;

        $design_info->{target_start}       = undef;
        $design_info->{target_end}         = undef;
        $design_info->{min_3p_exon_flanks} = 100;
        $design_info->{min_5p_exon_flanks} = 300;

        # seperate multi_region_offset_shim to 5p / 3p two different params.
        $design_info->{multi_region_5p_offset_shim} = 60;
        $design_info->{multi_region_3p_offset_shim} = 60;

        $design_info->{primer_length}              = 50;
        $design_info->{retrieval_primer_length_3p} = 1000;
        $design_info->{retrieval_primer_length_5p} = 1000;
        $design_info->{retrieval_primer_offset_3p} = 4500;
        $design_info->{retrieval_primer_offset_5p} = 6500;

     # seperate split_target_seq_length to 5p/3p two different paras, but still keep original for Block specified design
        $design_info->{split_target_seq_length}    = 120;
        $design_info->{split_5p_target_seq_length} = 120;
        $design_info->{split_3p_target_seq_length} = 120;

        $design_info->{oligo_strand} = 'forward';

        $c->log->debug( "size of initialised gene-build-dropdown " . scalar(@$gene_builds) );

        $c->stash->{design_comment_categories}
            = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
            $c->stash->{design_info} = $design_info;
        $c->stash->{mode}            = 'create';
        $c->stash->{template}        = 'design/edit.tt';
    }
}

sub search_for_gene_build_gene : Local {
    my ( $self, $c ) = @_;
    my $design_info;

    my $user_name = $self->check_authorised($c);

    # read the parameters
    $design_info->{min_3p_exon_flanks} = $c->request->param('min_3p_exon_flanks');
    $design_info->{min_5p_exon_flanks} = $c->request->param('min_5p_exon_flanks');

    # 5p/3p of multi_region_offset_shim
    $design_info->{multi_region_5p_offset_shim} = $c->request->param('multi_region_5p_offset_shim');
    $design_info->{multi_region_3p_offset_shim} = $c->request->param('multi_region_3p_offset_shim');

    $design_info->{primer_length}              = $c->request->param('primer_length');
    $design_info->{retrieval_primer_length_3p} = $c->request->param('retrieval_primer_length_3p');
    $design_info->{retrieval_primer_length_5p} = $c->request->param('retrieval_primer_length_5p');
    $design_info->{retrieval_primer_offset_3p} = $c->request->param('retrieval_primer_offset_3p');
    $design_info->{retrieval_primer_offset_5p} = $c->request->param('retrieval_primer_offset_5p');
    $design_info->{score}                      = $c->request->param('score');

    # 5p/3p of split_target_seq_length
    $design_info->{split_5p_target_seq_length} = $c->request->param('split_5p_target_seq_length');
    $design_info->{split_3p_target_seq_length} = $c->request->param('split_3p_target_seq_length');

    # still need to read split_target_seq_length for block specified design
    #$design_info->{split_target_seq_length} = $c->request->param('split_target_seq_length');
    $design_info->{artificial_intron_design} = $c->request->param('artificial_intron_design');
    $design_info->{design_type}              = $c->request->param('design_type');
    $design_info->{oligo_select_method}      = $c->request->param('oligo_select_method');
    $design_info->{subtype}                  = $c->request->param('subtype');
    $design_info->{subtype_description}      = $c->request->param('subtype_description');
    $design_info->{created_user}             = $user_name;
    $design_info->{message}                  = "";                                               #store error message

    my @design_info_keys = keys %$design_info;

    my $exon_list;
    my $primary_name;
    my $chr_strand;

    $c->log->debug( "gene_build: " . $c->request->param('gene_build') );
    $c->log->debug( "gene_build gene: " . $c->request->param('selected_gene_build_gene') );

    if ( $c->request->param('gene_build') && $c->request->param('selected_gene_build_gene') ) {

        if (   ( $c->request->param('selected_gene_build_gene') =~ /OTT/ )
            || ( $c->request->param('selected_gene_build_gene') =~ /ENS/ ) )
        {
            ( $exon_list, $primary_name, $chr_strand )
                = $self->get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name(
                $c,
                $c->request->param('gene_build'),
                $c->request->param('selected_gene_build_gene')
                );

        }
        else {
            $design_info->{message} = "Gene name must be either Ensembl (ENSMUSG...) or Vega (OTTMUSG...) identifier";
        }
    }
    else {
        $design_info->{message} = "Gene build and Gene name must be populated";
    }

    $design_info->{gene_build}               = $c->request->param('gene_build');
    $design_info->{exons}                    = $exon_list;
    $design_info->{selected_gene_build_gene} = $primary_name;
    $design_info->{chr_strand}               = $chr_strand;

    # get gene build list
    my $gene_builds = $self->get_gene_build_list($c);
    my $gene_builds_for_dropdown;
    foreach my $gene_build (@$gene_builds) {
        push @$gene_builds_for_dropdown, $gene_build->version . " : " . $gene_build->name;
    }

    # check if the gene build in the list, if not, add it in
    my $found = 0;    # a flag

    # loop every gene build in the list and see any of them is the same as the origianl one
    foreach my $gene_build_in_the_list (@$gene_builds_for_dropdown) {
        if ( $gene_build_in_the_list eq $design_info->{gene_build} ) {
            $found = 1;
        }
    }

    # not found, add it in
    if ( $found == 0 ) {
        push @$gene_builds_for_dropdown, $design_info->{gene_build};
    }

    # sort the dropdown list
    @$gene_builds_for_dropdown = sort @$gene_builds_for_dropdown;
    $design_info->{gene_build_list} = $gene_builds_for_dropdown;

    $c->log->debug( "design type:" . $design_info->{design_type} );
    $c->stash->{mode} = 'create';

    #add a new marker to display 'find me a target' button
    if (   $design_info->{message} eq ""
        && $exon_list
        && $design_info->{design_type} eq "Knockout first"
        && $design_info->{oligo_select_method} eq "Block Specified" )
    {
        $c->stash->{display_find_target} = 1;
    }

    $c->stash->{design_info} = $design_info;
    $c->stash->{design_comment_categories}
        = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
        $c->stash->{template} = 'design/edit.tt';
}

sub refresh_design : Local {
    my ( $self, $c ) = @_;

    my $design_id          = $c->request->param('design_id');
    my $design_instance_id = $c->request->param('design_instance_id');
    my $oligo_strand       = $c->request->param('oligo_strand');

    my $design;
    if ($design_id) {
        $design = $c->model('HTGTDB::Design')->search( design_id => $design_id )->first;
    }
    elsif ($design_instance_id) {
        my $design_instance
            = $c->model('HTGTDB::DesignInstance')->search( design_instance_id => $design_instance_id )->first;
        $design = $design_instance->design;
    }

    if ( !$design ) {
        $c->flash->{error_msg} = "Design not found";
        $c->log->debug("Can't find design to refresh.");
        $c->response->redirect('/design/designlist/list_designs');
        return;
    }

    # check if it is a regeneron design, if yes, link to velocigene page
    my $design_parameter_name = $design->design_parameter->parameter_name;

    if ( $design_parameter_name =~ /REGENERON/ ) {

        # GET the regeneron id
        my @regeneron_name = split /_/, $design_parameter_name;
        my $regeneron_id = $regeneron_name[0];

        my $regeneron_url = "http://www.velocigene.com/komp/detail/" . $regeneron_id;

        $c->response->redirect($regeneron_url);    #change here to regeneron page
    }
    else {

        my $design_info = $self->create_design_info_from_stored_design( $c, $design, $oligo_strand );

        # add import_otter_gene flag to indicate whether the design is from import otter gene
        if ( $design_info->{status} eq "Created" && $design_info->{gene_build} eq "3:otter_flex" ) {

            # add a flag
            $design_info->{import_otter_gene} = 1;

            # if it is the design from importing otter gene, then display in 'create' mode in template
            $c->stash->{mode} = 'create';

#in this case , we need to get gene builds list including the 'otter_flex' && exon lists to send to template, allow user to select

            my $gene_builds = $self->get_gene_build_list($c);
            my $gene_builds_for_dropdown;
            foreach my $gene_build (@$gene_builds) {
                push @$gene_builds_for_dropdown, $gene_build->version . " : " . $gene_build->name;
            }

            # check if the gene build in the list, if not, add it in
            my $found = 0;    # a flag

            # loop every gene build in the list and see any of them is the same as the origianl one
            foreach my $gene_build_in_the_list (@$gene_builds_for_dropdown) {
                if ( $gene_build_in_the_list eq $design_info->{gene_build} ) {
                    $found = 1;
                }
            }

            # not found, add it in
            if ( $found == 0 ) {
                push @$gene_builds_for_dropdown, $design_info->{gene_build};
            }

            # sort the dropdown list
            @$gene_builds_for_dropdown = sort @$gene_builds_for_dropdown;
            $design_info->{gene_build_list} = $gene_builds_for_dropdown;

            # get exon list to allow user to select
            my $exon_list;
            my $primary_name;

            ( $exon_list, $primary_name ) = $self->get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name(
                $c,
                $design_info->{gene_build},
                $design_info->{selected_gene_build_gene}
            );
            $design_info->{exons} = $exon_list;
        }

        $c->log->debug( "import otter gene flag: " . $design_info->{import_otter_gene} );

        my $user_name = $self->check_authorised($c);
        if ( $design_info->{created_user} && ( $design_info->{created_user} eq $user_name ) ) {
            $design_info->{show_delete} = 1;
        }
        else {
            $design_info->{show_delete} = 0;
        }

        #check if the design has design instance
        my @design_instances = $c->model('HTGTDB::DesignInstance')->search( design_id => $design_id );
        if ( scalar(@design_instances) > 0 ) {
            $design_info->{design_instance} = 1;
        }

        #$c->log->debug("Design info has: ".scalar(@{$design_info->{features}})." features stored");

        # interpret the design_type
        if ( $design_info->{design_type} eq "KO" ) {
            $design_info->{design_type}         = "Knockout first";
            $design_info->{oligo_select_method} = "Block Specified";
        }
        elsif ( $design_info->{design_type} eq "KO_Location" ) {
            $design_info->{design_type}         = "Knockout first";
            $design_info->{oligo_select_method} = "Location Specified";
        }
        elsif ( $design_info->{design_type} eq "Del_Block" ) {
            $design_info->{design_type}         = "Deletion";
            $design_info->{oligo_select_method} = "Block Specified";
        }
        elsif ( $design_info->{design_type} eq "Del_Location" ) {
            $design_info->{design_type}         = "Deletion";
            $design_info->{oligo_select_method} = "Location Specified";
        }
        elsif ( $design_info->{design_type} eq "Ins_Block" ) {
            $design_info->{design_type}         = "Insertion";
            $design_info->{oligo_select_method} = "Block Specified";
        }
        elsif ( $design_info->{design_type} eq "Ins_Location" ) {
            $design_info->{design_type}         = "Insertion";
            $design_info->{oligo_select_method} = "Location Specified";
        }

        #hack for Alejandro - get rcmb primers in orientation of target gene
        my $frs     = $design->validated_features;
        my $dstrand = $design->locus->chr_strand;
        $c->stash->{concat_rcmb_primers} = join "", map { $dstrand == -1 ? revcom_as_string($_) : $_ }
            map  { $_->get_seq_str }
            grep {$_}
            map  { $frs->search( q(feature_type.description) => $_, { join => q(feature_type) } )->first }
            qw(G5 U5 U3 D5 D3 G3);

        $c->stash->{design_info} = $design_info;
        $c->stash->{design_comment_categories}
            = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
            $c->stash->{template} = 'design/edit.tt';
    }
}

sub edit_design : Local {
    my ( $self, $c ) = @_;

    # read the info from current design:
    my $design_id    = $c->request->param('design_id');
    my $oligo_strand = $c->request->param('oligo_strand');

    my $design = $c->model('HTGTDB::Design')->search( design_id => $design_id )->first;
    if ( !$design ) {
        $c->log->debug("Cant find the design to edit.");
        $c->flash->{error_msg} = "Design not found";
        $c->response->redirect('/design/designlist/list_designs');
        return;
    }
    my $design_info = $self->create_design_info_from_stored_design( $c, $design, $oligo_strand );

    # interpret the design type & desertion type
    if ( $design_info->{design_type} eq "KO" ) {
        $design_info->{design_type}         = "Knockout first";
        $design_info->{oligo_select_method} = "Block Specified";
    }
    elsif ( $design_info->{design_type} eq "KO_Location" ) {
        $design_info->{design_type}         = "Knockout first";
        $design_info->{oligo_select_method} = "Location Specified";
    }
    elsif ( $design_info->{design_type} eq "Del_Block" ) {
        $design_info->{design_type}         = "Deletion";
        $design_info->{oligo_select_method} = "Block Specified";
    }
    elsif ( $design_info->{design_type} eq "Del_Location" ) {
        $design_info->{design_type}         = "Deletion";
        $design_info->{oligo_select_method} = "Location Specified";
    }
    elsif ( $design_info->{design_type} eq "Ins_Block" ) {
        $design_info->{design_type}         = "Insertion";
        $design_info->{oligo_select_method} = "Block Specified";
    }
    elsif ( $design_info->{design_type} eq "Ins_Location" ) {
        $design_info->{design_type}         = "Insertion";
        $design_info->{oligo_select_method} = "Location Specified";
    }

# To keep the input while also give the available choices, so we need to get the gene build lists & exon lists & project lists
# At the same time we need to refresh the design id

    #get gene builds info
    # Here should it keep the original gene build???

    my $gene_builds = $self->get_gene_build_list($c);
    my $gene_builds_for_dropdown;
    foreach my $gene_build (@$gene_builds) {
        push @$gene_builds_for_dropdown, $gene_build->version . " : " . $gene_build->name;
    }

    # check if the gene build in the list, if not, add it in
    my $found = 0;    # a flag

    # loop every gene build in the list and see any of them is the same as the origianl one
    foreach my $gene_build_in_the_list (@$gene_builds_for_dropdown) {
        if ( $gene_build_in_the_list eq $design_info->{gene_build} ) {
            $found = 1;
        }
    }

    # not found, add it in
    if ( $found == 0 ) {
        push @$gene_builds_for_dropdown, $design_info->{gene_build};
    }

    # sort the dropdown list
    @$gene_builds_for_dropdown = sort @$gene_builds_for_dropdown;
    $design_info->{gene_build_list} = $gene_builds_for_dropdown;

    #get exon lists & project list
    my $exon_list;
    my $primary_name;

    ( $exon_list, $primary_name ) = $self->get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name(
        $c,
        $design_info->{gene_build},
        $design_info->{selected_gene_build_gene}
    );

    $design_info->{exons} = $exon_list;

    # refresh the design id
    $design_info->{design_id} = "";

    # update the created_user to current user
    $design_info->{created_user} = $self->check_authorised($c);

    #update design comment
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
    $mon++;
    $year = $year - 100 + 2000;
    $design_info->{score} = $design_info->{created_user} . "_${mday}_${mon}_${year}";

    # change to create mode
    $c->stash->{mode} = 'create';

    # send design info back to template
    $c->stash->{design_info} = $design_info;
    $c->stash->{design_comment_categories}
        = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
        $c->stash->{template} = 'design/edit.tt';
}

sub export_design : Local {
    my ( $self, $c ) = @_;
    my $design_id    = $c->request->param('design_id');
    my $oligo_strand = $c->request->param('oligo_strand');
    my $design       = $c->model('HTGTDB::Design')->search( design_id => $design_id )->first;
    if ( !$design ) {
        $c->log->debug("Can't find the design to refresh!");
        $c->stash->{template} = 'design/list.tt';
        return;
    }

    my $design_info = $self->create_design_info_from_stored_design( $c, $design, $oligo_strand );
    my $export;
    $export .= "Design ID," . $design_info->{design_id} . "\n";
    $export .= "Status," . $design_info->{status} . "\n";
    $export .= "Gene Build," . $design_info->{gene_build} . "\n";
    $export .= "Gene," . $design_info->{selected_gene_build_gene} . "\n";
    $export .= "Gene," . $design_info->{selected_gene_build_gene} . "\n";
    $export .= "BACs," . $design_info->{bac_string} . "\n";
    foreach my $instance ( @{ $design_info->{instance_string_array} } ) {
        $export .= "Instance, $instance\n";
    }
    $export .= "Start Exon," . $design_info->{start_exon} . "\n";
    $export .= "End Exon," . $design_info->{end_exon} . "\n";
    $export .= "Target Start," . $design_info->{target_start} . "\n";
    $export .= "Target End," . $design_info->{target_end} . "\n";
    $export .= "Min 5 prime Spacer," . $design_info->{min_5p_exon_flanks} . "\n";
    $export .= "Min 3 prime Spacer," . $design_info->{min_3p_exon_flanks} . "\n";
    $export .= "U Block Size," . $design_info->{split_5p_target_seq_length} . "\n";
    $export .= "U Block Offset," . $design_info->{multi_region_5p_offset_shim} . "\n";
    $export .= "D Block Size," . $design_info->{split_3p_target_seq_length} . "\n";
    $export .= "D Block Offset," . $design_info->{multi_region_3p_offset_shim} . "\n";
    $export .= "5 prime retrieval arm length," . $design_info->{retrieval_primer_offset_5p} . "\n";
    $export .= "3 prime retrieval arm length," . $design_info->{retrieval_primer_offset_3p} . "\n";
    $export .= "Primer Length," . $design_info->{primer_length} . "\n";
    $export .= "Comment," . $design_info->{score} . "\n";
    $export .= "Created By," . $design_info->{created_user} . "\n";

    foreach my $feature ( @{ $design_info->{features} } ) {
        $export .= "Feature," . $feature->{name} . "," . $feature->{length} . "," . $feature->{seq} . "\n";
    }
    foreach my $note ( $design_info->{design_notes} ) {
        $export .= "Note,$note\n";
    }

    $c->res->content_type('application/ms-excel');
    my $filename = "design_${design_id}_export.csv";
    $c->res->header( 'Content-Disposition', qq[attachment; filename="$filename"] );
    $c->res->body($export);
}

sub create_design_and_run : Local {
    my ( $self, $c ) = @_;

    my $time = $self->get_time;
    $c->log->debug("$time : Entering create_design_and_run");

    my $created_user = $self->check_authorised($c);
    if ( !$created_user ) {
        $c->forward('/welcome');
    }

    $c->log->debug("$time : after check_authorised");

    $time = $self->get_time;
    $c->log->debug("$time : Creating design");

    my $design_type              = $c->request->param('design_type');
    my $oligo_select_method      = $c->request->param('oligo_select_method');
    my $artificial_intron_design = $c->request->param('artificial_intron_design');

    my %HANDLER_FOR = (
        'Knockout first.Block Specified'    => 'create_design_for_KO_Block_Specified',
        'Knockout first.Location Specified' => 'create_design_for_KO_Location_Specified',
        'Deletion.Block Specified'          => 'create_design_for_Deletion_Block_Specified',
        'Deletion.Location Specified'       => 'create_design_for_InsDel_Location_Specified',
        'Insertion.Block Specified'         => 'create_design_for_Insertion_Block_Specified',
        'Insertion.Location Specified'      => 'create_design_for_InsDel_Location_Specified',
    );

    my $design_info;
    my $design;    # to store the result

    my $method = $HANDLER_FOR{"$design_type.$oligo_select_method"};
    if ($method) {
        ( $design, $design_info ) = $self->$method($c);
    }
    else {
        $design_info = { message => "Invalid design type/oligo select method: $design_type/$oligo_select_method" };
    }

    if ( $design_info->{message} ne "" || !$design ) {
        $c->log->debug( "Something went wrong: " . $design_info->{message} );

        # need gene build list & exon list and send back to edit page
        #get gene builds info
        my $gene_builds = $self->get_gene_build_list($c);
        my $gene_builds_for_dropdown;
        foreach my $gene_build (@$gene_builds) {
            push @$gene_builds_for_dropdown, $gene_build->version . " : " . $gene_build->name;
        }

        # sort the dropdown list
        @$gene_builds_for_dropdown = sort @$gene_builds_for_dropdown;
        $design_info->{gene_build_list} = $gene_builds_for_dropdown;

        #get exon lists & project list
        my $exon_list;
        my $primary_name;

        ( $exon_list, $primary_name ) = $self->get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name(
            $c,
            $design_info->{gene_build},
            $design_info->{selected_gene_build_gene}
        );

        $design_info->{exons} = $exon_list;

        # switch to create mode
        $c->stash->{mode} = 'create';

    }
    else {
        $time = $self->get_time;
        $c->log->debug( "$time : created design, id: " . $design->design_id );

        $c->stash->{mode} = 'edit';

        $design_info->{design_id} = $design->design_id;

        my $design_status = $design->design_statuses->first;

        $time = $self->get_time;
        $c->log->debug( "$time : retrieved design status: " . $design_status->design_status_id );

        my $dict_entry = $design->design_statuses->first->design_status_dict;

        $time = $self->get_time;
        $c->log->debug( "$time : retrieved dict entry : " . $dict_entry );
        $design_info->{status} = $dict_entry->description;

        my $design_notes;
        foreach my $design_note ( $design->design_notes ) {
            $time = $self->get_time;
            $c->log->debug( "$time : Design NOTE: " . $design_note->design_note_id );
            push @$design_notes, $design_note->note;
        }

        $design_info->{design_notes} = $design_notes;

        $self->start_design_run( $c, $design->design_id );

        $time = $self->get_time;
        $c->log->debug("$time: leaving create_design_and_run");
    }

    $design_info->{design_type}         = $design_type;
    $design_info->{oligo_select_method} = $oligo_select_method;

    $c->log->debug( "Design type: " . $design_info->{design_type} );
    $c->stash->{design_info} = $design_info;
    $c->stash->{design_comment_categories}
        = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
        $c->stash->{template} = 'design/edit.tt';
}

=head2 run_design 

method for updating existing design parameter & locus & start design run, called from design page

=cut

sub run_design : Local {
    my ( $self, $c ) = @_;

    my $design_info;
    my $design;

    # read parameters
    my $created_user        = $self->check_authorised($c);
    my $subtype             = $c->request->param('subtype');
    my $subtype_description = $c->request->param('subtype_description');
    my $target_start        = $c->request->param('target_start');
    my $target_end          = $c->request->param('target_end');
    my $min_3p_exon_flanks  = $c->request->param('min_3p_exon_flanks');
    my $min_5p_exon_flanks  = $c->request->param('min_5p_exon_flanks');

    # 5p/3p
    my $multi_region_5p_offset_shim = $c->request->param('multi_region_5p_offset_shim');
    my $multi_region_3p_offset_shim = $c->request->param('multi_region_3p_offset_shim');
    my $primer_length               = $c->request->param('primer_length');
    my $retrieval_primer_length_3p  = $c->request->param('retrieval_primer_length_3p');
    my $retrieval_primer_length_5p  = $c->request->param('retrieval_primer_length_5p');
    my $retrieval_primer_offset_3p  = $c->request->param('retrieval_primer_offset_3p');
    my $retrieval_primer_offset_5p  = $c->request->param('retrieval_primer_offset_5p');
    my $score                       = $c->request->param('score');

    # 5p/3p
    my $split_5p_target_seq_length = $c->request->param('split_5p_target_seq_length');
    my $split_3p_target_seq_length = $c->request->param('split_3p_target_seq_length');

    # store design_info
    $design_info->{subtype}             = $subtype;
    $design_info->{subtype_description} = $subtype_description;
    $design_info->{min_3p_exon_flanks}  = $min_3p_exon_flanks;
    $design_info->{min_5p_exon_flanks}  = $min_5p_exon_flanks;

    # 3p/5p
    $design_info->{multi_region_5p_offset_shim} = $multi_region_5p_offset_shim;
    $design_info->{multi_region_3p_offset_shim} = $multi_region_3p_offset_shim;

    $design_info->{primer_length}              = $primer_length;
    $design_info->{retrieval_primer_length_3p} = $retrieval_primer_length_3p;
    $design_info->{retrieval_primer_length_5p} = $retrieval_primer_length_5p;
    $design_info->{retrieval_primer_offset_3p} = $retrieval_primer_offset_3p;
    $design_info->{retrieval_primer_offset_5p} = $retrieval_primer_offset_5p;

    # 5p/3p
    $design_info->{split_5p_target_seq_length} = $split_5p_target_seq_length;
    $design_info->{split_3p_target_seq_length} = $split_3p_target_seq_length;

    $design_info->{score} = $score;

    $design_info->{target_start} = $target_start;
    $design_info->{target_end}   = $target_end;
    $design_info->{created_user} = $created_user;
    $design_info->{message}      = "";              #store error message

    if (!(     $target_start
            && $target_end
            && $min_3p_exon_flanks
            && $min_5p_exon_flanks
            && $multi_region_5p_offset_shim
            && $multi_region_3p_offset_shim
            && $primer_length
            && $retrieval_primer_length_3p
            && $retrieval_primer_length_5p
            && $retrieval_primer_offset_3p
            && $retrieval_primer_offset_5p
            && $split_5p_target_seq_length
            && $split_3p_target_seq_length
            && $created_user
        )
        )
    {
        $design_info->{message} = "All parameters must be specified (and numeric parameters must be greater than zero)";
        $c->log->debug("parameters not complete!");
    }
    else {
        if ( !$self->is_a_number( $c, $target_start ) ) {
            $design_info->{message} = "Target start ($target_start) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $target_end ) ) {
            $design_info->{message} = "Target end ($target_end) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_5p_exon_flanks ) ) {
            $design_info->{message} = "Min 5 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_3p_exon_flanks ) ) {
            $design_info->{message} = "Min 3 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_5p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_5p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_3p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_3p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $multi_region_5p_offset_shim ) ) {
            $design_info->{message} = "Block offset ($multi_region_5p_offset_shim) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $multi_region_3p_offset_shim ) ) {
            $design_info->{message} = "Block offset ($multi_region_3p_offset_shim) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $primer_length ) ) {
            $design_info->{message} = "Primer length ($primer_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_3p ) ) {
            $design_info->{message} = "3' Retrieval arm length ($retrieval_primer_length_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_5p ) ) {
            $design_info->{message} = "5' Retrieval arm length ($retrieval_primer_length_5p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_3p ) ) {
            $design_info->{message} = "3' Retrieval block size ($retrieval_primer_offset_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_5p ) ) {
            $design_info->{message} = "5' Retrieval block size ($retrieval_primer_offset_5p) isn't a valid number";
        }
        else {

            #
            #recover the start/end exon-ids from the gene-build, gbg and exon names
            # Note - this will feed the 'right' exon-ids back - in the event the start and end exons
            # are different, we will get back the exon nearest the U cassette.
            #
            my $time = $self->get_time;
            $c->log->debug("$time : creating design: fetching gene build and exon ids");

            # update design_parameter
            my $parameter_string
                = qq[min_3p_exon_flanks=$min_3p_exon_flanks,min_5p_exon_flanks=$min_5p_exon_flanks,multi_region_5p_offset_shim=$multi_region_5p_offset_shim,multi_region_3p_offset_shim=$multi_region_3p_offset_shim,primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,split_5p_target_seq_length=$split_5p_target_seq_length,split_3p_target_seq_length=$split_3p_target_seq_length,score=$score
          ];

            my $design_id = $c->request->param('design_id');
            $design_info->{design_id} = $design_id;
            $design = $c->model('HTGTDB::Design')->search( design_id => $design_id )->first;
            my $design_parameter_id = $design->design_parameter_id;

            my $design_parameter
                = $c->model('HTGTDB::DesignParameter')->search( design_parameter_id => $design_parameter_id )->first;

            $design_parameter->update( { parameter_value => $parameter_string } );

            # update locus
            if ( $target_start > $target_end ) {
                $design->locus->update(
                    {   chr_start => $target_end,
                        chr_end   => $target_start
                    }
                );
            }
            else {
                $design->locus->update(
                    {   chr_start => $target_start,
                        chr_end   => $target_end
                    }
                );
            }

            # update design
            $design->update(
                {   subtype             => $subtype,
                    subtype_description => $subtype_description
                }
            );

            if ( $design_info->{message} ne "" ) {

                # send back message
            }
            else {

                # start to run the design
                $self->start_design_run( $c, $design_id );
            }
        }
    }

    # get design info from stored design
    my $oligo_strand = $c->request->param('oligo_strand');
    $design_info = $self->create_design_info_from_stored_design( $c, $design, $oligo_strand );

    # interpret the design type to the type that template can recognize
    $design_info->{design_type} = "Knockout first";

    $c->log->debug( "import otter gene flag:" . $design_info->{import_otter_gene} . "\n" );

    $c->stash->{mode}        = 'edit';
    $c->stash->{design_info} = $design_info;
    $c->stash->{design_comment_categories}
        = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
        $c->stash->{template} = 'design/edit.tt';
}

sub create_design_for_KO_Block_Specified {
    my ( $self, $c ) = @_;
    my $design_info;

    # read parameters
    my $created_user = $self->check_authorised($c);

    my $subtype                  = $c->request->param('subtype');
    my $subtype_description      = $c->request->param('subtype_description');
    my $gene_build               = $c->request->param('gene_build');
    my $gene_build_gene          = $c->request->param('selected_gene_build_gene');
    my $artificial_intron_design = $c->request->param('artificial_intron_design');

    my $start_exon = $c->request->param('start_exon');
    my $end_exon   = $c->request->param('end_exon');

    my $target_start       = $c->request->param('target_start');
    my $target_end         = $c->request->param('target_end');
    my $min_3p_exon_flanks = $c->request->param('min_3p_exon_flanks');
    my $min_5p_exon_flanks = $c->request->param('min_5p_exon_flanks');

    # 5p/3p
    my $multi_region_5p_offset_shim = $c->request->param('multi_region_5p_offset_shim');
    my $multi_region_3p_offset_shim = $c->request->param('multi_region_3p_offset_shim');

    my $primer_length              = $c->request->param('primer_length');
    my $retrieval_primer_length_3p = $c->request->param('retrieval_primer_length_3p');
    my $retrieval_primer_length_5p = $c->request->param('retrieval_primer_length_5p');
    my $retrieval_primer_offset_3p = $c->request->param('retrieval_primer_offset_3p');
    my $retrieval_primer_offset_5p = $c->request->param('retrieval_primer_offset_5p');
    my $score                      = $c->request->param('score');

    # 5p/3p
    my $split_5p_target_seq_length = $c->request->param('split_5p_target_seq_length');
    my $split_3p_target_seq_length = $c->request->param('split_3p_target_seq_length');
    my @selected_projects          = $c->request->param('projects');
    my $selected_projects          = \@selected_projects;

    # store design_info
    $design_info->{subtype}             = $subtype;
    $design_info->{subtype_description} = $subtype_description;
    $design_info->{min_3p_exon_flanks}  = $min_3p_exon_flanks;
    $design_info->{min_5p_exon_flanks}  = $min_5p_exon_flanks;

    # 3p/5p
    $design_info->{multi_region_5p_offset_shim} = $multi_region_5p_offset_shim;
    $design_info->{multi_region_3p_offset_shim} = $multi_region_3p_offset_shim;

    $design_info->{primer_length}              = $primer_length;
    $design_info->{retrieval_primer_length_3p} = $retrieval_primer_length_3p;
    $design_info->{retrieval_primer_length_5p} = $retrieval_primer_length_5p;
    $design_info->{retrieval_primer_offset_3p} = $retrieval_primer_offset_3p;
    $design_info->{retrieval_primer_offset_5p} = $retrieval_primer_offset_5p;

    # 5p/3p
    $design_info->{split_5p_target_seq_length} = $split_5p_target_seq_length;
    $design_info->{split_3p_target_seq_length} = $split_3p_target_seq_length;

    $design_info->{score}                    = $score;
    $design_info->{gene_build}               = $gene_build;
    $design_info->{selected_gene_build_gene} = $gene_build_gene;
    $design_info->{selected_projects}        = $selected_projects;
    $design_info->{start_exon}               = $start_exon;
    $design_info->{end_exon}                 = $end_exon;
    $design_info->{target_start}             = $target_start;
    $design_info->{target_end}               = $target_end;
    $design_info->{created_user}             = $created_user;
    $design_info->{message}                  = "";                   #store error message
    my $design;

    if (!(     $gene_build
            && $gene_build_gene
            && $start_exon
            && $end_exon
            && $target_start
            && $target_end
            && $min_3p_exon_flanks
            && $min_5p_exon_flanks
            && $multi_region_5p_offset_shim
            && $multi_region_3p_offset_shim
            && $primer_length
            && $retrieval_primer_length_3p
            && $retrieval_primer_length_5p
            && $retrieval_primer_offset_3p
            && $retrieval_primer_offset_5p
            && $split_5p_target_seq_length
            && $split_3p_target_seq_length
            && $created_user
        )
        )
    {
        $design_info->{message} = "All parameters must be specified (and numeric parameters must be greater than zero)";
        $c->log->debug("parameters not complete!");
    }
    else {
        if ( !$self->is_a_number( $c, $target_start ) ) {
            $design_info->{message} = "Target start ($target_start) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $target_end ) ) {
            $design_info->{message} = "Target end ($target_end) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_5p_exon_flanks ) ) {
            $design_info->{message} = "Min 5 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_3p_exon_flanks ) ) {
            $design_info->{message} = "Min 3 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_5p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_5p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_3p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_3p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $multi_region_5p_offset_shim ) ) {
            $design_info->{message} = "Block offset ($multi_region_5p_offset_shim) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $multi_region_3p_offset_shim ) ) {
            $design_info->{message} = "Block offset ($multi_region_3p_offset_shim) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $primer_length ) ) {
            $design_info->{message} = "Primer length ($primer_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_3p ) ) {
            $design_info->{message} = "3' Retrieval arm length ($retrieval_primer_length_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_5p ) ) {
            $design_info->{message} = "5' Retrieval arm length ($retrieval_primer_length_5p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_3p ) ) {
            $design_info->{message} = "3' Retrieval block size ($retrieval_primer_offset_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_5p ) ) {
            $design_info->{message} = "5' Retrieval block size ($retrieval_primer_offset_5p) isn't a valid number";
        }
        else {

            #
            #recover the start/end exon-ids from the gene-build, gbg and exon names
            # Note - this will feed the 'right' exon-ids back - in the event the start and end exons
            # are different, we will get back the exon nearest the U cassette.
            #
            my $time = $self->get_time;
            $c->log->debug("$time : creating design: fetching gene build and exon ids");

            my ( $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id, $chr_name, $chr_strand )
                = $self->get_gene_build_and_exon_ids( $c, $gene_build, $gene_build_gene, $start_exon, $end_exon );

            unless ($gene_build_id) {
                $c->log->warn("failed to retrieve target gene/exons for $gene_build");
                $design_info->{message} = "failed to retrieve target gene/exons from build $gene_build";
                return ( undef, $design_info );
            }

            $time = $self->get_time;
            $c->log->debug("$time : got gene_build_id: $gene_build_id and exonids: $start_exon_id - $end_exon_id");

            # create design_parameter
            my $parameter_string
                = qq[min_3p_exon_flanks=$min_3p_exon_flanks,min_5p_exon_flanks=$min_5p_exon_flanks,multi_region_5p_offset_shim=$multi_region_5p_offset_shim,multi_region_3p_offset_shim=$multi_region_3p_offset_shim,primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,split_5p_target_seq_length=$split_5p_target_seq_length,split_3p_target_seq_length=$split_3p_target_seq_length,score=$score
          ];

            my $design_parameter = $self->create_design_parameter( $c, $parameter_string );

            $time = $self->get_time;
            $c->log->debug(
                      "$time : Created design parameter with values: $c, $min_3p_exon_flanks, $min_5p_exon_flanks, "
                    . "$multi_region_5p_offset_shim,$multi_region_3p_offset_shim, $primer_length, $retrieval_primer_length_3p, "
                    . "$retrieval_primer_length_5p, $retrieval_primer_offset_3p" );

            my $design_type = "KO";

            # create design record
            $design = $self->create_design(
                $c,           $gene_build_id,       $start_exon_id, $end_exon_id,
                $assembly_id, $chr_name,            $target_start,  $target_end,
                $chr_strand,  $design_parameter,    $created_user,  $design_type,
                $subtype,     $subtype_description, $artificial_intron_design
            );

            $design->update( {
                phase => $design->start_exon->phase,
            } );
        }
    }

    if ( $design_info->{message} ne "" ) {
        return ( undef, $design_info );
    }
    else {
        return ( $design, $design_info );
    }
}

sub create_design_for_Deletion_Block_Specified {
    my ( $self, $c ) = @_;
    my $design_info;

    # read parameters
    my $artificial_intron_design = $c->request->param('artificial_intron_design');
    my $subtype                  = $c->request->param('subtype');
    my $subtype_description      = $c->request->param('subtype_description');
    my $created_user             = $self->check_authorised($c);
    my $gene_build               = $c->request->param('gene_build');
    my $gene_build_gene          = $c->request->param('selected_gene_build_gene');
    my $start_exon               = $c->request->param('start_exon');
    my $end_exon                 = $c->request->param('end_exon');
    my $target_start             = $c->request->param('target_start');
    my $target_end               = $c->request->param('target_end');

    my $min_3p_exon_flanks         = $c->request->param('min_3p_exon_flanks');
    my $min_5p_exon_flanks         = $c->request->param('min_5p_exon_flanks');
    my $primer_length              = $c->request->param('primer_length');
    my $retrieval_primer_length_3p = $c->request->param('retrieval_primer_length_3p');
    my $retrieval_primer_length_5p = $c->request->param('retrieval_primer_length_5p');
    my $retrieval_primer_offset_3p = $c->request->param('retrieval_primer_offset_3p');
    my $retrieval_primer_offset_5p = $c->request->param('retrieval_primer_offset_5p');
    my $score                      = $c->request->param('score');
    my $split_5p_target_seq_length = $c->request->param('split_5p_target_seq_length');
    my $split_3p_target_seq_length = $c->request->param('split_3p_target_seq_length');
    my @selected_projects          = $c->request->param('projects');
    my $selected_projects          = \@selected_projects;

    # store in design_info
    $design_info->{subtype}                    = $subtype;
    $design_info->{subtype_description}        = $subtype_description;
    $design_info->{min_3p_exon_flanks}         = $min_3p_exon_flanks;
    $design_info->{min_5p_exon_flanks}         = $min_5p_exon_flanks;
    $design_info->{primer_length}              = $primer_length;
    $design_info->{retrieval_primer_length_3p} = $retrieval_primer_length_3p;
    $design_info->{retrieval_primer_length_5p} = $retrieval_primer_length_5p;
    $design_info->{retrieval_primer_offset_3p} = $retrieval_primer_offset_3p;
    $design_info->{retrieval_primer_offset_5p} = $retrieval_primer_offset_5p;
    $design_info->{split_5p_target_seq_length} = $split_5p_target_seq_length;
    $design_info->{split_3p_target_seq_length} = $split_3p_target_seq_length;
    $design_info->{score}                      = $score;
    $design_info->{gene_build}                 = $gene_build;
    $design_info->{selected_gene_build_gene}   = $gene_build_gene;
    $design_info->{selected_projects}          = $selected_projects;
    $design_info->{start_exon}                 = $start_exon;
    $design_info->{end_exon}                   = $end_exon;
    $design_info->{target_start}               = $target_start;
    $design_info->{target_end}                 = $target_end;
    $design_info->{created_user}               = $created_user;
    $design_info->{message}                    = "";                            #store error message
    my $design;

    if (!(     $gene_build
            && $gene_build_gene
            && $start_exon
            && $end_exon
            && $target_start
            && $target_end
            && $min_3p_exon_flanks
            && $min_5p_exon_flanks
            && $primer_length
            && $retrieval_primer_length_3p
            && $retrieval_primer_length_5p
            && $retrieval_primer_offset_3p
            && $retrieval_primer_offset_5p
            && $split_5p_target_seq_length
            && $split_3p_target_seq_length
            && $created_user
        )
        )
    {
        $design_info->{message} = "All parameters must be specified (and numeric parameters must be greater than zero)";
    }
    else {
        if ( !$self->is_a_number( $c, $target_start ) ) {
            $design_info->{message} = "Target start ($target_start) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $target_end ) ) {
            $design_info->{message} = "Target end ($target_end) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_5p_exon_flanks ) ) {
            $design_info->{message} = "Min 5 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_3p_exon_flanks ) ) {
            $design_info->{message} = "Min 3 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_5p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_5p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_3p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_3p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $primer_length ) ) {
            $design_info->{message} = "Primer length ($primer_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_3p ) ) {
            $design_info->{message} = "3' Retrieval arm length ($retrieval_primer_length_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_5p ) ) {
            $design_info->{message} = "5' Retrieval arm length ($retrieval_primer_length_5p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_3p ) ) {
            $design_info->{message} = "3' Retrieval block size ($retrieval_primer_offset_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_5p ) ) {
            $design_info->{message} = "5' Retrieval block size ($retrieval_primer_offset_5p) isn't a valid number";
        }
        else {

            #
            #recover the start/end exon-ids from the gene-build, gbg and exon names
            # Note - this will feed the 'right' exon-ids back - in the event the start and end exons
            # are different, we will get back the exon nearest the U cassette.
            #
            my $time = $self->get_time;
            $c->log->debug("$time : creating design: fetching gene build and exon ids");

            my ( $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id, $chr_name, $chr_strand )
                = $self->get_gene_build_and_exon_ids( $c, $gene_build, $gene_build_gene, $start_exon, $end_exon );

            unless ($gene_build_id) {
                $c->log->warn("failed to retrieve target gene/exons for $gene_build");
                $design_info->{message} = "failed to retrieve target gene/exons from build $gene_build";
                return ( undef, $design_info );
            }

            $time = $self->get_time;
            $c->log->debug("$time : got gene_build_id: $gene_build_id and exonids: $start_exon_id - $end_exon_id");

            my $parameter_string
                = qq[min_3p_exon_flanks=$min_3p_exon_flanks,min_5p_exon_flanks=$min_5p_exon_flanks,primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,split_5p_target_seq_length=$split_5p_target_seq_length,split_3p_target_seq_length=$split_3p_target_seq_length,score=$score
      ];

            # create design_parameter
            my $design_parameter = $self->create_design_parameter( $c, $parameter_string );

            $time = $self->get_time;
            $c->log->debug("$time : Created design parameter: creating design");

            my $design_type = "Del_Block";

            # create design record
            $design = $self->create_design(
                $c,           $gene_build_id,       $start_exon_id, $end_exon_id,
                $assembly_id, $chr_name,            $target_start,  $target_end,
                $chr_strand,  $design_parameter,    $created_user,  $design_type,
                $subtype,     $subtype_description, $artificial_intron_design
            );
        }
    }

    if ( $design_info->{message} ne "" ) {
        return ( undef, $design_info );
    }
    else {
        return ( $design, $design_info );
    }

}

sub create_design_for_Insertion_Block_Specified {
    my ( $self, $c ) = @_;
    my $design_info;

    # read parameters
    my $artificial_intron_design = $c->request->param('artificial_intron_design');
    my $subtype                  = $c->request->param('subtype');
    my $subtype_description      = $c->request->param('subtype_description');
    my $created_user             = $self->check_authorised($c);
    my $gene_build               = $c->request->param('gene_build');
    my $gene_build_gene          = $c->request->param('selected_gene_build_gene');
    my $start_exon               = $c->request->param('start_exon');
    my $target_start             = $c->request->param('target_start');
    my $target_end               = $c->request->param('target_end');

    my $min_5p_exon_flanks         = $c->request->param('min_5p_exon_flanks');
    my $primer_length              = $c->request->param('primer_length');
    my $retrieval_primer_length_3p = $c->request->param('retrieval_primer_length_3p');
    my $retrieval_primer_length_5p = $c->request->param('retrieval_primer_length_5p');
    my $retrieval_primer_offset_3p = $c->request->param('retrieval_primer_offset_3p');
    my $retrieval_primer_offset_5p = $c->request->param('retrieval_primer_offset_5p');
    my $score                      = $c->request->param('score');
    my $split_5p_target_seq_length = $c->request->param('split_5p_target_seq_length');
    my $split_3p_target_seq_length = $c->request->param('split_3p_target_seq_length');
    my @selected_projects          = $c->request->param('projects');
    my $selected_projects          = \@selected_projects;

    # store in design_info
    $design_info->{subtype}                    = $subtype;
    $design_info->{subtype_description}        = $subtype_description;
    $design_info->{min_5p_exon_flanks}         = $min_5p_exon_flanks;
    $design_info->{primer_length}              = $primer_length;
    $design_info->{retrieval_primer_length_3p} = $retrieval_primer_length_3p;
    $design_info->{retrieval_primer_length_5p} = $retrieval_primer_length_5p;
    $design_info->{retrieval_primer_offset_3p} = $retrieval_primer_offset_3p;
    $design_info->{retrieval_primer_offset_5p} = $retrieval_primer_offset_5p;
    $design_info->{split_5p_target_seq_length} = $split_5p_target_seq_length;
    $design_info->{split_3p_target_seq_length} = $split_3p_target_seq_length;
    $design_info->{score}                      = $score;
    $design_info->{gene_build}                 = $gene_build;
    $design_info->{selected_gene_build_gene}   = $gene_build_gene;
    $design_info->{selected_projects}          = $selected_projects;

    $design_info->{start_exon}   = $start_exon;
    $design_info->{target_start} = $target_start;
    $design_info->{target_end}   = $target_end;
    $design_info->{created_user} = $created_user;
    $design_info->{message}      = "";              #store error message
    my $design;

    if (!(     $gene_build
            && $gene_build_gene
            && $start_exon
            && $target_start
            && $target_end
            && $min_5p_exon_flanks
            && $primer_length
            && $retrieval_primer_length_3p
            && $retrieval_primer_length_5p
            && $retrieval_primer_offset_3p
            && $retrieval_primer_offset_5p
            && $split_5p_target_seq_length
            && $split_3p_target_seq_length
            && $created_user
        )
        )
    {
        $design_info->{message} = "All parameters must be specified (and numeric parameters must be greater than zero)";
    }
    else {
        if ( !$self->is_a_number( $c, $target_start ) ) {
            $design_info->{message} = "Target start ($target_start) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $target_end ) ) {
            $design_info->{message} = "Target end ($target_end) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $min_5p_exon_flanks ) ) {
            $design_info->{message} = "Min 5 prime Spacer ($min_5p_exon_flanks) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_5p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_5p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $split_3p_target_seq_length ) ) {
            $design_info->{message} = "Block size ($split_3p_target_seq_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $primer_length ) ) {
            $design_info->{message} = "Primer length ($primer_length) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_3p ) ) {
            $design_info->{message} = "3' Retrieval arm length ($retrieval_primer_length_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_5p ) ) {
            $design_info->{message} = "5' Retrieval arm length ($retrieval_primer_length_5p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_3p ) ) {
            $design_info->{message} = "3' Retrieval block size ($retrieval_primer_offset_3p) isn't a valid number";
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_5p ) ) {
            $design_info->{message} = "5' Retrieval block size ($retrieval_primer_offset_5p) isn't a valid number";
        }
        else {

            #
            #recover the start/end exon-ids from the gene-build, gbg and exon names
            # Note - this will feed the 'right' exon-ids back - in the event the start and end exons
            # are different, we will get back the exon nearest the U cassette.
            #
            my $time = $self->get_time;
            $c->log->debug("$time : creating design: fetching gene build and exon ids");

            my ( $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id, $chr_name, $chr_strand )
                = $self->get_gene_build_and_exon_ids( $c, $gene_build, $gene_build_gene, $start_exon );

            unless ($gene_build_id) {
                $c->log->warn("failed to retrieve target gene/exons for $gene_build");
                $design_info->{message} = "failed to retrieve target gene/exons from build $gene_build";
                return ( undef, $design_info );
            }

            $time = $self->get_time;
            $c->log->debug("$time : got gene_build_id: $gene_build_id and exonids: $start_exon_id - $end_exon_id");

            my $parameter_string
                = qq[min_5p_exon_flanks=$min_5p_exon_flanks,primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,split_5p_target_seq_length=$split_5p_target_seq_length,split_3p_target_seq_length=$split_3p_target_seq_length,score=$score];

            # create design_parameter
            my $design_parameter = $self->create_design_parameter( $c, $parameter_string );

            $time = $self->get_time;
            $c->log->debug("$time : Created design parameter: creating design");

            my $design_type = "Ins_Block";

            # create design record
            $design = $self->create_design(
                $c,           $gene_build_id,       $start_exon_id, $end_exon_id,
                $assembly_id, $chr_name,            $target_start,  $target_end,
                $chr_strand,  $design_parameter,    $created_user,  $design_type,
                $subtype,     $subtype_description, $artificial_intron_design
            );
        }
    }

    if ( $design_info->{message} ne "" ) {
        return ( undef, $design_info );
    }
    else {
        return ( $design, $design_info );
    }
}

sub create_design_for_KO_Location_Specified {
    my ( $self, $c ) = @_;

    $c->log->debug("create_design_for_KO_Location_Specified");

    my %design_info = (
        artificial_intron_design   => $c->request->param('artificial_intron_design'),
        design_type                => 'KO_Location',
        subtype                    => $c->request->param('subtype'),
        created_user               => $self->check_authorised($c),
        gene_build                 => $c->request->param('gene_build'),
        selected_gene_build_gene   => $c->request->param('selected_gene_build_gene'),
        start_exon                 => $c->request->param('start_exon'),
        end_exon                   => $c->request->param('end_exon'),
        cassette_start             => $c->request->param('cassette_start'),
        cassette_end               => $c->request->param('cassette_end'),
        loxp_start                 => $c->request->param('loxp_start'),
        loxp_end                   => $c->request->param('loxp_end'),
        primer_length              => $c->request->param('primer_length'),
        retrieval_primer_length_3p => $c->request->param('retrieval_primer_length_3p'),
        retrieval_primer_length_5p => $c->request->param('retrieval_primer_length_5p'),
        retrieval_primer_offset_3p => $c->request->param('retrieval_primer_offset_3p'),
        retrieval_primer_offset_5p => $c->request->param('retrieval_primer_offset_5p'),
        score                      => $c->request->param('score'),
        selected_projects          => [ $c->request->param('projects') ],
    );

    for my $k ( keys %design_info ) {
        unless ( $design_info{$k} ) {
            $c->log->warn("$k must be specified");
            $design_info{message} = "$k must be specified";
            return ( undef, \%design_info );
        }
    }

    for my $k (
        qw( cassette_start cassette_end loxp_start loxp_end primer_length
        retrieval_primer_length_3p retrieval_primer_length_5p
        retrieval_primer_offset_3p retrieval_primer_offset_5p )
        )
    {
        unless ( $design_info{$k} =~ /^\d+$/ ) {
            $c->log->warn("$_ is not a valid number");
            $design_info{message} = "$_ is not a valid number";
            return ( undef, \%design_info );
        }
    }

    if ( $design_info{cassette_start} < $design_info{loxp_end} ) {

        # positive strand
        $design_info{target_start} = $design_info{cassette_end};
        $design_info{target_end}   = $design_info{loxp_start};
    }
    else {

        # negative strand
        $design_info{target_start} = $design_info{loxp_end};
        $design_info{target_end}   = $design_info{cassette_start};
    }

    $c->log->debug( Dumper( \%design_info ) );

    my $parameter_string = join q{,}, map "$_=$design_info{$_}", qw( primer_length
        retrieval_primer_length_3p retrieval_primer_length_5p
        retrieval_primer_offset_3p retrieval_primer_offset_5p
        score cassette_start cassette_end loxp_start loxp_end
    );

    $c->log->debug("Parameter string: $parameter_string");

    @design_info{qw( gene_build_id start_exon_id end_exon_id assembly_id chr_name chr_strand )}
        = $self->get_gene_build_and_exon_ids( $c,
        @design_info{qw( gene_build selected_gene_build_gene start_exon end_exon )} );

    unless ( $design_info{gene_build_id} ) {
        $c->log->warn("failed to retrieve gene_build_id/exons for $design_info{gene_build}");
        $design_info{message} = "failed to retrieve target gene from build $design_info{gene_build}";
        return ( undef, \%design_info );
    }

    # create design_parameter
    $design_info{design_parameter} = $self->create_design_parameter( $c, $parameter_string );

    # create design record
    my $design = $self->create_design(
        $c,
        @design_info{
            qw( gene_build_id    start_exon_id end_exon_id assembly_id
                chr_name         target_start  target_end  chr_strand
                design_parameter created_user  design_type
                subtype          subtype_description
                artificial_intron_design)
            }
    );

    my $u5_oligo_loc = create_U5_oligo_loc_from_cassette_coords( $design_info{ cassette_start }, $design_info{ cassette_end }, $design_info{ chr_strand } );
    my $transcript_id = $c->model( 'HTGTDB::GnmExon' )->find( { id => $design_info{ start_exon_id } } )->transcript->primary_name;
    my $design_phase = get_phase_from_transcript_id_and_U5_oligo( $transcript_id, $u5_oligo_loc );

    $design->update( {
        phase => $design_phase,
    } );

    return ( $design, \%design_info );
}

sub create_design_for_InsDel_Location_Specified {
    my ( $self, $c ) = @_;
    my $design_info;

    # read parameters
    my $artificial_intron_design = $c->request->param('artificial_intron_design');
    my $subtype                  = $c->request->param('subtype');
    my $subtype_description      = $c->request->param('subtype_description');
    my $created_user             = $self->check_authorised($c);
    my $gene_build               = $c->request->param('gene_build');
    my $gene_build_gene          = $c->request->param('selected_gene_build_gene');
    my $start_exon               = $c->request->param('start_exon');
    my $end_exon                 = $c->request->param('end_exon');

    my $start = $c->request->param('start');
    my $end   = $c->request->param('end');

    my $primer_length              = $c->request->param('primer_length');
    my $retrieval_primer_length_3p = $c->request->param('retrieval_primer_length_3p');
    my $retrieval_primer_length_5p = $c->request->param('retrieval_primer_length_5p');
    my $retrieval_primer_offset_3p = $c->request->param('retrieval_primer_offset_3p');
    my $retrieval_primer_offset_5p = $c->request->param('retrieval_primer_offset_5p');
    my $score                      = $c->request->param('score');

    my @selected_projects = $c->request->param('projects');
    my $selected_projects = \@selected_projects;

    # store in design_info
    $design_info->{subtype}             = $subtype;
    $design_info->{subtype_description} = $subtype_description;
    $design_info->{design_type}         = $c->request->param('design_type');
    $design_info->{target_start}        = $start;
    $design_info->{target_end}          = $end;

    $design_info->{primer_length}              = $primer_length;
    $design_info->{retrieval_primer_length_3p} = $retrieval_primer_length_3p;
    $design_info->{retrieval_primer_length_5p} = $retrieval_primer_length_5p;
    $design_info->{retrieval_primer_offset_3p} = $retrieval_primer_offset_3p;
    $design_info->{retrieval_primer_offset_5p} = $retrieval_primer_offset_5p;

    $design_info->{score}                    = $score;
    $design_info->{gene_build}               = $gene_build;
    $design_info->{selected_gene_build_gene} = $gene_build_gene;
    $design_info->{selected_projects}        = $selected_projects;

    $design_info->{start_exon}   = $start_exon;
    $design_info->{end_exon}     = $end_exon;
    $design_info->{created_user} = $created_user;
    $design_info->{message}      = "";              #store error message
    my $design;

    if (!(     $gene_build
            && $gene_build_gene
            && $start_exon
            && $end_exon
            && $start
            && $end
            && $primer_length
            && $retrieval_primer_length_3p
            && $retrieval_primer_length_5p
            && $retrieval_primer_offset_3p
            && $retrieval_primer_offset_5p
            && $created_user
        )
        )
    {
        $design_info->{message} = "All parameters must be specified (and numeric parameters must be greater than zero)";
        $c->log->debug("All parameters must be specified (and numeric parameters must be greater than zero)");
    }
    else {
        if ( !$self->is_a_number( $c, $start ) ) {
            $design_info->{message} = "Insertion/Deletion start ($start) isn't a valid number";
            $c->log->debug("start not valid");
        }
        elsif ( !$self->is_a_number( $c, $end ) ) {
            $design_info->{message} = "Insertion/Deletion end ($end) isn't a valid number";
            $c->log->debug("end not valid");
        }
        elsif ( !$self->is_a_number( $c, $primer_length ) ) {
            $design_info->{message} = "Primer length ($primer_length) isn't a valid number";
            $c->log->debug("primer not valid");
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_3p ) ) {
            $design_info->{message} = "3' Retrieval arm length ($retrieval_primer_length_3p) isn't a valid number";
            $c->log->debug("retrieval primer length 3p not valid");
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_length_5p ) ) {
            $design_info->{message} = "5' Retrieval arm length ($retrieval_primer_length_5p) isn't a valid number";
            $c->log->debug("retrieval primer length 5p not valid");
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_3p ) ) {
            $design_info->{message} = "3' Retrieval block size ($retrieval_primer_offset_3p) isn't a valid number";
            $c->log->debug("retrieval primer offset 3p not valid");
        }
        elsif ( !$self->is_a_number( $c, $retrieval_primer_offset_5p ) ) {
            $design_info->{message} = "5' Retrieval block size ($retrieval_primer_offset_5p) isn't a valid number";
            $c->log->debug("retrieval primer offset 5p not valid");
        }
        else {

            #
            #recover the start/end exon-ids from the gene-build, gbg and exon names
            # Note - this will feed the 'right' exon-ids back - in the event the start and end exons
            # are different, we will get back the exon nearest the U cassette.
            #
            $c->log->debug("parameters checked.");
            my $time = $self->get_time;
            $c->log->debug("$time : creating design: fetching gene build and exon ids");

            my ( $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id, $chr_name, $chr_strand )
                = $self->get_gene_build_and_exon_ids( $c, $gene_build, $gene_build_gene, $start_exon, $end_exon );

            unless ($gene_build_id) {
                $c->log->warn("failed to retrieve target gene/exons for $gene_build");
                $design_info->{message} = "failed to retrieve target gene/exons from build $gene_build";
                return ( undef, $design_info );
            }

            $time = $self->get_time;
            $c->log->debug("$time : got gene_build_id: $gene_build_id and exonids: $start_exon_id - $end_exon_id");

            # no need to store start & end in the parameters
            my $parameter_string
                = qq[primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,score=$score
      ];

            $c->log->debug($parameter_string);

            my $design_type;
            if ( $design_info->{design_type} eq "Deletion" ) {
                $design_type = "Del_Location";
            }
            elsif ( $design_info->{design_type} eq "Insertion" ) {
                $design_type = "Ins_Location";
            }
            else {
                $design_info->{message} = "Design type must be Knockout first, Deletion or Insertion";
                return ( undef, $design_info );
            }

            # create design_parameter
            my $design_parameter = $self->create_design_parameter( $c, $parameter_string );

            $time = $self->get_time;
            $c->log->debug("$time : Created design parameter: creating design");

            # create design record
            $design = $self->create_design(
                $c,           $gene_build_id,       $start_exon_id, $end_exon_id,
                $assembly_id, $chr_name,            $start,         $end,
                $chr_strand,  $design_parameter,    $created_user,  $design_type,
                $subtype,     $subtype_description, $artificial_intron_design
            );
        }
    }

    if ( $design_info->{message} ne "" ) {
        return ( undef, $design_info );
    }
    else {
        return ( $design, $design_info );
    }
}

sub start_design_run : Local {
    my ( $self, $c, $design_id ) = @_;

    my $designserver = HTGT::Utils::Design::DesignServer->new();
    $designserver->design_only( $c, $design_id );

    # add a status here.
    # need to update previous status first
    $c->model('HTGTDB::DesignStatus')->search( { design_id => $design_id } )->update( { is_current => 0 } );
    my $design_status = $c->model('HTGTDB::DesignStatus')->update_or_create(
        {   design_id        => $design_id,
            design_status_id => 2,
            is_current       => 1
        }
    );
}

sub create_design_info_from_stored_design : Private {
    my ( $self, $c, $design, $oligo_strand ) = @_;
    if ( !$design ) {
        $c->log->debug("Design passed in NOT defined!");
        return;
    }
    if ( !$oligo_strand ) {
        $oligo_strand = 'forward';
    }

    my $sort_order = {
        'G5'    => 1,
        'U5'    => 2,
        'U3'    => 3,
        'D5'    => 4,
        'D3'    => 5,
        'G3'    => 6,
        'G5_U5' => 7,
        'U3_D5' => 8,
        'D3_G3' => 9,
        'U5_15' => 9.2,
        'D3_15' => 9.7,
        'GF1'   => 10,
        'GF2'   => 11,
        'GF3'   => 12,
        'GF4'   => 13,
        'EX5'   => 14,
        'EX52'  => 15,
        'EX3'   => 16,
        'EX32'  => 17,
        'GR1'   => 18,
        'GR2'   => 19,
        'GR3'   => 20,
        'GR4'   => 21
    };

    my $design_info;
    my $design_parameter_string = $design->design_parameter->parameter_value;
    my @pieces = split /,/, $design_parameter_string;
    my %parameters;

    $design_info->{oligo_strand} = $oligo_strand;

    foreach my $piece (@pieces) {
        my ( $key, $value ) = split /=/, $piece;
        $parameters{$key} = $value;

# process multi_region_offset_shim & split_target_seq_length, bsc these are previous params name, need to transfer to new param name to display
        if ( $key eq 'multi_region_offset_shim' ) {
            $design_info->{multi_region_5p_offset_shim} = $value;
            $design_info->{multi_region_3p_offset_shim} = $value;

        }
        elsif ( $key eq 'split_target_seq_length' ) {
            $design_info->{split_5p_target_seq_length} = $value;
            $design_info->{split_3p_target_seq_length} = $value;
        }
        else {
            $design_info->{$key} = $value;
        }

        $c->log->debug("recovered parameter: $key: $value");
    }

    $design_info->{design_id} = $design->design_id;
    if ( $design->gene_build ) {
        $design_info->{gene_build} = $design->gene_build->version . ":" . $design->gene_build->name;
    }

    eval {
        if ( $design->start_exon )
        {
            $design_info->{start_exon} = $design->start_exon->primary_name;
        }
        if ( $design->end_exon ) {
            $design_info->{end_exon} = $design->end_exon->primary_name;
        }
        $design_info->{chr_strand} = $design->locus->chr_strand;
    };

    # check chr_strand and decide target_start is chr_start or chr_end;
    # also need to get del_or_ins_start & end
    if ( $design->locus ) {
        if ( $design->locus->chr_strand == 1 ) {
            $design_info->{target_start} = $design->locus->chr_start;
            $design_info->{target_end}   = $design->locus->chr_end;
        }
        elsif ( $design->locus->chr_strand == -1 ) {
            $design_info->{target_start} = $design->locus->chr_end;
            $design_info->{target_end}   = $design->locus->chr_start;
        }
        $design_info->{chr_name} = $design->locus->chr_name;
    }
    if ( $design->start_exon ) {
        $design_info->{selected_gene_build_gene} = $design->start_exon->transcript->gene_build_gene->primary_name;
    }
    $design_info->{created_user} = $design->created_user;

    # design_type & desertion type
    $design_info->{design_type} = $design->design_type;

    # get the info of validated_by_annotation
    $design_info->{validated_by_annotation} = $design->validated_by_annotation;

    if ( $design_info->{validated_by_annotation} eq "" ) {
        $design_info->{validated_by_annotation} = "not done";
    }

    # if there is no design type(ie existing designs), that is treated as KO.
    unless ( $design_info->{design_type} ) {
        $design_info->{design_type}         = "Knockout first";
        $design_info->{oligo_select_method} = "Block Specified";
    }

    # get subtype & subtype info
    $design_info->{subtype}             = $design->subtype;
    $design_info->{subtype_description} = $design->subtype_description;

    # get design comments
    my @comments = $design->design_user_comments;
    $design_info->{design_comments} = \@comments;

    $design_info->{artificial_intron_design} = 'No';
    my $art_intron_design_category
        = $c->model('HTGTDB::DesignUserCommentCategories')->find( { category_name => 'Artificial intron design' } );
    for my $des_comment (@comments) {
        if ( $des_comment->category_id == $art_intron_design_category->category_id ) {
            $design_info->{artificial_intron_design} = 'Yes';
        }
    }

    my $design_status = $design->design_statuses->first;

    my @statuses = $design->design_statuses->search( is_current => 1 );
    my $status = $statuses[0];

    if ($status) {
        $design_info->{status} = $status->design_status_dict->description;
    }

    my $bac_string;
    my @design_bacs = $design->design_bacs;
    foreach my $design_bac (@design_bacs) {
        $bac_string .= $design_bac->bac->remote_clone_id . " : ";
    }
    $design_info->{bac_string} = $bac_string;
    
    my $feature_arref = [];
    my @features      = $design->features;
    foreach my $feature (@features) {
        my $name = $feature->feature_type->description;
        my $validated;
        my $seq;
        my $start;
        my $end;
        my $length;

        $start  = $feature->feature_start;
        $end    = $feature->feature_end;
        $length = $end - $start + 1;

        my @feature_data = $feature->feature_data;
        foreach my $datum (@feature_data) {

        #$c->log->debug("retrieved feature data: ".$datum->feature_data_type->description." value: ".$datum->data_item);
            my $datum_type = $datum->feature_data_type;
            if ( $datum_type->description eq 'validated' && $datum->data_item == 1 ) {
                $validated = 1;
            }
            if ( $datum_type->description eq 'sequence' ) {
                $seq = $datum->data_item;
            }
        }

        if ($validated) {
            my $datum_ref;
            $datum_ref->{start}  = $start;
            $datum_ref->{end}    = $end;
            $datum_ref->{length} = $length;
            $datum_ref->{name}   = $name;
            $datum_ref->{id}     = $feature->feature_id;
            if ( $oligo_strand eq 'forward' ) {

                $datum_ref->{seq} = $seq;

            }
            elsif ( $oligo_strand eq 'ordered' ) {

                if ( $design->locus->chr_strand == 1 ) {
                    if ( ( $name eq 'G5' ) || ( $name eq 'U3' ) || ( $name eq 'D3' ) ) {
                        $datum_ref->{seq} = $self->revcomp($seq);
                    }
                    else {
                        $datum_ref->{seq} = $seq;
                    }
                }
                elsif ( $design->locus->chr_strand == -1 ) {
                    if ( ( $name eq 'G3' ) || ( $name eq 'U5' ) || ( $name eq 'D5' ) ) {
                        $datum_ref->{seq} = $self->revcomp($seq);
                    }
                    else {
                        $datum_ref->{seq} = $seq;
                    }
                }
                else {
                    die "design strand: " . $design->locus->chr_strand . " not expected";
                }

            }
            else {
                die "oligo strand: $oligo_strand not expected";
            }
            $datum_ref->{sort_order} = $sort_order->{ $datum_ref->{name} };
            push @{$feature_arref}, $datum_ref;
        }
    }

    $c->log->debug( "feature arref has " . scalar(@$feature_arref) . " elements " );

    my @sorted_features = sort { $a->{sort_order} <=> $b->{sort_order} } @$feature_arref;
    $design_info->{features} = \@sorted_features;

    my $design_notes;
    foreach my $design_note ( sort { $a->design_note_id <=> $b->design_note_id } $design->design_notes ) {
        push @$design_notes, $design_note->note;
    }
    $design_info->{design_notes} = $design_notes;

    my $instance_arref;
    foreach my $instance ( $design->design_instances ) {
        my $plate           = $instance->plate;
        my $well            = $instance->well;
        my $instance_string = "Plate ${plate}: Well ${well}: BACs";
        foreach my $bac ( $instance->bacs ) {
            $instance_string .= " " . $bac->remote_clone_id;
        }
        push @$instance_arref, $instance_string;
    }
    $design_info->{instance_string_array} = $instance_arref;

    # Add info for display features on current genome build
    my $val_features_ref = [];
    my $val_features = $design->validated_display_features;
    while ( my ($type, $val_feature) = each(%$val_features) ){
    	my $feature_info;
    	$feature_info->{name} = $type;
        $feature_info->{start} = $val_feature->feature_start;
    	$feature_info->{end} = $val_feature->feature_end;
    	$feature_info->{length} = $feature_info->{end} - $feature_info->{start} + 1;
    	
    	# We get the sequence that was generated for the original feature
    	my $feature_id = $val_feature->feature_id;
    	my ($feature) = grep { $_->{id} == $feature_id } @{ $design_info->{features} };
    	$feature_info->{seq} = $feature->{seq};
    	
    	$feature_info->{sort_order} = $sort_order->{ $feature_info->{name} };
        push @{$val_features_ref}, $feature_info;
    }
    my @sorted_val_features = sort { $a->{sort_order} <=> $b->{sort_order} } @$val_features_ref;
    $design_info->{validated_features} = \@sorted_val_features;
    
    # add import_otter_gene flag to indicate whether the design is from import otter gene
    #if ($design_info->{status} eq "Created" && $design_info->{gene_build} eq "3:otter_flex") {
    #   $design_info->{import_otter_gene} = 1;
    #}

    return $design_info;
}

sub create_design_parameter : Private {
    my ( $self, $c, $parameter_string ) = @_;

    $c->log->debug("creating design parameter with parameter string: $parameter_string");
    my $design_parameter = $c->model('HTGTDB::DesignParameter')
        ->create( { parameter_name => 'custom knockout', parameter_value => $parameter_string } );

    return $design_parameter;
}

sub create_design {
    my ($self,        $c,           $gene_build_id,       $start_exon_id,
        $end_exon_id, $assembly_id, $chr_name,            $target_start,
        $target_end,  $chr_strand,  $design_parameter,    $created_user,
        $design_type, $subtype,     $subtype_description, $artificial_intron_design
    ) = @_;

    $c->log->debug("creating design... ");
    my $locus = $self->create_locus( $c, $assembly_id, $chr_name, $target_start, $target_end, $chr_strand );

    my $locus_id = $locus->id;

    $c->log->debug( "created locus " . $locus->id );

    my $design = $c->model('HTGTDB::Design')->create(
        {   start_exon_id       => $start_exon_id,
            end_exon_id         => $end_exon_id,
            gene_build_id       => $gene_build_id,
            locus_id            => $locus_id,
            design_parameter_id => $design_parameter->id,
            created_user        => $created_user,
            design_type         => $design_type,
            subtype             => $subtype,
            subtype_description => $subtype_description,
        }
    );

    $c->log->debug( "created design " . $design->design_id );

    my $design_status_dict = $c->model('HTGTDB::DesignStatusDict')->search( description => 'Created' )->first;

    if ( !$design_status_dict ) {
        $c->log->debug("Something is wrong - I cant locate a design_status_dict entry for 'Created'");
        return undef;
    }

    my $design_status = $c->model('HTGTDB::DesignStatus')->create(
        {   design_id        => $design->design_id,
            design_status_id => $design_status_dict->design_status_id,
            is_current       => 1
        }
    );

    if ( !$design_status ) {
        $c->log->debug("Something is wrong - I cant create a design_status");
        return undef;
    }

    $c->log->debug( "created design status " . $design_status->design_status_id );

    my $design_note_type = $c->model('HTGTDB::DesignNoteTypeDict')->search( { description => 'Info' } )->first;
    if ( !$design_note_type ) {
        $c->log->debug("Cant get a design-note-type of 'Info'");
        return undef;
    }
    else {
        $c->log->debug("Found design_note_type_dict entry with description 'Info'");
    }

    my $design_note = $c->model('HTGTDB::DesignNote')->create(
        {   design_note_type_id => $design_note_type->design_note_type_id,
            design_id           => $design->design_id,
            note                => 'Created'
        }
    );

    $c->log->debug("created design_note");

    if ( $artificial_intron_design eq 'Yes' ) {
        my $art_intron_design_category
            = $c->model('HTGTDB::DesignUserCommentCategories')->find( { category_name => 'Artificial intron design' } );
        if ( !$art_intron_design_category ) {
            $c->log->debug("Cannot find design user comment category 'Artifical intron design'");
            return undef;
        }
        my $design_comment = $c->model('HTGTDB::DesignUserComments')->create(
            {   design_id   => $design->design_id,
                category_id => $art_intron_design_category->category_id,
                edited_user => $c->user->id,
                visibility  => 'public',
            }
        );
    }
    return $design;
}

sub get_gene_build_list : Private {
    my ( $self, $c ) = @_;
    my @results = $c->model('HTGTDB::GnmGeneBuild')->search( { version => ['72.38'] }, { order_by => 'name' } );

    $c->log->debug( "Available gene builds: " . join( q{, }, map { $_->name } @results ) );

    return \@results;
}

sub create_locus : Private {
    my ( $self, $c, $assembly_id, $chr_name, $target_start, $target_end, $chr_strand ) = @_;

    # check target_start or target_end make sure chr_start < chr_end
    my $chr_start;
    my $chr_end;

    if ( $target_start > $target_end ) {
        $chr_start = $target_end;
        $chr_end   = $target_start;
    }
    else {
        $chr_start = $target_start;
        $chr_end   = $target_end;
    }
    my $locus = $c->model('HTGTDB::GnmLocus')->create(
        {   chr_name    => $chr_name,
            chr_start   => $chr_start,
            chr_end     => $chr_end,
            chr_strand  => $chr_strand,
            assembly_id => $assembly_id,
            type        => 'DESIGN'
        }
    );

    return $locus;
}

sub get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name : Private {
    my ( $self, $c, $gene_build_string, $primary_name ) = @_;
    $gene_build_string =~ /\s*(\S*)\s*:\s*(\S*)\s*/;
    my $version = $1;
    my $gbname  = $2;
    $c->log->debug(
        "In get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name: Recovered chosen version: $version and name $gbname"
    );
    my @gene_builds = $c->model('HTGTDB::GnmGeneBuild')->search( { version => $version } );
    my $gene_build;
    if ( scalar(@gene_builds) >= 1 ) {
        $gene_build = $gene_builds[0];
        $c->log->debug( "Found gene build with id: " . $gene_build->id );
    }
    else {
        $c->log->debug("Found NO gene build - returning");
        return undef;
    }
    my @gene_build_genes = $c->model('HTGTDB::GnmGeneBuildGene')->search(
        {   build_id     => $gene_build->id,
            primary_name => $primary_name
        }
    );

    # If we retrieved one gene then find all its distinct exons and sort them
    # by genomic start. Walk the resulting list and compose an arref with strings like
    # name : start/end to put back into the exon-dropdowns
    my %exon_hash;
    my $exon_name_list;
    my $chr_strand;

    # what about scalar(@gene_build_genes) >1 ????
    #if(scalar(@gene_build_genes) == 1){
    if ( scalar(@gene_build_genes) >= 1 ) {
        my $gb_gene = $gene_build_genes[0];
        $c->log->debug( "Found gbgene with id: " . $gb_gene->id );

        my @transcripts = $gb_gene->transcripts;
        foreach my $transcript (@transcripts) {
            my @exons = $transcript->exons;
            foreach my $exon (@exons) {
                $exon_hash{ $exon->primary_name } = $exon;
            }
        }

        $c->log->debug( "Found " . scalar( values %exon_hash ) . " exons to sort" );

        my @sorted_exons = sort { $a->locus->chr_start <=> $b->locus->chr_start } values %exon_hash;
        foreach my $exon (@sorted_exons) {
            $c->log->debug( $exon->primary_name . ":" . $exon->locus->chr_start . "-" . $exon->locus->chr_end );
            $chr_strand = $exon->locus->chr_strand;
            push
                @$exon_name_list,
                $exon->primary_name . ":" . $exon->locus->chr_start . "-" . $exon->locus->chr_end;
        }

        return ( $exon_name_list, $gb_gene->primary_name, $chr_strand );

    }
    else {
        $c->log->debug("Found no gene - returning");
        return undef;
    }
}

sub get_gene_build_and_exon_ids {
    my ( $self, $c, $gene_build_string, $primary_name, $start_exon_string, $end_exon_string ) = @_;
    my ( $gene_build, $gene ) = get_gene_build_and_gene( $self, $c, $gene_build_string, $primary_name );
    unless ( $gene_build and $gene ) {
        $c->log->error("failed to retrieve gene build gene: $gene_build_string / $primary_name");
        return;
    }

    $start_exon_string =~ /(\S*):.*/;
    my $start_exon_name = $1;
    $end_exon_string =~ /(\S*):.*/;
    my $end_exon_name = $1;

    $c->log->debug("isolated exon names: $start_exon_name - $end_exon_name");

    #my $start_exon_name = $start_exon_string;
    #my $end_exon_name = $end_exon_string;

    $c->log->debug( "retrieved build: " . $gene_build->id . " and gb gene: " . $gene->id . " from mig" );
    $c->log->debug( "start exon name:" . $start_exon_name );
    $c->log->debug( "end exon name:" . $end_exon_name );
    my %exon_hash;
    if ( $gene_build && $gene ) {
        my @transcripts = $gene->transcripts;
        foreach my $transcript (@transcripts) {
            my @exons = $transcript->exons;
            foreach my $exon (@exons) {
                $c->log->debug( "exon: " . $exon );
                if ( not exists $exon_hash{ $exon->primary_name } ) {
                    $c->log->debug("not exist");
                    $exon_hash{ $exon->primary_name } = $exon;
                }
                elsif ( $exon_hash{ $exon->primary_name }->id > $exon->id ) {
                    $c->log->debug("exist");
                    $exon_hash{ $exon->primary_name } = $exon;
                }
            }
        }
        $c->log->debug("end exon name: $exon_hash{$end_exon_name}");
        $c->log->debug("start exon name: $exon_hash{$start_exon_name}");
        my $chr_strand = $exon_hash{$end_exon_name}->locus->chr_strand;

        # This is the default position.
        $c->log->debug("start exon: $start_exon_name, end exon: $end_exon_name");
        my $start_exon_id = $exon_hash{$start_exon_name}->id;
        my $end_exon_id   = $exon_hash{$end_exon_name}->id;

        # The start exon must be always nearest the U casette. Make sure of this
        # by flipping them around if necessary.
        if ( $chr_strand == 1 ) {
            $c->log->debug( "Plus stranded comparison on exon starts: "
                    . $exon_hash{$start_exon_name}->locus->chr_start . " - "
                    . $exon_hash{$end_exon_name}->locus->chr_start );
            if ( $exon_hash{$start_exon_name}->locus->chr_start > $exon_hash{$end_exon_name}->locus->chr_start ) {
                $c->log->debug("Reversing");
                $start_exon_id = $exon_hash{$end_exon_name}->id;
                $end_exon_id   = $exon_hash{$start_exon_name}->id;
            }
        }
        else {
            $c->log->debug( "Neg stranded comparison on exon starts: "
                    . $exon_hash{$start_exon_name}->locus->chr_start . " - "
                    . $exon_hash{$end_exon_name}->locus->chr_start );
            if ( $exon_hash{$start_exon_name}->locus->chr_start < $exon_hash{$end_exon_name}->locus->chr_start ) {
                $c->log->debug("Reversing");
                $start_exon_id = $exon_hash{$end_exon_name}->id;
                $end_exon_id   = $exon_hash{$start_exon_name}->id;
            }
        }

        $c->log->debug( "start_exon_id:" . $start_exon_id );
        $c->log->debug( "end_exon_id:" . $end_exon_id );
        return (
            $gene_build->id, $start_exon_id, $end_exon_id, $gene_build->assembly_id,
            $exon_hash{$start_exon_name}->locus->chr_name,
            $exon_hash{$end_exon_name}->locus->chr_strand
        );
    }
    else {
        return;
    }
}

sub get_gene_build_and_gene : Private {
    my ( $self, $c, $gene_build_string, $primary_name ) = @_;
    $gene_build_string =~ /\s*(\S*)\s*:\s*(\S*)\s*/;
    my $version = $1;
    my $gbname  = $2;
    $c->log->debug("Recovered chosen version: $version and name $gbname");
    my @gene_builds = $c->model('HTGTDB::GnmGeneBuild')->search( { version => $version } );
    my $gene_build;
    if ( scalar(@gene_builds) == 1 ) {
        $gene_build = $gene_builds[0];
        $c->log->debug( "Found gene build with id: " . $gene_build->id );
    }
    else {
        $c->log->debug("Found NO corresponding gene build - returning");
        return;
    }

    $c->log->debug( "Searching for gbgene with build: " . $gene_build->id . " and name $primary_name" );
    my @genes = $c->model('HTGTDB::GnmGeneBuildGene')->search(
        {   build_id     => $gene_build->id,
            primary_name => $primary_name
        }
    );

    my $gene;

    ## what about more than one gene
    #if(scalar(@genes) == 1){
    if ( scalar(@genes) >= 1 ) {
        $gene = $genes[0];
        $c->log->debug( "Found gene with id: " . $gene->id );
    }
    else {
        $c->log->debug("Found NO corresponding gene - returning");
        return;
    }

    return ( $gene_build, $gene );
}

sub check_authorised : Private {
    my $self = shift;
    my $c    = shift;
    my $user = $c->user;
    if ($user) {
        return $user->id;
    }
    return undef;
}

sub revcomp : Private {
    my ( $self, $seq ) = @_;
    my $revseq = reverse($seq);
    $revseq =~ tr/ACGTacgt/TGCAtgca/;
    return $revseq;
}

sub is_a_number : Private {
    my ( $self, $c, $number ) = @_;

    #$c->log->debug("checking number for: $number");
    if ( $number =~ /^\d+$/ ) {
        return 1;
    }
    return 0;
}

sub get_time {
    my $c        = shift;
    my @months   = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ( $second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings )
        = localtime();
    my $year    = 1900 + $yearOffset;
    my $theTime = "$hour:$minute:$second, $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
    return $theTime;
}

sub trim : Private {
    my ( $self, $string ) = @_;
    return '' unless defined $string;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _design_comment_new : Local {
    my ( $self, $c ) = @_;

    my $design_id = $c->req->params->{design_id};
    my $default_category_id
        = $c->model('HTGTDB::DesignUserCommentCategories')->find( { category_name => 'Other' } )->category_id;

    $c->log->debug( "design id:" . $design_id );

    # create a new comment
    my $new_comment = $c->model('HTGTDB::DesignUserComments')->create(
        {   design_id      => $design_id,
            category_id    => $default_category_id,
            design_comment => '[Comment Text]',
            edited_user    => $c->user->id,
            visibility     => 'internal'
        }
    );

    # Get the design comments
    my @design_comments = $c->model('HTGTDB::Design')->find( { design_id => $design_id } )->design_user_comments;

    my $design_info;
    $design_info->{design_comments} = \@design_comments;
    $design_info->{design_id}       = $design_id;

    $c->stash->{design_info}    = $design_info;
    $c->stash->{timestamp}      = $c->req->params->{timestamp};
    $c->stash->{new_comment_id} = $new_comment->design_comment_id;
    $c->stash->{design_comment_categories}
        = [ $c->model('HTGTDB::DesignUserCommentCategories')->search( {}, { order_by => 'category_name' } ) ],
        $c->stash->{template} = 'design/_design_comment_table.tt';
    $c->forward('HTGT::View::NakedTT');
}

sub _design_comment_delete : Local {
    my ( $self, $c ) = @_;

    # look up design comment
    my $design_comment = $c->model('HTGTDB::DesignUserComments')
        ->find( { design_comment_id => $c->req->params->{design_comment_id} } );

    # save the id
    my $design_id = $design_comment->design_id;

    # delete the comment
    $design_comment->delete();

    my @design_comments = $c->model('HTGTDB::Design')->find( { design_id => $design_id } )->design_user_comments;

    my $design_info;
    $design_info->{design_comments} = \@design_comments;
    $design_info->{design_id}       = $design_id;

    $c->stash->{design_info} = $design_info;

    $c->stash->{timestamp} = $c->req->params->{timestamp};
    $c->stash->{template}  = 'design/_design_comment_table.tt';
    $c->forward('HTGT::View::NakedTT');
}

sub _design_comment_update : Local {
    my ( $self, $c ) = @_;

    # find the edited_user
    my $designComment = $c->model('HTGTDB::DesignUserComments')->find( { design_comment_id => $c->req->params->{id} } );
    my $edited_user   = $designComment->edited_user;
    my $design_id     = $designComment->design_id;

    my $error = sub {
        $c->res->body( sprintf( '<span style="color: red; font-weight: bold;">%s</span>', shift ) );
    };

    unless ( $edited_user eq $c->user->id or $c->check_user_roles("design") ) {
        return $error->("You are not authorised to update other's comment. Click 'refresh' button to go back.");
    }

    my $field = $c->req->params->{field};
    my $value = $self->trim( $c->req->params->{value} );

    if ( $c->req->params->{field} eq "design_comment" ) {
        $designComment->update(
            {   design_comment => $value,
                edited_user    => $c->user->id,
                edited_date    => \'current_timestamp'
            }
        );
        $c->res->body( $value || '[Comment Text]' );
    }
    elsif ( $c->req->params->{field} eq "visibility" ) {
        return $error->("Visibility must be 'internal' or 'public'")
            unless $value eq 'internal' or $value eq 'public';
        $designComment->update(
            {   visibility  => $value,
                edited_user => $c->user->id,
                edited_date => \'current_timestamp'
            }
        );
        $c->res->body($value);
    }
    elsif ( $c->req->params->{field} eq "category" ) {
        my $category = $c->model('HTGTDB::DesignUserCommentCategories')->find( { category_id => $value } )
            or return $error->("$value is not a valid category id");
        $designComment->update(
            {   category_id => $category->category_id,
                edited_user => $c->user->id,
                edited_date => \'current_timestamp'
            }
        );
        $c->res->body( $category->category_name );
    }
}

=head2

method for automatic finding suggested targets for a given ensembl id

=cut

sub find_target : Local {
    my ( $self, $c ) = @_;

    my $ensembl_id = $c->request->param('ensembl_id');
    my $type       = $c->request->param('type');

    my $gene_build = $c->request->param('gene_build');

    my ( $exon_list, $primary_name )
        = $self->get_exons_and_gene_build_gene_for_gene_build_string_and_primary_name( $c, $gene_build, $ensembl_id );

    # get the exon name only
    my @exons;

    foreach my $exon (@$exon_list) {
        my @exon_target = split /:/, $exon;
        my $exon = $exon_target[0];
        push @exons, $exon;
    }

    my @targets;

    if ( $type eq "frameshift" ) {
        my $standard_results;
        my $short_results;

        eval { $standard_results = HTGT::Controller::Design::TargetFinder->standard( $c, $ensembl_id ); };

        if ( $@ || $standard_results eq "" ) {
            $c->log->debug("error: $@ or no taget from standard!");

            # in this case, try to run short one
            eval {
                $short_results = HTGT::Controller::Design::TargetFinder->short( $c, $ensembl_id );

                # this is for debug only
                #use Data::Dumper;
                #print Dumper $short_results;
            };

            if ( $@ || $short_results eq "" ) {
                if ($@) {
                    $c->stash->{error_message} = $@;
                    $c->log->debug($@);
                }
                else {
                    $c->stash->{error_message} = "No targets found!";
                    $c->log->debug("no target from short either!");
                }

                # mark it as no result
                $c->stash->{result} = 0;
            }
            else {

                # process result short
                foreach my $result (@$short_results) {
                    my $target;

                    $target->{exon}      = $result->{start_exon} . "-" . $result->{end_exon};
                    $target->{start_end} = $result->{target_start} . "-" . $result->{target_end};

                    #get the target size
                    if ( $result->{target_start} > $result->{target_end} ) {
                        $target->{size} = $result->{target_start} - $result->{target_end};
                    }
                    else {
                        $target->{size} = $result->{target_end} - $result->{target_start};
                    }

                    # get the params
                    $target->{l_param} = $result->{l_param};
                    $target->{r_param} = $result->{r_param};

                    # get the exon rank
                    my $start_exon_rank;
                    my $end_exon_rank;

                    my $count = 0;
                    foreach my $exon (@exons) {
                        $count++;
                        if ( $result->{start_exon} eq $exon ) {
                            $start_exon_rank = $count;
                        }
                        if ( $result->{end_exon} eq $exon ) {
                            $end_exon_rank = $count;
                        }
                    }

                    $target->{rank} = "#" . $start_exon_rank . " - #" . $end_exon_rank;

                    push @targets, $target;

                    # short results doesn't have a score, mark it here
                    $c->stash->{short} = 1;
                }
            }
        }
        else {

            # process result from standard
            foreach my $result (@$standard_results) {
                my $target;

                $target->{exon}      = $result->{start_exon} . "-" . $result->{end_exon};
                $target->{start_end} = $result->{target_start} . "-" . $result->{target_end};
                $target->{score}     = $result->{score};

                #get the target size
                if ( $result->{target_start} > $result->{target_end} ) {
                    $target->{size} = $result->{target_start} - $result->{target_end};
                }
                else {
                    $target->{size} = $result->{target_end} - $result->{target_start};
                }

                # get the params

                $target->{l_param} = $result->{l_param};
                $target->{r_param} = $result->{r_param};

                # get the exon rank
                my $start_exon_rank;
                my $end_exon_rank;

                my $count = 0;
                foreach my $exon (@exons) {
                    $count++;
                    if ( $result->{start_exon} eq $exon ) {
                        $start_exon_rank = $count;
                    }
                    if ( $result->{end_exon} eq $exon ) {
                        $end_exon_rank = $count;
                    }
                }

                $target->{rank} = "#" . $start_exon_rank . " - #" . $end_exon_rank;

                push @targets, $target;
            }
        }

    }
    elsif ( $type eq "domain" ) {
        my $domain_results;

        eval { $domain_results = HTGT::Controller::Design::TargetFinder->domain( $c, $ensembl_id, 'everything' ); };
        if ($@) {
            $c->log->debug( "#Error from domain: " . $@ );
            $c->stash->{error_message} = $@;
            $c->stash->{result}        = 0;
        }
        else {
            if ( $domain_results eq "" ) {
                $c->log->debug("no taget!");
                $c->stash->{error_message} = "No targets found!";
                $c->stash->{result}        = 0;
            }
            else {
                foreach my $result (@$domain_results) {
                    my $target;

                    $target->{exon}                  = $result->{start_exon} . "-" . $result->{end_exon};
                    $target->{start_end}             = $result->{target_start} . "-" . $result->{target_end};
                    $target->{score}                 = $result->{score};
                    $target->{domain}                = $result->{domain};
                    $target->{displayed_domain_name} = $result->{displayed_domain_name};

                    #get the target size
                    if ( $result->{target_start} > $result->{target_end} ) {
                        $target->{size} = $result->{target_start} - $result->{targ3et_end};
                    }
                    else {
                        $target->{size} = $result->{target_end} - $result->{target_start};
                    }

                    # get the params
                    $target->{l_param} = $result->{l_param};
                    $target->{r_param} = $result->{r_param};

                    # get the exon rank
                    my $start_exon_rank;
                    my $end_exon_rank;

                    my $count = 0;
                    foreach my $exon (@exons) {
                        $count++;
                        if ( $result->{start_exon} eq $exon ) {
                            $start_exon_rank = $count;
                        }
                        if ( $result->{end_exon} eq $exon ) {
                            $end_exon_rank = $count;
                        }
                    }

                    $target->{rank} = "#" . $start_exon_rank . " - #" . $end_exon_rank;
                    push @targets, $target;
                }
            }
        }
    }

    # sort the targets
    my @sorted_targets = sort { $b->{score} <=> $a->{score} } @targets;

    $c->stash->{type}     = $type;
    $c->stash->{targets}  = \@sorted_targets;
    $c->stash->{template} = 'design/_target_result.tt';
}

=head1 AUTHOR

Vivek Iyer, Wanjuan Yang

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
