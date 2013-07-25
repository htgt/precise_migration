package HTGT::Utils::DesignQcReports::DnaWells;

use Moose;
use namespace::autoclean;
use Const::Fast;
use Try::Tiny;

extends 'HTGT::Utils::DesignQcReports';

const my %VALID_PLATE_TYPES => (
    QPCRDNA => 1,
    SBDNA   => 1,
);

has plate_type => (
    is      => 'ro',
    isa     => 'Str',
    trigger => \&_check_plate_type,
);

sub _check_plate_type {
    my ( $self, $value ) = @_;

    unless ( exists $VALID_PLATE_TYPES{$value} ){
        die("Invalid plate type: $value");
    }
}

sub _build_column_names {
    return [ qw( 
        plate well design_id marker_symbol 
    ) ];
}

sub get_data_for_design {
    my ( $self, $design ) = @_;
    my @data;
    my $design_id = $design->design_id;
    my $marker_symbol;
    try {
        $marker_symbol = $design->info->mgi_gene->marker_symbol;
    }
    catch {
        $marker_symbol = '-';
    };

    my @design_instances = map{ $_->design_instance_id } $design->design_instances->all;

    my $dna_wells_rs = $self->schema->resultset('Well')->search_rs(
        {
            'plate.type' => $self->plate_type,
            design_instance_id => { IN => \@design_instances }, 
        },
        {
            join => 'plate',
        }
    );

    unless ( $dna_wells_rs->count ) {
        my %d;
        $d{design_id}     = $design_id;
        $d{marker_symbol} = $marker_symbol;
        push @data, \%d;
    }

    while ( my $well = $dna_wells_rs->next ) {
        my %d;
        $d{design_id}     = $design_id;
        $d{marker_symbol} = $marker_symbol;

        my $plate = $well->plate;
        $d{plate} = $plate->name;
        $d{well}  = $plate->name . '_' . $well->well_name;
        push @data, \%d;
    }

    return \@data;
}


1;

__END__
