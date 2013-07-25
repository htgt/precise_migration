package HTGT::Utils::UploadQCResults::DnaPlates;

use Moose;
use namespace::autoclean;
use HTGT::Constants qw( %QC_RESULT_TYPES %RANKED_QC_RESULTS );
use CSV::Reader;
use Try::Tiny;
use Const::Fast;

const my %VALID_DNA_PLATE_TYPES => (
   QPCRDNA => 1,
   SBDNA   => 1,
);

with 'HTGT::Utils::UploadQCResults';

has dna_plate_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => \&_dna_plate_type_check,
);

sub _dna_plate_type_check {
    my ( $self, $dna_plate_type ) = @_;

    unless ( exists $VALID_DNA_PLATE_TYPES{ $dna_plate_type } ) {
        die( "Unrecognised dna plate type: " . $self->dna_plate_type );
    }
}

has dna_plate_data => (
    is         => 'ro',
    isa        => 'HashRef',
    traits     => ['Hash'],
    default    => sub { {} },
    handles    => {
        no_dna_plate_data    => 'is_empty',
        clear_dna_plate_data => 'clear',
    }
);

has dna_plates => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        get_dna_plate    => 'get',
        dna_plate_exists => 'exists',
        set_dna_plate    => 'set',
    }
);

sub _build_csv_reader {
    my $self = shift;

    my $csv_reader = CSV::Reader->new( 
        input      => $self->cleaned_input,
        use_header => 1,
    );

    die( "Unable to construct CSV::Reader object" ) unless $csv_reader;
    return $csv_reader;
}

sub parse_csv {
    my $self = shift;

    try {
        while ( my $line_data = $self->csv_reader->read ) {
            # copy to new hash with lowercase keys
            my %data = map{ lc($_) => $line_data->{$_} } keys %{ $line_data }; 
            $self->_parse_line( \%data );
        }
    }
    catch{
        $self->add_error("Parse error, line " . $self->line_number . " of input: $_" );
    };
}

sub _parse_line {
    my ( $self, $data ) = @_;
    $self->inc_line_number;

    for my $param ( qw( plate well clone_name ) ) {
        unless ( $data->{$param} ) {
            $self->add_error("Missing $param name line " . $self->line_number );
            return;
        }
    }

    my $plate_type = $self->dna_plate_type;
    unless ( $data->{plate} =~ /^$plate_type[A-Z0-9_]+/ ) {
        $self->add_error("Invalid plate name: " .  $data->{plate} . ' line ' . $self->line_number );
        return;
    }

    unless ( $data->{well} =~ /^[A-O](0[1-9]|1[0-9]|2[0-4])$/ ) {
        $self->add_error("Invalid well name: " . $data->{well} . ' line ' . $self->line_number );
        return;
    }

    return if $data->{clone_name} eq '-';
    $data->{clone_name} =~ /^(.*)_(\w\d\d)$/;
    my $epd_plate_name = $1;
    my $epd_well = $self->_get_epd_well( $data->{clone_name}, $epd_plate_name );
    return unless $epd_well;

    $self->dna_plate_data->{ $data->{plate} }{ $data->{well} } = $epd_well;
    
}

sub _get_epd_well {
    my ( $self, $epd_well_name, $epd_plate_name ) = @_;

    my $epd_well = $self->schema->resultset('Well')->find( 
        { 
            well_name    => $epd_well_name,
            'plate.name' =>  $epd_plate_name,
            'plate.type' => 'EPD',
        }, { join => 'plate' }
    );

    unless ( $epd_well ) {
        $self->add_error("Unable to find epd clone: $epd_well_name" . ' line ' . $self->line_number );
        return;
    }

    return $epd_well;
}

sub update_qc_results {
    my $self = shift;

    return if $self->no_dna_plate_data;
    return if $self->has_errors;

    foreach my $plate_name ( keys %{ $self->dna_plate_data } ) {
        my $plate = $self->find_or_create_plate( $plate_name );
        my $plate_data = $self->dna_plate_data->{$plate_name};

        foreach my $well_name ( keys %{ $plate_data } ) {
            $self->check_and_create_well( $plate, $well_name, $plate_data->{$well_name} );
        }
    }
}

sub find_or_create_plate{
    my ( $self, $plate_name ) = @_;

    return $self->get_dna_plate( $plate_name ) if $self->dna_plate_exists( $plate_name );

    my $plate = $self->schema->resultset( 'Plate' )->find( { name => $plate_name } );
    unless ( $plate ) {
        $plate = $self->schema->resultset( 'Plate' )->create(
            {
                name         => $plate_name,
                type         => $self->dna_plate_type,
                created_user => $self->user,
                edited_user  => $self->user,
                created_date => \'current_timestamp',
                edited_date  => \'current_timestamp',
            }
        );
        $self->add_log("Created plate $plate_name : " . $plate->plate_id );
    }

    $self->set_dna_plate( $plate_name => $plate );
    return $plate;
}

sub check_and_create_well {
    my ( $self, $plate, $well_name, $parent_well ) = @_;
    my $well;

    if ( $well = $plate->wells->find( { well_name => $well_name } ) ) {
        if ( $well->parent_well_id != $parent_well->well_id ) {
            $self->update_parent_well( $plate, $well, $parent_well );
        }
        return $well;
    }

    $well = $plate->wells_rs->create(
        {
            well_name          => $well_name,
            parent_well_id     => $parent_well->well_id,            
            design_instance_id => $parent_well->design_instance_id,
            edit_user          => $self->user,
            edit_date          => \'current_timestamp'
        }
    );

    $self->update_plate_plate( $plate, $parent_well->plate );

    $self->add_log( "Created $well_name well on plate: " . $plate->name 
                    . ", with parent: " . $parent_well->well_name );
    return $well;
}

sub update_parent_well {
    my ( $self, $plate, $well, $parent_well ) = @_;
    my $existing_parent_well = $well->parent_well;

    $well->update( 
        { 
            parent_well_id     => $parent_well->well_id,
            design_instance_id => $parent_well->design_instance_id, 
        } 
    );

    $self->update_plate_plate( $plate, $parent_well->plate, $existing_parent_well->plate );

    $self->add_log( "$plate plate has " . $well->well_name . " well that belongs to " 
                    . 'a different parent well ' . $existing_parent_well->well_name 
                    . ', changing to new parent well ' . $parent_well->well_name );
    return $well;
}

sub update_plate_plate {
    my ( $self, $plate, $new_parent_plate, $old_parent_plate ) = @_;

    if ( $old_parent_plate ) {
        my $parent_plates_rs = $plate->parent_plates_from_parent_wells;

        my $exists_old_parent_plate = $parent_plates_rs->find( { plate_id => $old_parent_plate->plate_id } );
        unless ( $exists_old_parent_plate ) {
            my $plate_plate = $self->schema->resultset('PlatePlate')->find(
                {
                    parent_plate_id => $old_parent_plate->plate_id,
                    child_plate_id  => $plate->plate_id
                }
            );
            ### delete palte palte : $plate_plate->parent_plate_id

            $plate_plate->delete if $plate_plate;
        }
    }

    $self->schema->resultset('PlatePlate')->find_or_create(
        {
            parent_plate_id => $new_parent_plate->plate_id,
            child_plate_id  => $plate->plate_id
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
