package HTGT::Controller::Design::DesignList;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

HTGT::Controller::Design::DesignList - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/design/designlist/list_designs') );
}

sub list_designs : Local {
    my ( $self, $c ) = @_;
    my $filter_info = {};
    my $designs;

    my $design_id        = $c->request->param('design_id');
    my $gene             = $c->request->param('gene');
    my $exon             = $c->request->param('exon');
    my $design_plate     = $c->request->param('design_plate');
    my $instance_plate   = $c->request->param('instance_plate');
    my $selected_group   = $c->request->param('selected_group');
    my $fulfills_request = $c->request->param('fulfills_request');
    my $comment          = $c->request->param('comment');

    #$c->log->debug("Selected design group: $selected_group");

    my @groups = sort { $a->name cmp $b->name } $c->model('HTGTDB::DesignGroup')->all;
    foreach my $group (@groups) {
        push @{ $filter_info->{groups} }, $group->name;
    }
    $filter_info->{design_id}        = $design_id;
    $filter_info->{gene}             = $gene;
    $filter_info->{exon}             = $exon;
    $filter_info->{design_plate}     = $design_plate;
    $filter_info->{instance_plate}   = $instance_plate;
    $filter_info->{selected_group}   = $selected_group;
    $filter_info->{fulfills_request} = $fulfills_request;
    $filter_info->{comment}          = $comment;

    my @tmp = @{ $filter_info->{groups} };

    #$c->log->debug("Loaded filter_info with groups: @tmp");

    $c->stash->{filter_info} = $filter_info;

    my $design_rows
        = $self->get_design_rows( $c, $design_id, $gene, $exon, $design_plate, $instance_plate, $selected_group,
        $fulfills_request, $comment );

    if ($design_rows) {
        $c->stash->{designs} = $design_rows;

        #$c->log->debug("Number of rows in design list: ".scalar(@$design_rows)."\n");
    }
    else {
        $design_rows = [];
    }

    $c->stash->{template} = 'design/list.tt';
}

sub get_design_rows : Private {
    my ($self,         $c,              $design_id,      $gene,             $exon,
        $design_plate, $instance_plate, $selected_group, $fulfills_request, $comment
    ) = @_;

    my $sql;
    my $sql_a;
    my $sql_b = "";
    my $sql_c = "";
    my $sql_d = "";
    my $sql_e = "";
    my $sql_f = "";
    my $sql_g = "";
    my $sql_h = "";

    if (   $design_id
        || $gene
        || $exon
        || $design_plate
        || $instance_plate
        || $selected_group
        || $fulfills_request
        || $comment )
    {
        $sql_a = qq/select distinct
    gnm_gene_build_gene.primary_name gbgene,
    exon1.primary_name start_exon,
    exon2.primary_name end_exon,
    coalesce(design.phase,exon1.phase) as phase,
    design_status_dict.description status,
    design.design_id as design_id,
    design.design_name,
    to_char(design_parameter.parameter_value) parameter_value,
    design.sp DESIGN_SP,
    design.tm DESIGN_TM,
    design.final_plate,
    design.created_date,
    design.well_loc,
    design_instance.plate,
    design_instance.well,
    mgi_gene.mgi_accession_id
    from
    design,
    design_status,
    design_status_dict,
    design_instance,
    design_parameter,
    mig.gnm_exon exon1,
    mig.gnm_exon exon2,
    mig.gnm_transcript,
    mig.gnm_gene_build_gene,
    project,
    mgi_gene
    where
    design.START_EXON_ID = exon1.ID
    and design.END_EXON_ID = exon2.ID
    and design.design_parameter_id = design_parameter.design_parameter_id
    and design.design_id = design_status.design_id and design_status.is_current = 1
    and design_status_dict.design_status_id = design_status.design_status_id
    and gnm_transcript.id = exon1.transcript_id
    and gnm_gene_build_gene.ID = gnm_transcript.build_gene_id
    and design.design_id = design_instance.design_id (+)
    and project.design_id (+) = design.design_id
    and mgi_gene.mgi_gene_id (+) = project.mgi_gene_id
    /;

        $sql .= $sql_a;

        my $re = "\'|\;|\:|insert|delete|update|drop|create|\(|\)|\|";

        # BECAUSE, FOR SOME REASON, PLACEHOLDERS WOULDN'T WORK I USE REs - NASTY.
        if ($design_plate) {
            $design_plate =~ s/$re//g;
            $sql_c = " and design.final_plate = '$design_plate' ";
        }
        if ($instance_plate) {
            $instance_plate =~ s/$re//g;
            $sql_d = " and design_instance.plate = '$instance_plate' ";
        }
        if ($gene) {
            $gene =~ s/$re//g;
            $sql_e = " and mig.gnm_gene_build_gene.primary_name = '$gene' ";
        }
        if ($exon) {
            $exon =~ s/$re//g;
            $sql_f = " and mig.exon1.primary_name = '$exon' ";
        }
        if ($design_id) {
            $design_id =~ s/$re//g;
            $sql_g = " and design.design_id = $design_id ";
        }
        if ($comment) {
            $comment =~ s/$re//g;
            $sql_h = " and parameter_value like '%$comment%' ";
        }

        $sql = $sql_a . $sql_b . $sql_c . $sql_d . $sql_e . $sql_f . $sql_g . $sql_h;

    }
    else {
        $sql = $sql_a;
        return undef;
    }

    my $sth = $c->model('HTGTDB')->schema()->storage()->dbh()->prepare($sql);
    $sth->execute();
    my @design_list;
    my $design;
    while ( my $result = $sth->fetchrow_hashref() ) {
        $design = $result;
        if ( $design->{START_EXON} eq $design->{END_EXON} ) {
            $design->{TARGET_STRING} = $design->{START_EXON};
        }
        else {
            $design->{TARGET_STRING} = $design->{START_EXON} . "-" . $design->{END_EXON};
        }

        my $parameter_value = $result->{PARAMETER_VALUE};
        my @pieces = split /,/, $parameter_value;
        my %parameters;
        foreach my $piece (@pieces) {
            my ( $key, $value ) = split /=/, $piece;
            $parameters{$key} = $value;
        }

        if ( $comment && !( $parameters{score} ) ) { next; }
        if ( $comment && !( $parameters{score} =~ /$comment/ ) ) { next; }

        $design->{COMMENT} = $parameters{score};

        # if design SP, TM is null, get the info from gene_info
        if ( $design->{DESIGN_SP} eq "" ) {
            $design->{SP} = $design->{GENE_SP};
        }
        else {
            $design->{SP} = $design->{DESIGN_SP};
        }

        if ( $design->{DESIGN_TM} eq "" ) {
            $design->{TM} = $design->{GENE_TM};
        }
        else {
            $design->{TM} = $design->{DESIGN_TM};
        }

        push @design_list, $design;

    }

    my @sorted_list
        = sort {
               ( $a->{FINAL_PLATE} <=> $b->{FINAL_PLATE} )
            || ( $a->{WELL_LOC} cmp $b->{WELL_LOC} )
            || ( $a->{PLATE} <=> $b->{PLATE} )
            || ( $a->{WELL} cmp $b->{WELL} )
            || ( $a->{SP} <=> $b->{SP} )
            || ( $a->{TM} <=> $b->{TM} )
            || ( $a->{ATG} <=> $b->{ATG} )
            || ( $a->{PHASE} <=> $b->{PHASE} )
            || ( $a->{PROMOTER} <=> $b->{PROMOTER} )
            || ( $a->{DESIGN_ID} <=> $b->{DESIGN_ID} )
        } @design_list;
    return \@sorted_list;
}

=head1 AUTHOR

Vivek Iyer

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
