package HTGT::Utils::Recovery::Report;

use strict;
use warnings FATAL => 'all';

use Moose::Role;
use HTGT::Utils::Recovery::Constants qw( @PROJECT_STATUS_IGNORE_PROJECT );
use HTGT::BioMart::QueryFactory;
use HTGT::Utils::RegeneronGeneStatus;
use Iterator;

with qw( HTGT::Utils::Report::GenericIterator MooseX::Log::Log4perl );

requires qw( _build_handled_state );

=attr handled_state

The gr_gene_recovery state handled by this class.

=cut

has handled_state => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

=method default_columns

Initializer for the B<columns> attribute.

=cut

sub _build_columns {
    [
        qw( marker_symbol
            mgi_accession_id
            sponsor
            comment
            redesign_recovery
            resynthesis_recovery
            gateway_recovery
            alternate_clone_recovery            
      )
    ]
}

=attr idcc_mart_uri

URI for the IDCC BioMart.

=cut

has idcc_mart_uri => (
    is    => 'ro',
    isa   => 'Str',
    required => 1,
    default  => 'http://www.i-dcc.org/biomart/martservice',
);

=attr regeneron_status_util

Cached B<HTGT::Utils::RegeneronGeneStatus> object.

=cut

has regeneron_status_util => (
    is          => 'ro',
    isa        => 'HTGT::Utils::RegeneronGeneStatus',
    lazy_build => 1,
);

sub _build_regeneron_status_util {
    my $self = shift;
    
    HTGT::Utils::RegeneronGeneStatus->new(
        HTGT::BioMart::QueryFactory->new( { martservice => $self->idcc_mart_uri } )
    );
}

=method search_filter

The filter passed to B<DBIx::Class::Resultset-E<gt>search()> to retrieve
records from the B<gr_gene_status> table for this report.

The default is to filter on state equals B<$class-E<gt>handled_state>.

=cut

has search_filter => (
    is         => 'rw',
    isa        => 'HashRef',
    required   => 1,
    lazy_build => 1,
);

sub _build_search_filter {
    return {
        state => shift->handled_state
    };    
}

=method search_params

Additional paramaters passed to B<DBIx::Class::Resultset-E<gt>search()>,
for example to join or prefetch data from other tables. The default is
to prefetch B<mgi_gene>.

=cut

has search_params => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_search_params {
    return {
        prefetch => [ 'mgi_gene' ]
    };
}

=method sponsor

Convenience method to look up the B<sponsor> for the gene. It does
this by finding a suitable active project and calling the C<sponsor>
method on the underlying B<HTGTDB::Project> object.

If no active projects are found (e.g. when reporting a gene in status
I<none>), the search is broadened to all projects.

B<WARNING: This may give misleading results if this gene belongs to projects with
different sponsors.>

=cut

sub sponsor {
    my ( $class, $mgi_gene ) = @_;

    my $project_rs = $mgi_gene->search_related(
        projects => {
            'status.code' => { -not_in => \@PROJECT_STATUS_IGNORE_PROJECT },
            -nest         => [ is_komp_csd => 1, is_eucomm => 1 ]
        },
        {
            join => 'status'
        }
    );

    unless ( $project_rs->first ) {
        $project_rs = $mgi_gene->search_related(
            projects => {
                -nest => [ is_komp_csd => 1, is_eucomm => 1 ]
            }
        );
    }

    return 'UNKNOWN' unless $project_rs->first;
    
    $project_rs->first->sponsor;
}

=method regeneron_status(I<$mgi_gene>)

Convenience method to retrieve the latest Regeneron status for I<$mgi_gene>.

=cut

sub regeneron_status {
    my ( $self, $mgi_gene ) = @_;

    my $mgi_accession_id = $mgi_gene->mgi_accession_id
        or return;
    
    $self->regeneron_status_util->status_for( $mgi_accession_id );
}

=method grd_plates(I<$mgi_gene>)

Retrieve a list of GRD plates containing I<$mgi_gene_id>.

=cut

sub grd_plates {
    my ( $self, $mgi_gene_id ) = @_;

    my $grd_plates;

    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            $grd_plates = $dbh->selectcol_arrayref( <<'EOT', undef, $mgi_gene_id );
select distinct plate.name
from plate
join well on well.plate_id = plate.plate_id
join project on project.design_instance_id = well.design_instance_id
where well.design_instance_id is not null
and plate.type = 'GRQ'
and plate.name like 'GRD0%'
and project.mgi_gene_id = ?
order by plate.name
EOT
        }
    );

    return join( q{, }, @{ $grd_plates } );
}


=method common_data( I<$gr_gene_status> )

Returns a list of key/value pairs of data common to all reports.

=cut

sub common_data {
    my ( $self, $gene_status ) = @_;

    return (
        marker_symbol    => $gene_status->mgi_gene->marker_symbol,
        mgi_accession_id => $gene_status->mgi_gene->mgi_accession_id,
        sponsor          => $self->sponsor( $gene_status->mgi_gene ),
        comment          => $gene_status->note,
        $self->recovery_plates( $gene_status ),
    );
}

=method recovery_plates( I<$gr_gene_status> )

Return a list mapping recovery type to a comma-separated lists of recovery plates for the specified gene.

=cut

sub recovery_plates {
    my ( $self, $gene_status ) = @_;

    my $sth = $self->schema->storage->dbh->prepare_cached( <<'EOT' );
select distinct plate.name, plate_data.data_type
from plate
join plate_data on plate_data.plate_id = plate.plate_id
join well on well.plate_id = plate.plate_id
join design_instance di on di.design_instance_id = well.design_instance_id
join project on project.design_instance_id = di.design_instance_id
where plate_data.data_type in ( 'redesign_recovery', 'resynthesis_recovery', 'gateway_recovery', 'alternate_clone_recovery' )
and plate_data.data_value = 'yes'
and project.mgi_gene_id = ?
order by plate.name
EOT

    $sth->execute( $gene_status->mgi_gene->mgi_gene_id );

    my %recovery_plates;
    while ( my ( $plate_name, $recovery_type ) = $sth->fetchrow_array ) {
        push @{ $recovery_plates{ $recovery_type } }, $plate_name;
    }

    return map { $_ => join( q{, }, @{ $recovery_plates{$_} } ) } keys %recovery_plates;
}

=method auxiliary_data( I<$gr_gene_status> )

Returns a list of key/value pairs of class-specific data. Defaults to
an empty list.

=cut

sub auxiliary_data {
    return ();
}

=method _build_iterator

Build the iterator used by this class. Each time the iterator is
called, it returns a row of data for the relevant report. The data is
returned as a hash reference whose keys will be (possibly a superset
of) C<$self->columns>.

=cut

sub _build_iterator {
    my $self = shift;

    my $rs = $self->schema->resultset( 'GRGeneStatus' )->search(
        $self->search_filter,
        { join => 'mgi_gene', order_by => 'mgi_gene.marker_symbol', %{ $self->search_params } }
    );

    return Iterator->new(
        sub {
            my $gr_gene_status = $rs->next or Iterator->is_done;
            return {
                $self->common_data( $gr_gene_status ),
                $self->auxiliary_data( $gr_gene_status )
            };
        }
    );
}

1;

__END__
