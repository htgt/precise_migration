package HTGT::Controller::QC::DnaPlateSearch;
use Moose;
use namespace::autoclean;

use HTGT::Utils::DesignQcReports::DnaWells;
use Try::Tiny;
use Const::Fast;

BEGIN {extends 'Catalyst::Controller'; }

=head2 index

Form that accepts design ids or marker symbols are returns any TaqMan Assay ID's
associated with those designs / genes.

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    unless ( $c->check_user_roles('edit') ) {
        $c->stash->{error_msg} =
          "You are not authorised to view this page";
        $c->detach( 'Root', 'welcome' );
    }

    my @qc_types = qw( SBDNA QPCRDNA );
    $c->stash->{qc_types} = [ '-' , @qc_types ];
    return unless $c->req->param('get_qc_data') || $c->req->param('get_qc_data_csv');

    if ( $c->req->param('qc_type') eq '-' ) {
        $c->stash->{error_msg} = 'Must specify a Qc Type';
        return;
    }

    $c->stash->{qc_type} = $c->req->param('qc_type');

    unless ( $c->req->param('input_data') ) {
        $c->stash->{error_msg} = 'No Data Entered';
        return;
    }
    $c->stash->{input_data} = $c->req->param('input_data');

    if ( $c->req->param( 'get_qc_data_csv' ) ) {
        $c->req->params->{view} = 'csvdl';
        $c->req->params->{file} = 'QC_Data.csv';
    }         

    my $dna_wells = HTGT::Utils::DesignQcReports::DnaWells->new(
        schema     => $c->model('HTGTDB')->schema,
        input_data => $c->req->param('input_data'),
        plate_type => $c->req->param('qc_type'),
    );

    $dna_wells->create_report;

    if ( $dna_wells->has_errors ) {
        $self->_create_error_message( $c, $dna_wells->errors );
        return;
    }

    $c->stash->{report} = $dna_wells->report;
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
