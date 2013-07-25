package HTGT::Utils::Plate::ShippingDateParser;

use Moose;
extends 'HTGT::Utils::Plate::PlateDataParser';
use namespace::autoclean;
use MooseX::Types::DateTimeX qw( DateTime );

has shipping_center => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has ship_date => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
    coerce   => 1
);

sub parse {
    my ( $self, $str ) = @_;

    if ( $str =~ /^$/ ) {
        $self->add_error("No Data Entered");
        return;
    }

    for my $line ( split qr/\r\n|\r|\n/, $str ) {
        $self->inc_line_num;
        $self->add_plate_data( $self->_parse_line($line) );
    }
}

sub _parse_line {
    my ( $self, $line ) = @_;

    $line =~ s/\s//g;
    $self->log->debug("Parsing line '$line'");

    my $plate = $self->schema->resultset('Plate')->find( { name => $line } );
    unless ($plate) {
        $self->add_error("No such plate ($line)");
        return;
    }

    return {
        plate                                => $plate,
        'ship_date_'. $self->shipping_center => $self->ship_date->strftime('%d-%b-%y')
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
