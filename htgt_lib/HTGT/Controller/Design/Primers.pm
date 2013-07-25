package HTGT::Controller::Design::Primers;
use Moose;
use namespace::autoclean;

use HTGT::Utils::Design::GetDesignPrimers;
use HTGT::Utils::UpdateLoxpPrimerResults;
use HTGT::Utils::TaqMan::Upload;
use HTGT::Utils::TaqMan::Design;
use HTGT::Utils::DesignQcReports::TaqmanIDs;
use Try::Tiny;
use Data::Pageset;
use Const::Fast;
use IO::Scalar;

const my @TAQMAN_PLATE_FIELDS => qw( 
    well_name
    assay_id
    design_id
    marker_symbol
    deleted_region
    forward_primer_seq
    reverse_primer_seq
    reporter_probe_seq
);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

HTGT::Controller::Design::Primers - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

}

=head2 get_short_range_loxp_primers

Form that takes in design ids or marker symbols and outputs a spreadsheet
with those designs corresponding short range loxp primers (LR, LF and PNFLR)

=cut

sub short_range_loxp_primers : Local :Args(0) {
    my ( $self, $c ) = @_;
    my $schema = $c->model('HTGTDB')->schema;
    
    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} =
          "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }
    
    my $input_data;
    return if !$c->req->param('get_primers') && !$c->req->param('update_used_primers');

    if ($c->req->param('update_used_primers')) {
        return unless $self->_update_short_range_loxp_primer_results($c);
        $input_data = $c->request->params->{original_input_data};
    }
    else {
        $input_data = $c->request->params->{input_data};        
    }

    unless ( defined $input_data ) {
        $c->stash->{error_msg} = 'No Data Entered';
        return;
    }
    $c->stash->{input_data} = $input_data;

    my $design_primers = HTGT::Utils::Design::GetDesignPrimers->new(
        schema     => $c->model('HTGTDB')->schema,
        input_data => $input_data
    );

    if ( $design_primers->has_errors ) {
        $self->_create_error_message( $c, $design_primers->errors );
        return;
    }

    my $report = $design_primers->create_report;
    $c->stash->{report} = $report;
}

=head2 _update_used_short_range_loxp_primers

Allow user to update which designs short range loxp primers were used

=cut

sub _update_short_range_loxp_primer_results {
    my ( $self, $c ) = @_;
    my @updates;

    my $epd_well_primer = $c->req->params->{epd_well_primer};
    unless ($epd_well_primer) {
        $self->_create_error_message($c, [ 'No epd well primers to update' ] );
        return;
    }
    
    my @epd_well_primers;
    if (ref($epd_well_primer) eq 'ARRAY' ) {
        @epd_well_primers = @{$epd_well_primer};
    }
    else {
        push @epd_well_primers, $epd_well_primer;
    }

    for my $epd_well_primer ( @epd_well_primers ) {
        my $used_feature_field = 'primer_result_' . $epd_well_primer;
        if ( $c->req->params->{$used_feature_field} ) {
            my $update_primer_results = $self->_update_primer_used( $c, $epd_well_primer,
                $c->req->params->{$used_feature_field} );
            
            return unless $update_primer_results;
            push @updates, $update_primer_results->update_log if $update_primer_results->has_update;
        }
        else {
            $self->_create_error_message($c, [ "Cannot find update value for $epd_well_primer" ] );
            return;
        }
    }
    $self->_create_update_message($c, \@updates);

    return 1;
}

sub _update_primer_used {
    my ($self, $c, $epd_well_primer, $result) = @_;
    
    my $update_primer_results;
    try {
        $update_primer_results = HTGT::Utils::UpdateLoxpPrimerResults->new(
            schema          => $c->model('HTGTDB')->schema,
            epd_well_primer => $epd_well_primer,
            result          => $result,
            user            => $c->user->id,
        );
        $update_primer_results->update;
    }
    catch {
        $self->_create_error_message($c, [ $_ ] );
    };

    return $update_primer_results ? $update_primer_results : 0;
}

=head2 upload_taqman_assay_data

Allow users to upload taqman assay data via a csv file upload

=cut

sub upload_taqman_assay_data : Local :Args(0){
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} =
          "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }

    return unless $c->req->param('upload_taqman_data');
    
    my $htgtdb_schema  = $c->model('HTGTDB')->schema;
    my $upload         = $c->req->upload('datafile');
    my $plate_name     = $c->req->param('plate_name');

    unless ( $plate_name ){
        $c->stash->{error_msg} = "You must specify a plate name";
        return;
    }

    $c->stash->{plate_name} = $plate_name;

    unless ( $upload ) {
        $c->stash->{error_msg} = "Missing or invalid upload data file";
        return;
    }
    $htgtdb_schema->txn_do(
        sub {
            try {
                my $taqman_uploader = HTGT::Utils::TaqMan::Upload->new(
                    schema         => $htgtdb_schema,
                    user           => $c->user->id,
                    csv_filename   => $upload->fh,
                    plate_name     => $plate_name,
                );
                
                if ( $taqman_uploader->has_errors ) {
                    $htgtdb_schema->txn_rollback;
                    $self->_create_error_message( $c, $taqman_uploader->errors );
                }
                else {
                    delete $c->stash->{input_data};
                    $self->_create_update_message( $c, $taqman_uploader->update_log );
                    $c->stash->{status_msg} .= 'Created TaqMan Plate: ' . '<a href="'
                        .  $c->uri_for( '/design/primers/view_taqman_assay_plate', 
                                        { plate_name => $plate_name } ) 
                        . '">' . $plate_name . '</a>';
                }
            }
            catch {
                $htgtdb_schema->txn_rollback;
                $c->stash->{error_msg} = "Error uploading Taqman data: $_";
            };
        }
    );
}

=head2 view_taqman_assay_plate

Table showing taqman assay plate data

=cut

sub view_taqman_assay_plate : Local  {
    my ( $self, $c ) = @_;

    my $plate_name = $c->req->param('plate_name');
    if ( $plate_name ) {
        $c->stash->{plate_name} = $plate_name;
        my $taqman_plate_data = $self->_get_taqman_plate_data( $c, $plate_name );
        return unless $taqman_plate_data;
        $c->stash->{taqman_plate} = $taqman_plate_data; 
        $c->stash->{columns} = \@TAQMAN_PLATE_FIELDS; 
    }
    else {
        if ( $c->req->param('get_taqman_plate') ){
            $c->stash->{error_msg} = "You must specify a plate name" unless $plate_name;
            return;
        }
    }
}

sub _get_taqman_plate_data : Private {
    my ( $self, $c, $plate_name ) = @_;
    my @taqman_data;

    my $plate = $c->model('HTGTDB')->schema->resultset('DesignTaqmanPlate')->find({ name => $plate_name });
    unless ( $plate ) {
        $c->stash->{error_msg} = "Taqman plate $plate_name does not exist";
        return;
    }

    for my $taqman_well ( $plate->taqman_assays->all ) {
        my %d;
        for my $data_type ( @TAQMAN_PLATE_FIELDS  ) {
            if ( $data_type eq 'marker_symbol' ){
                try {
                    $d{marker_symbol} = $taqman_well->design->info->mgi_gene->marker_symbol;
                };
            }
            else {
                $d{$data_type} = $taqman_well->$data_type;
            }
        }
        push @taqman_data, \%d;
    }

    return \@taqman_data;
}

=head2 list_taqman_plates

Table listing all the TaqMan Assay plates

=cut

sub list_taqman_plates : Local {
    my ( $self, $c ) = @_;

}

sub _list_taqman_plates : Local {
    my ( $self, $c ) = @_;

    my $taqman_plate_rs = $c->model('HTGTDB')->schema->resultset('DesignTaqmanPlate')->search_rs(
        {}, { rows => 25, page => $c->req->params->{page} }
    );
    my $data_page_obj = $taqman_plate_rs->pager();

    $c->stash->{page_info} = Data::Pageset->new(
        {
            'total_entries'    => $data_page_obj->total_entries(),
            'entries_per_page' => $data_page_obj->entries_per_page(),
            'current_page'     => $data_page_obj->current_page(),
            'pages_per_set'    => 5,
            'mode'             => 'slide'
        }
    );

    $c->stash->{plate_count} = $data_page_obj->total_entries();

    # Stash the results
    $c->stash->{plates} = [ $taqman_plate_rs->all ];
}

=head2 get_taqman_ids

Form that accepts design ids or marker symbols are returns any TaqMan Assay ID's
associated with those designs / genes.

=cut

sub get_taqman_ids : Local {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} = "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }

    return unless $c->req->param('get_taqman_ids') || $c->req->param('get_taqman_ids_csv');

    unless ( $c->req->param('input_data') ) {
        $c->stash->{error_msg} = 'No Data Entered';
        return;
    }
    $c->stash->{input_data} = $c->req->param('input_data');

    if ( $c->req->param( 'get_taqman_ids_csv' ) ) {
        $c->req->params->{view} = 'csvdl';
        $c->req->params->{file} = 'Taqman_Report.csv';
    }         

    my $taqman_assays = HTGT::Utils::DesignQcReports::TaqmanIDs->new(
        schema     => $c->model('HTGTDB')->schema,
        input_data => $c->req->param('input_data'),
    );

    $taqman_assays->create_report;

    if ( $taqman_assays->has_errors ) {
        $self->_create_error_message( $c, $taqman_assays->errors );
        return;
    }

    $c->stash->{report} = $taqman_assays->report;
}

=head2 get_taqman_design_info

Get information needed to create taqman primers for specific designs

=cut

sub get_taqman_design_info : Local {
    my ( $self, $c ) = @_;

    $c->stash->{targets} = [
        { name => '-', value => '-' },
        map { name => $_, value => $_ }, qw( critical deleted )
    ];
    $c->stash->{output_types} = [
        { name => '-', value => '-' },
        map { name => $_, value => $_ }, qw( sequence coordinates )
    ];

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} = "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }

    return unless $c->req->param('get_taqman_design_info');

    my $htgtdb_schema = $c->model('HTGTDB')->schema;
    my $input         = $c->req->upload('datafile');
    my $target        = $c->req->param('target');
    my $output_type   = $c->req->param('output_type');
    my $duplicates    = $c->req->param('duplicates');

    if ( !$target || $target eq '-' ){
        $c->stash->{error_msg} = "You must specify a target";
        return;
    }
    $c->stash->{current_target} = $target;

    if ( !$output_type || $output_type eq '-' ){
        $c->stash->{error_msg} = "You must specify a output type";
        return;
    }
    $c->stash->{output_type} = $output_type;
    $c->stash->{duplicates} = $duplicates;

    unless ( $input ) {
        $c->stash->{error_msg} = "Missing or invalid input data file";
        return;
    }

    try {
        my $taqman = HTGT::Utils::TaqMan::Design->new(
            schema             => $htgtdb_schema,
            target             => $target,
            sequence           => $output_type eq 'sequence' ? 1 : 0,
            include_duplicates => $duplicates ? 1 : 0,
            input_file         => $input->fh,
        );

        my $zip = $taqman->create_zip_file;
        my $data;
        my $fh = new IO::Scalar \$data;
        $zip->writeToFileHandle($fh);
        
        $c->res->content_type('application/octet-stream');
        $c->res->headers->header( 'Content-Disposition' => "attachment; filename=\"taqman_design_info.zip" );
        $c->res->body($data);
    }
    catch {
        $c->stash->{error_msg} = "Error creating TaqMan design information: $_"; 
        return;
    };
}

=head2 _create_error_message

Builds up and displays error messages gathered by GetDesignPrimers as it parses the input

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

=head2 _create_update_message

Builds up and displays update messages create by UpdateLoxpPrimerResult module

=cut

sub _create_update_message {
    my ( $self, $c, $update_log ) = @_;
    my $update_message;

    unless ( scalar(@{ $update_log }) ){
        $c->stash->{status_msg} = 'Nothing to change';
        return;
    }

    foreach my $message ( @{ $update_log } ) {
        $update_message .= $message . "<br>";
    }
    
    $c->stash->{status_msg} = $update_message;
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
