package HTGT::Utils::Report::SequencingArchiveLabels;

use Moose;
use Iterator::Util;
use namespace::autoclean;

with qw( HTGT::Utils::Report::GenericIterator );

sub _build_name { "Sequencing Archive Labels" }

sub _build_columns { [ "Sequencing Archive Label", "Plate Name" ] }

sub _build_iterator {
    my $self = shift;

    my $rs = $self->schema->resultset( 'PlateData' )->search(
        {
            'me.data_type' => 'archive_label'
        },
        {
            prefetch => 'plate'
        }
    );

    my @rows = map $_->[0],
        sort { $a->[1] cmp $b->[1] || $a->[2] <=> $b->[2] }
            map $self->parse_data( $_ ), $rs->all;

    Iterator::Util::iarray( \@rows );    
}

sub parse_data {
    my ( $self, $row ) = @_;

    my $archive_label = $row->data_value;
    my $plate_name    = $row->plate->name;

    my ( $prefix, $suffix ) = $archive_label =~ m/^\s*([A-Za-z_]+)\s*(\d+)\s*$/;

    return [       
        {
            "Sequencing Archive Label" => $archive_label,
            "Plate Name"               => $plate_name
        },
        $prefix,
        $suffix
    ];
}

1;

__END__
