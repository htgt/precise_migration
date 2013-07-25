package HTGT::Utils::Plate::ArchiveLabelParser;

use Moose;
use namespace::autoclean;

extends 'HTGT::Utils::Plate::PlateDataParser';
with 'MooseX::Log::Log4perl';

sub parse {
    my ( $self, $str ) = @_;

    if ( $str =~ /^$/ ) {
        $self->add_error("No Data Entered");
        return;
    }
    for my $line ( split qr/\r\n|\r|\n/, $str ) {

        $self->inc_line_num;
        for my $datum ( $self->_parse_line($line) ) { #returns array of hashes
            $self->add_plate_data($datum);            #$datum is hashref
        }
    }
}

sub _parse_line {
    my ( $self, $line ) = @_;

    $line =~ s/\s//g;
    $self->log->debug("Parsing line '$line'");

    my ( $plate_basename, $archive_label, $range, $surplus ) = split qr/,/,
        $line;
    unless ( defined $plate_basename ) {
        $self->add_error("No Data Entered");
        return;
    }
    unless ( defined $archive_label ) {
        $self->add_error("Missing archive label");
        return;
    }
    unless ( defined $range ) {
        $range = '1-4';    # default
    }

    if ( defined $surplus ) {
        $self->add_error("Too many fields entered, max of 3");
        return;
    }

    return $self->_expand_data( $plate_basename, $archive_label, $range );
}

sub _expand_data {
    my ( $self, $plate_basename, $archive_label, $range ) = @_;

    unless ( $archive_label =~ /^P(C|G)\d+$/ ) {
        $self->add_error("Invalid archive label ($archive_label)");
    }

    my @data;
    for my $suffix ( $self->_expand_plate_numbers($range) ) {
        my $plate_name = $plate_basename . '_' . $suffix;
        if ( $self->is_plate_seen($plate_name) ) {
            $self->add_error("Duplicate Plate Entered ($plate_name)");
            next;
        }
        $self->mark_plate_seen($plate_name);

        my $plate = $self->schema->resultset('Plate')
            ->find( { name => $plate_name } );
        unless ($plate) {
            $self->add_error("No such plate ($plate_name)");
            next;
        }
        push @data,
            {
            plate            => $plate,
            plate_label      => $plate_basename . '_' . $range,
            archive_label    => $archive_label,
            archive_quadrant => $self->_quadrant($suffix),
            };
    }

    return @data;
}

=head2 _quadrant

Return correct archive plate quadrant when given plate suffix 

=cut

sub _quadrant {
    my ( $self, $num ) = @_;

    while ( $num > 4 ) {
        $num -= 4;
    }

    return $num;
}

=head2 _expand_plate_numbers

Expand plate number values into list of numbers

=cut

sub _expand_plate_numbers {
    my ( $self, $number_string ) = @_;

    unless ( $number_string =~ /^(\d+(-\d+)?)(&(\d+(-\d+)?))*$/ ) {
        $self->add_error("Invalid plate number range ($number_string)");
        return;
    }

    my @range = map $self->_expand_range($_), split( /&/, $number_string );

    return sort @range;
}

=head2 _expand_range

Expand range of numbers into full sequence of numbers

=cut

sub _expand_range {
    my ( $self, $range_str ) = @_;

    my ( $from, $to ) = $range_str =~ /^(\d+)(?:-(\d+))?$/
        or do {
        $self->add_error("Invalid range ($range_str)");
        return;
        };

    $to ||= $from;
    if ( $to < $from ) {
        $self->add_error(
            "Invalid plate number range, must be smaller to larger value ($range_str)"
        );
        return;
    }
    if ( ( $to - $from ) > 4 ) {
        $self->add_error(
            "Invalid plate number range, too many plates ($range_str)");
        return;
    }

    return $from .. $to;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
