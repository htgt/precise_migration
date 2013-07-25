package HTGT::Controller::MicroInjection;

use strict;
use warnings;
use base 'Catalyst::Controller';

use IO::String;
use Kermits::XLS;
use HTGT::Utils::Cache;

=head1 NAME

HTGT::Controller::MicroInjection - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

Redirects to '/microinjection/kermits_report'

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for( '/microinjection/kermits_report' ) );
}

=head2 kermits_report

Produces an Excel file download of all Microinjections found in the Kermits database.

(This is the EUCOMM 'work package 7' report spreadsheet)

=cut

sub _build_kermits_report {
    my ( $self, $c, $project ) = @_;

    my $file;
    my $fh      = IO::String->new( $file );
    my $excel   = Kermits::XLS->new( file => $fh, c => $c );

    if ( $project ) {
        $excel->write_summary_sheet( { project => $project } );
        $excel->write_centre_mi_data( { project => $project, centre => 'WTSI', sheet_name => 'Sanger - ' . $project } );
        $excel->write_centre_mi_data( { project => $project, centre => 'GSF', sheet_name => 'Helmholtz' } );
        $excel->write_centre_mi_data( { project => $project, centre => 'ICS' } );
        $excel->write_centre_mi_data( { project => $project, centre => 'MRC - Harwell', sheet_name => 'MRC' } );
        $excel->write_centre_mi_data( { project => $project, centre => 'Monterotondo', sheet_name => 'CNR' } );

        # completely miss out the UCD MI's for the EUCOMM sheet.
        if ( $project eq 'KOMP' ) {
            $excel->write_centre_mi_data( { project => $project, centre => 'UCD', sheet_name => 'UCD' } );
        }
    }
    else {
        $excel->write_summary_sheet();
        $excel->write_centre_mi_data( { project => 'EUCOMM', centre => 'WTSI', sheet_name => 'Sanger - EUCOMM' } );
        $excel->write_centre_mi_data( { project => 'KOMP', centre => 'WTSI', sheet_name => 'Sanger - KOMP' } );
        $excel->write_centre_mi_data( { centre => 'GSF', sheet_name => 'Helmholtz' } );
        $excel->write_centre_mi_data( { centre => 'ICS' } );
        $excel->write_centre_mi_data( { centre => 'MRC - Harwell', sheet_name => 'MRC' } );
        $excel->write_centre_mi_data( { centre => 'Monterotondo',  sheet_name => 'CNR' } );
        $excel->write_centre_mi_data( { centre => 'UCD',           sheet_name => 'UCD' } );
    }

    $excel->workbook->close();
    
    return $file;
}

sub kermits_report : Local {
    my ( $self, $c ) = @_;

    my $project = $c->req->params->{ project } || '';
    
    my $data =
        get_or_update_cached( $c, "microinjection_kermits_report.$project",
                              sub { $self->_build_kermits_report( $c, $project ) },
                              base64 => 1 );                                    


    $c->res->content_type( 'excel/ms-excel' );
    $c->res->header( 'Content-Disposition', qq[attachment; filename="WP7.xls"] );
    $c->res->body( $data );
}

=head2 glt_mice_report

Report page detailing all microinjections carried out where germ line transmission 
has been achieved.

=cut

sub glt_mice_report : Local {
    my ( $self, $c ) = @_;

    ##
    ## Fetch the data from Kermits (all attempts with glt > 0)
    ##

    my $attempt_rs =
        $c->model( 'KermitsDB::EmiAttempt' )->search(
            {
                -and => [
                    -or => [
                        { chimeras_with_glt_from_genotyp => { '>', 0 } },
                        { number_het_offspring => { '>', 0 } }
                    ],
                    'pipeline.id' => '1', # EUCOMM
                    'me.emma' => 1,
                ]
            },
            {
                join     => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ],
                prefetch => [ 'status', { 'event' => [ 'centre', { 'clone' => 'pipeline' } ] } ],
                order_by => { -asc => 'clone.clone_name' }
            }
        );

    my $attempts_a_ref  = [];
    my $epd_name_h_ref  = {};
    my $trap_name_h_ref = {};

    while ( my $attempt = $attempt_rs->next ) {
        # Disregard sanger attempts where less than five hets have been produced.
        next if ( $attempt->event->centre->name eq 'WTSI' && $attempt->number_het_offspring < 2 );

        push( @{ $attempts_a_ref }, $attempt );

        my $clone = $attempt->event->clone->clone_name;
        if    ( $clone =~ /EPD/ ) { $epd_name_h_ref->{ $attempt->event->clone->clone_name } = ''; }
        elsif ( $clone =~ /EUC/ ) { $trap_name_h_ref->{ $attempt->event->clone->clone_name } = ''; }
    }

    ##
    ## Now fetch all of the related project info from HTGT
    ##

    my $info_by_clone_h_ref = {};

    my $well_summary_rs = $c->model( 'HTGTDB::WellSummaryByDI' )->search(
      { epd_well_name => [ keys %{ $epd_name_h_ref } ] },
      { prefetch => 'project' }
    );

    while ( my $ws = $well_summary_rs->next ) {
      $info_by_clone_h_ref->{ $ws->epd_well_name } = {
        clone_id          => $ws->epd_well_id,
        allele_name       => $ws->allele_name,
        project_id        => $ws->project_id,
        type              => 'targ',
        marker_symbol     => $ws->project->mgi_gene->marker_symbol,
        project_status    => $ws->project->status->name,
        project_status_id => $ws->project->project_status_id,
      };
    }

    my $gene_trap_rs = $c->model( 'HTGTDB::GeneTrapWell' )->search(
      { gene_trap_well_name => [ keys %{ $trap_name_h_ref } ] }
    );

    while ( my $trap = $gene_trap_rs->next ) {
      my $project = $trap->projects->first;

      if ( defined $project and $project->project_id ) {
        $info_by_clone_h_ref->{ $trap->gene_trap_well_name } = {
          clone_id    => $trap->gene_trap_well_id,
          project_id  => $project->project_id,
          type        => 'trap'
        };
      }
      else {
        $info_by_clone_h_ref->{ $trap->gene_trap_well_name } = {
          clone_id => $trap->gene_trap_well_id,
          type     => 'trap'
        };
      }
    }

    ##
    ## Merge and stash the data...
    ##

    my $attempts_plus_htgt_ah_ref = [];

    foreach my $attempt ( @{ $attempts_a_ref } ) {
      my $clone_info = $info_by_clone_h_ref->{ $attempt->event->clone->clone_name };
      
      push(
        @{ $attempts_plus_htgt_ah_ref },
        {
          attempt        => $attempt,
          clone_id       => $clone_info->{ clone_id },
          project_id     => $clone_info->{ project_id },
          marker_symbol  => $clone_info->{ marker_symbol },
          project_status => $clone_info->{ project_status },
          allele_name    => $clone_info->{ allele_name } ? $clone_info->{ allele_name } : $attempt->event->clone->allele_name,
          type           => $clone_info->{ type }
        }
      );
    }
    $c->stash->{ attempts } = $attempts_plus_htgt_ah_ref;
}

=head1 AUTHOR

Darren Oakley
Dan Klose

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
