package HTGT::Utils::DesignQcReports;

use Moose;
use namespace::autoclean;
use Try::Tiny;

with 'MooseX::Log::Log4perl';

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has input_data => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has column_names => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

has errors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        clear_errors => 'clear',
        has_errors   => 'count',
        add_error    => 'push',
    }
);

has report => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => sub { {} },
);

sub create_report {
    my $self = shift;

    if ( $self->input_data =~ /^$/ ) {
        $self->add_error("No Data Entered");
        return;
    }

    my %report;
    $report{columns} = $self->column_names;

    my @data;
    for my $datum ( $self->input_data =~ /([\w-]+)/gsm ) {
        my @designs;
        if ( $datum =~ /^\d+$/ ) {
            push @designs, $self->_get_design( $datum );
        }
        else {
            push @designs, @{ $self->_get_designs_by_marker_symbol( $datum ) };
        }

        push @data, map { @{ $self->get_data_for_design( $_ ) } } grep{ defined $_ } @designs;

    }
    $report{data} = \@data;
    $self->report( \%report );
}

sub _get_design {
    my ( $self, $design_id ) = @_;

    my $design = $self->schema->resultset('Design')->find( { design_id => $design_id } );
    unless ($design) {
        $self->add_error( 'Can not find design: ' . $design_id );
        return; 
    }

    return $design;
}

sub _get_designs_by_marker_symbol {
    my ( $self, $marker_symbol ) = @_;

    my @designs;
    my $mgi_gene = $self->schema->resultset('MGIGene')->find( { marker_symbol => $marker_symbol } );
    unless ($mgi_gene) {
        $self->add_error( 'Marker Symbol does not exist: ' . $marker_symbol );
        return [];
    }

    my @projects = $mgi_gene->projects->search( {}, { columns => [qw/design_id/], distinct => 1 } );
    unless (@projects) {
        $self->add_error( 'Marker Symbol does not have any valid projects: ' . $marker_symbol );
        return [];
    }

    for my $design ( grep {defined} map { $_->design } @projects ) {
        push @designs, $design;
    }
    return \@designs;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
