package HTGT::Controller::Report::Recovery;

use strict; 
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

use HTGT::Utils::Cache;
use HTGT::Utils::Recovery::Constants qw( @REPORTS );
use HTGT::Utils::Recovery::Report::SecondaryGateway;
use Path::Class;
use Readonly;
use Text::CSV_XS;

Readonly my $CSV_DIR => dir( '/software/team87/brave_new_world/data/generated/recovery_reports' );

sub default : Path {
    my ( $self, $c, $report_name ) = @_;

    $c->detach( 'index' ) unless $report_name;

    my $file = $CSV_DIR->file( "$report_name.csv" );

    my $fh = $file->open;
    unless ( $fh ) {
        $c->log->error( "open $file: $!" );
        $c->stash->{error_msg} = "Report $report_name is temporarily unavailable; please try again later";
        $c->detach( 'index' );
    }

    $c->response->content_type('text/comma-separated-values');
    $c->response->header( 'Content-Disposition', qq[attachment; filename="$report_name.csv"] );
    $c->response->body( $fh );
} 
    
sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $count_for = get_or_update_cached( $c, 'recovery_gene_counts',
                                          sub { $self->_build_counts( $c ) } );
    
    my @reports;
    
    for my $section ( @REPORTS ) {
        my @section_reports;
        for my $report ( @{ $section->{reports} } ) {
            push @section_reports, {
                name    => $report->{name},
                count   => $count_for->{ $report->{action} },
                csv_uri => $c->uri_for( $c->action, $report->{action} )                
            };
        }
        push @reports, { name => $section->{name}, reports => \@section_reports };
    }    

    $c->stash->{template} = 'report/recovery/index.tt';
    $c->stash->{reports}  = \@reports;
}


sub secondary_gateway : Local {
    my ( $self, $c ) = @_;

    my $plate_name = $c->req->param( 'plate_name' );
    if ( $plate_name ) {
        $c->stash->{report} = HTGT::Utils::Recovery::Report::SecondaryGateway->new(
            plate_name       => $plate_name,
            schema           => $c->model( 'HTGTDB' )->schema,
            vector_qc_schema => $c->model( 'ConstructQC' )->schema,
            csv_uri          => $c->uri_for( $c->action, { view => 'csvdl', plate_name => $plate_name } ),
        );        
    }
}

sub _build_counts {
    my ( $self, $c ) = @_;

    my %count_for;

    for my $report ( map $_->{action}, map @{ $_->{reports} }, @REPORTS ) {
        my $file = $CSV_DIR->file( "$report.csv" );
        my $ifh = $file->open;
        unless ( $ifh ) {
            $c->log->error( "open $file: $!" );
            $count_for{ $report } = '-';
            next;
        }
        my $csv = Text::CSV_XS->new;
        $csv->column_names( $csv->getline( $ifh ) );
        my %seen;
        while ( my $data = $csv->getline_hr( $ifh ) ) {
            next unless defined $data->{mgi_accession_id};
            $seen{ $data->{mgi_accession_id} }++;
        }
        $count_for{ $report } = scalar keys %seen;
    }

    return \%count_for;    
}
    
1;

__END__
