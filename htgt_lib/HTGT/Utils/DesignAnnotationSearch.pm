package HTGT::Utils::DesignAnnotationSearch;

=head1 NAME

HTGT::Utils::DesignAnnotationSearch

=head1 DESCRIPTION

Searches for design annotations for given design ids or marker symbols.

=cut

use Moose;
use namespace::autoclean;
use Try::Tiny;

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

has assembly_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has build_id => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
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

sub find_annotations {
    my $self = shift;

    if ( $self->input_data =~ /^$/ ) {
        $self->add_error("No Data Entered");
        return;
    }

    my @designs;
    for my $datum ( $self->input_data =~ /([\w-]+)/gsm ) {
        if ( $datum =~ /^\d+$/ ) {
            push @designs, $datum;
        }
        else {
            push @designs, @{ $self->_get_designs_by_marker_symbol( $datum ) };
        }
    }

    my @design_annotations;
    for my $design_id ( @designs ) {
        my $da = $self->find_design_annotation( $design_id );
        push @design_annotations, $da if $da;
    }

    return \@design_annotations;
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

    for my $design_id ( grep {defined} map { $_->design_id } @projects ) {
        push @designs, $design_id;
    }
    return \@designs;
}

sub find_design_annotation {
    my ( $self, $design_id ) = @_;

    return $self->schema->resultset('DesignAnnotation')->find(
        {
            design_id   => $design_id,
            assembly_id => $self->assembly_id,
            build_id    => $self->build_id,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
