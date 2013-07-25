package HTGT::Utils::TaqMan::Design::Coordinates;

use Moose::Role;
use namespace::autoclean;
use Const::Fast;
use File::Temp qw( tempfile );
use CSV::Writer;
use List::MoreUtils qw( uniq );

const my @OUT_DELETED_COLUMNS => qw(
    marker_symbol
    design_id
    has_primer
    sponsor
    chromosome
    strand
    design_type
    u_deleted_start
    u_deleted_end
    d_deleted_start
    d_deleted_end
    deleted_start
    deleted_end
);

const my @OUT_CRITICAL_COLUMNS => qw(
    marker_symbol
    design_id
    has_primer
    sponsor
    chromosome
    strand
    design_type
    critical_start
    critical_end
);

has csv => (
    is => 'ro',
    isa => 'CSV::Writer',
    lazy_build => 1,
);

sub _build_csv {
    my $self = shift;

    my @out_columns = $self->target eq 'deleted'  ? @OUT_DELETED_COLUMNS
                    : $self->target eq 'critical' ? @OUT_CRITICAL_COLUMNS
                    :                               '';

    my $csv = CSV::Writer->new(
        columns => \@out_columns, output => $self->temp_output_files->{csv} );
    $csv->write(@out_columns);

    return $csv;
}

sub _build_temp_output_files {
    my $self = shift;

    my $csv_file = File::Temp->new()
        or die "Unable to create tmp file: $!";

    return { csv => $csv_file };
}

sub get_taqman_design_info {
    my ( $self, $data )= @_;

    my $design_ids = $self->get_designs( $data );

    foreach my $design_id ( uniq @{ $design_ids } ) {
        my $data = $self->get_taqman_target_data( $design_id );
        $self->csv->write($data)
    }
}

sub fetch_wildtype_critical_data {
    my ( $self, $data, $features ) = @_;

    my $c;
    if ( $data->{strand} == 1 ) {
        $c = $self->coordinates_plus( 'U3', 'D5', $features );
    }
    else {
        $c = $self->coordinates_minus( 'U3', 'D5', $features );
    }

    $data->{critical_start} = $c->{start};
    $data->{critical_end}   = $c->{end};
}

sub fetch_wildtype_deleted_data {
    my ( $self, $data, $features ) = @_;

    my %c;
    if ( $data->{strand} == 1 ) {
        $c{u_deleted} = $self->coordinates_plus( 'U5', 'U3', $features );
        $c{d_deleted} = $self->coordinates_plus( 'D5', 'D3', $features );
    }
    else {
        $c{u_deleted} = $self->coordinates_minus( 'U5', 'U3', $features );
        $c{d_deleted} = $self->coordinates_minus( 'D5', 'D3', $features );
    }

    $data->{u_deleted_start} = $c{u_deleted}->{start};
    $data->{u_deleted_end}   = $c{u_deleted}->{end};
    $data->{d_deleted_start} = $c{d_deleted}->{start};
    $data->{d_deleted_end}   = $c{d_deleted}->{end};

}

sub fetch_wildtype_data_non_KO_design {
    my ( $self, $data, $features ) = @_;

    my $c;
    if ( $data->{strand} == 1 ) {
        $c = $self->coordinates_plus( 'U5', 'D3', $features );
    }
    else {
        $c = $self->coordinates_minus( 'U5', 'D3', $features );
    }

    $data->{$self->target . '_start'} = $c->{start};
    $data->{$self->target . '_end'}   = $c->{end};

}

1;

__END__
