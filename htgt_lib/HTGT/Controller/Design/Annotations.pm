package HTGT::Controller::Design::Annotations;
use Moose;
use namespace::autoclean;
use Smart::Comments;
use Try::Tiny;
use Data::Pageset;
use HTGT::Utils::DesignAnnotationSearch;
use HTGT::Utils::UpdateDesign::ProjectGene;
use Const::Fast;
use List::MoreUtils qw( uniq );
use HTGT::Constants qw(
        $DEFAULT_ANNOTATION_ASSEMBLY_ID
        $DEFAULT_ANNOTATION_BUILD_ID
        %ANNOTATION_ASSEMBLIES
        @ANNOTATION_BUILDS
    );

BEGIN { extends 'Catalyst::Controller'; }

const my %CHECK_TYPE_NAMES => (
    oligo_status_id             => 'Oligo',
    target_region_status_id     => 'Target Region',
    design_quality_status_id    => 'Design Quality',
    artificial_intron_status_id => 'Artificial Intron',
    final_status_id             => 'Final',
);

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{assembly_id} = $c->req->params->{assembly_id} || $DEFAULT_ANNOTATION_ASSEMBLY_ID;
    $c->stash->{build_id}    = $c->req->params->{build_id} || $DEFAULT_ANNOTATION_BUILD_ID;

    # need to re-map hash because of problem calling keys on const variable
    $c->stash->{assemblies}  = { map{ $_ => $ANNOTATION_ASSEMBLIES{$_}  } keys %ANNOTATION_ASSEMBLIES };
    $c->stash->{builds}     = \@ANNOTATION_BUILDS;
}

=head1 NAME

HTGT::Controller::Design::Annotations - Catalyst Controller

=head1 DESCRIPTION

Interface to design check information

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

}

=head2 design_annotation_summary

Summary of design annotation information

=cut

sub design_annotation_summary : Local :Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} = "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }

    my $design_annotations = $c->model('HTGTDB')->schema->resultset('DesignAnnotation')->search_rs(
        {
            assembly_id => $c->stash->{assembly_id},
            build_id    => $c->stash->{build_id},
        }
    );

    my @check_types = qw(
        oligo_status_id
        design_quality_status_id
        target_region_status_id
        artificial_intron_status_id
        final_status_id
    );

    my %results;
    while ( my $da = $design_annotations->next ) {
        for my $check_type ( @check_types ) {
            next unless $da->$check_type;
            $results{$check_type}{$da->$check_type}++;
        }
    }

    $c->stash->{results}          = \%results;
    $c->stash->{check_type_order} = \@check_types;
    $c->stash->{check_type_name}  = \%CHECK_TYPE_NAMES;
}

=head2 find_design_annotation

View design information stored for given design

=cut

sub find_design_annotation : Local {
    my ( $self, $c ) = @_;

    return unless $c->req->param('get_design_annotations');

    unless ( $c->req->param('input_data') ) {
        $c->stash->{error_msg} = 'No Data Entered';
        return;
    }
    $c->stash->{input_data} = $c->req->param('input_data');

    my $annotation_search = HTGT::Utils::DesignAnnotationSearch->new(
        schema      => $c->model('HTGTDB')->schema,
        input_data  => $c->req->param('input_data'),
        assembly_id => $c->stash->{assembly_id},
        build_id    => $c->stash->{build_id},
    );

    my $design_annotations = $annotation_search->find_annotations;

    if ( $annotation_search->has_errors ) {
        $self->_create_error_message( $c, $annotation_search->errors );
        return;
    }

    if ( @{ $design_annotations } ) {
        $c->stash->{design_annotations} = $self->_process_design_annotations( $design_annotations );
    }
    else {
        $c->stash->{error_msg} = 'No design annotations found for given designs / genes';
        $c->stash->{design_annotations} = [];
    }

    return;
}

sub _process_design_annotations : Private {
    my ( $self, $annotation_list ) = @_;

    my @design_annotations;
    for my $da ( @{ $annotation_list } ) {
        my %result = map{ $_ => $da->$_ } qw(
                design_id
                oligo_status_id
                design_quality_status_id
                target_region_status_id
                artificial_intron_status_id
                final_status_id
                build_id
                assembly_id
            );

        my $gene = try{ $da->design->projects->first->mgi_gene };

        $result{gene} = $gene->marker_symbol;

        push @design_annotations, \%result;
    }

    return \@design_annotations;
}

=head2 view_design_annotation

View design information stored for given design

=cut

sub view_design_annotation : Local  {
    my ( $self, $c ) = @_;

    if ( !$c->req->param('design_id') && !$c->req->param('design_annotation_id') ) {
        $c->stash->{error_msg} = "You must specify a design_id or a design_annotation_id";
        return;
    }
    $c->stash->{design_id} = $c->req->param('design_id');
    $c->stash->{assembly_id} = $c->req->param('assembly_id');
    $c->stash->{build_id} = $c->req->param('build_id');
    $c->stash->{design_annotation_id} = $c->req->param( 'design_annotation_id' );

    my $design_annotation_data = $self->_get_design_annotation_data( $c );
    return unless $design_annotation_data;

    $c->stash->{data} = $design_annotation_data;
    my @has = $c->model('HTGTDB')->schema->resultset('DaHumanAnnotationStatus')->all;
    $c->stash->{human_annotations} = [ map{ $_->human_annotation_status_id } @has ];

    $c->forward( 'add_human_annotation' ) if $c->req->param('add_human_annotation');
}

sub _get_design_annotation_data : Private {
    my ( $self, $c ) = @_;
    my %data;

    my $design_id   = $c->req->param('design_id');
    my $assembly_id = $c->stash->{assembly_id};
    my $build_id    = $c->stash->{build_id};
    my $design_annotation_id = $c->req->param( 'design_annotation_id' );

    my $search;
    if ( $design_annotation_id ) {
        $search = { design_annotation_id => $design_annotation_id };
    }
    else {
        $search = {
            assembly_id    => $assembly_id,
            build_id       => $build_id,
            'me.design_id' => $design_id,
        };
    }

    my $design_annotation = $c->model('HTGTDB')->schema->resultset('DesignAnnotation')->find(
        $search, { prefetch => 'design' } );

    unless ( $design_annotation ) {
        $c->stash->{error_msg} = "Design $design_id does not have design annotation data "
           .  "on assembly $assembly_id for build $build_id";
        return;
    }
    $data{da}                  = $design_annotation;
    $data{human_annotations}   = [ $design_annotation->human_annotations->all ];
    $data{target_region_genes} = [ $design_annotation->target_region_genes->all ];

    my @alt_annotations = $c->model('HTGTDB')->schema->resultset('DesignAnnotation')->search(
        {
            design_id => $design_id,
            -or => [
                assembly_id => { '!=' => $assembly_id },
                build_id    => { '!=' => $build_id },
            ]
        }
    );
    $data{alternate_das} =
        [ map{ { build_id => $_->build_id, assembly_id => $_->assembly_id } } @alt_annotations ];

    my $design      = $design_annotation->design;
    $data{design}   = $design;
    my @projects    = $design->projects->all;
    $data{projects} = \@projects;

    return \%data;
}

=head2 add_human_annotation

Adds human annotations

=cut
sub add_human_annotation : Local  {
    my ( $self, $c ) = @_;

    my $schema = $c->model('HTGTDB')->schema;
    my $design_annotation_id = $c->req->param('design_annotation_id');
    my $da = $schema->resultset('DesignAnnotation')->find(
        { 'design_annotation_id' => $design_annotation_id });
    my $design = $da->design;

    my $human_annotation_notes = "";
    my $human_annotation_status = "";
    $schema->txn_do(
        sub {
            try {
                if ( exists $c->req->params->{'change_project_gene'}){
                    my $project_updater = HTGT::Utils::UpdateDesign::ProjectGene->new(
                        schema               => $schema,
                        design               => $design,
                        new_mgi_accession_id => $c->req->param('correct_project_gene'),
                    );
                    $project_updater->update;

                    $human_annotation_notes = $project_updater->note("\n");
                    $human_annotation_status = 'change_the_design_projects_gene';
                }

                # Create human annnotation
                $da->create_related( 'human_annotations',
                    {
                        human_annotation_status_id          => $human_annotation_status,
                        design_check_status_notes           => $c->req->param('failed_test_notes'),
                        $c->req->param('failed_test_table') => $c->req->param('failed_test'),
                        human_annotation_status_notes       => $human_annotation_notes,
                        created_by                          => $c->user->id ,
                    }
                );

                $design->check_design( $da->assembly_id, $da->build_id );
            }
            catch {
                $schema->txn_rollback;
                $c->flash(error_msg => "Failed to create human annotation " . $_ );
            };
        }
    );

    $c->res->redirect(
        $c->uri_for(
            "/design/annotations/view_design_annotation",
            { 'design_annotation_id' => $design_annotation_id }
        )
    );
    return;
}

=head2 list_status_designs

Table listing all the designs with given status for given check type

=cut

sub list_status_designs : Local :Args(2) {
    my ( $self, $c, $check_type, $status ) = @_;

    my $design_annotation_resultsource = $c->model('HTGTDB')->schema->source('DesignAnnotation');

    unless ( $design_annotation_resultsource->has_column($check_type) ){
        $c->stash->{error_msg} = "Unrecognised column $check_type";
        return;
    }

    $c->stash->{check_type_name} = \%CHECK_TYPE_NAMES;
    $c->stash->{check_type}      = $check_type;
    $c->stash->{status}          = $status;
}

sub _list_status_designs : Local {
    my ( $self, $c ) = @_;

    my $check_type  = $c->req->params->{check_type};
    my $status      = $c->req->params->{status};
    my $page        = $c->req->params->{page};

    my $design_annotation_rs = $c->model('HTGTDB')->schema->resultset('DesignAnnotation')->search_rs(
        {
            assembly_id => $c->stash->{assembly_id},
            build_id    => $c->stash->{build_id},
            $check_type => $status,
        },
        {
            columns => [ qw(
                design_id
                oligo_status_id
                design_quality_status_id
                target_region_status_id
                artificial_intron_status_id
                final_status_id
            ) ],
            rows    => 25,
            page    => $page,
        }
    );
    my $data_page_obj = $design_annotation_rs->pager();

    $c->stash->{page_info} = Data::Pageset->new(
        {
            'total_entries'    => $data_page_obj->total_entries(),
            'entries_per_page' => $data_page_obj->entries_per_page(),
            'current_page'     => $data_page_obj->current_page(),
            'pages_per_set'    => 5,
            'mode'             => 'slide'
        }
    );

    $c->stash->{annotation_count} = $data_page_obj->total_entries();
    $c->stash->{check_type}       = $check_type;
    $c->stash->{status}           = $status;

    # Stash the results
    $c->stash->{design_annotations} = [ $design_annotation_rs->all ];
}

=head2 projects_with_changed_gene_report

A report to display all designs with a human annotation changing the gene the design is associated with.

=cut
sub projects_with_changed_gene_report : Local {
    my ( $self, $c ) = @_;

    #get all human annotations with a changed gene status
    my @annotations = $c->model('HTGTDB')->schema->resultset("DaHumanAnnotation")->search( 
        { human_annotation_status_id => "change_the_design_projects_gene" },
        { join => { design_annotation => 'design' } }
    );

    my @columns = qw(
        Project_ID
        Project_Status
        Original_MGI
        New_MGI
        Original_Gene
        New_Gene
        Design_ID
        Date_Created
        ES_Cells
    );

    #go through all the annotations that have changed a gene and get the relevant information

    my ( @rows, @errors );
    for my $row ( @annotations ) { 
        my @changes;

        #we have to store this first otherwise the regex loops forever
        my $notes = $row->human_annotation_status_notes;

        my $design = $row->design_annotation->design;

        #extract project id and the mgi genes from the note section
        #the notes string is not ideal for extracting information, lets hope it doesn't change.
        while ( $notes =~ /Project (\d+).+?(MGI:\d+)\s*to\s*(MGI:\d+)/g ) {
            my ( $project_id, $from_mgi, $to_mgi ) = ( $1, $2, $3 );

            my $project = $c->model('HTGTDB')->schema->resultset('Project')->find(
                { project_id => $project_id },
                { join => "status" }
            );

            #make sure the project id is valid
            unless ( $project ) {
                $self->_create_error_message( $c, [ "Couldn't find project $project_id" ] );
                return;
            }

            #get all es cells that are distributed/targeted_trap and linked to this project
            my @es_cells = $c->model('HTGTDB')->schema->resultset('NewWellSummary')->search(
                { 
                    -and => [ 
                                project_id => $project->project_id,
                                -or => [ epd_distribute => 'yes', targeted_trap => 'yes' ]
                            ]
                }
            );

            #remove time from the created (its in the format 02-MAY-13 14.24.21.958348)
            my $created_date = (split " ", $row->created_at)[0];

            push @changes, [
                $project_id,
                $project->status->name,
                $from_mgi,
                $to_mgi,
                $self->get_marker_symbol_from_mgi( $c, $from_mgi ),
                $self->get_marker_symbol_from_mgi( $c, $to_mgi ),
                $design->design_id,
                $created_date,
                map { $_->epd_well_name } @es_cells,
            ];
        }

        if ( @changes ) {
            push @rows, @changes;
        }
        else {
            #it would be very strange if this actually happened
            push @errors, $row->human_annotation_id;
        }
    }

    #make sure we didnt get any errors
    if ( @errors ) {
        $self->_create_error_message( $c, 
            [ map { 'No changes for human annotation ' . $_ } @errors ] 
        );
        return;
    }

    #change the view to csv
    $c->req->params->{view} = 'csvdl';

    $c->stash(
        csv_filename => 'design_annotations_report.csv',
        columns      => \@columns,
        data         => \@rows,
    );
}

=head2 get_marker_symbol_from_mgi 

Convert an mgi accession id into a marker symbol using the MGI_GENE_DATA table

=cut
sub get_marker_symbol_from_mgi {
    my ( $self, $c, $mgi_accession_id ) = @_;

    #$c->log->debug( 'getting mgi for ' . $mgi_accession_id );

    my @genes = $c->model( 'HTGTDB' )->schema->resultset('MGIGene')->search( 
        { mgi_accession_id => $mgi_accession_id },
    );

    my @marker_symbols = uniq map { $_->marker_symbol || "" } @genes;

    return "Error: multiple found" unless @marker_symbols == 1;

    my $marker_symbol = pop @marker_symbols;

    #$c->log->debug('marker symbol is ' . $marker_symbol);

    #status of the projects, remove milliseconds, add mgi accession
    #

    return $marker_symbol;
}

=head2 _create_error_message

Builds up and displays error messages

=cut

sub _create_error_message {
    my ( $self, $c, $errors ) = @_;
    my $error_message;

    foreach my $error ( @{$errors} ) {
        $error_message .= $error . "<br>";
    }

    $c->stash->{error_msg} = $error_message;
    $error_message =~ s/<br>//g;
    $c->log->warn($error_message);

    return;
}

=head1 AUTHOR

Sajith Perera

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

__END__
