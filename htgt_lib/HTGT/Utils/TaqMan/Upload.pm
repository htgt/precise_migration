package HTGT::Utils::TaqMan::Upload;

use Moose;
use namespace::autoclean;
use Const::Fast;
use CSV::Reader;
use List::MoreUtils qw( none );
use Perl6::Slurp;
use IO::File;

const my @VALID_DELETED_REGIONS => qw(
    u
    d
    c
);

# 1 means required
const my %CSV_FIELDS => (
    Well               => 1,
    design_id          => 1,
    Assay_ID           => 1,
    design_region      => 1,
    marker_symbol      => 0,
    forward_primer_seq => 0,
    reverse_primer_seq => 0,
    reporter_probe_seq => 0,
);

const my @TAQMAN_DATA_INPUT_FIELDS => qw(
    well_name
    assay_id
    deleted_region
    forward_primer_seq
    reverse_primer_seq
    reporter_probe_seq
);

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
);

has csv_filename => (
    is       => 'ro',
    isa      => 'IO::File',
    required => 1,
);

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has plate => (
    is         => 'ro',
    isa        => 'HTGTDB::DesignTaqmanPlate',
    lazy_build => 1,
);

sub _build_plate {
    my $self = shift;

    my $plate = $self->schema->resultset( 'DesignTaqmanPlate' )->find_or_create(
        {
            name => $self->plate_name,
        }
    );
    die 'Unable to find or create TaqMan plate' unless $plate;

    return $plate;
}

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has assay_data => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        has_assay_data => 'count',
        add_assay_data => 'push',
    }
);

has errors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        has_errors   => 'count',
        add_error    => 'push',
        clear_errors => 'clear',
    }
);

has update_log => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
    traits  => ['Array'],
    handles => {
        add_log => 'push',
    }
);


sub BUILD {
    my $self = shift;

    $self->build_assay_data;
    $self->add_error('No assay data') unless $self->has_assay_data;

    return if $self->has_errors;

    foreach my $data ( @{ $self->assay_data } ) {
        my %assay_data = map { $_ => $data->{$_} } grep { exists $data->{$_} } @TAQMAN_DATA_INPUT_FIELDS;
        $assay_data{taqman_plate_id} = $self->plate->taqman_plate_id;
        $assay_data{edit_user}       = $self->user;
        $assay_data{edit_date}       = \'current_timestamp';

        next if $self->_existing_assay_id( $assay_data{assay_id} );
        next if $self->_invalid_deleted_region( $assay_data{deleted_region} );
        next if $self->_existing_assay_well( $assay_data{well_name} );

        $data->{design}->create_related( 'taqman_assays', \%assay_data );
        $self->add_log( 'assay id: ' . $assay_data{assay_id} . ', linked to design: ' . $data->{design_id} );
    }
}

sub build_assay_data {
    my $self = shift;
    my @assays;

    my @data = split /\r\n|\r|\n/, slurp( $self->csv_filename );
    my $temp_file = IO::File->new_tmpfile;
    map{ $temp_file->print( $_ . "\n") } @data;
    $temp_file->seek(0,0);

    my $line = 1;
    my $csv = CSV::Reader->new( input => $temp_file, use_header => 1 );
    return [] unless $self->_has_recognised_data($csv->columns);

    while ( my $r = $csv->read ) {
        $line++;
        my %assay_data;
        next unless $self->_has_required_data($r, $line);
        $assay_data{design_id}      = $r->{design_id};
        $assay_data{design}         = $self->_get_design($r->{design_id}),
        $assay_data{assay_id}       = $r->{Assay_ID};
        $assay_data{well_name}      = $r->{Well};
        $assay_data{deleted_region} = $r->{design_region};

        #check if we have one primer seq then we expect all?
        for my $seq ( qw( forward_primer_seq reverse_primer_seq reporter_probe_seq ) ) {
            $assay_data{$seq} = $r->{$seq} if $r->{$seq};
        }
        $self->add_assay_data( \%assay_data );
    }
}

sub _invalid_deleted_region {
    my ( $self, $deleted_region ) = @_;

    if ( none{ $_ eq lc($deleted_region) } @VALID_DELETED_REGIONS ) {
        $self->add_error("$deleted_region is not a valid deleted region");
        return 1
    }
    return;
}

sub _existing_assay_id {
    my ( $self, $assay_id ) = @_;
    my $assay = $self->schema->resultset('DesignTaqmanAssay')->find( { assay_id => $assay_id });
    if ( $assay ) {
        $self->add_error("Assay ID: $assay_id already exists in database on plate: "
            . $assay->taqman_plate->name );
        return 1;
    }
    return;
}

sub _existing_assay_well {
    my ( $self, $well ) = @_;

    my $assay = $self->plate->taqman_assays->find( { well_name => $well, } );

    if ( $assay ) {
        $self->add_error("There is already a $well well associated with plate: " .  $self->plate->name);
        return 1;
    }
    return;
}

sub _has_required_data {
    my ( $self, $r, $line ) = @_;
    my $error = 0;
    for my $field ( grep { $CSV_FIELDS{$_} } keys %CSV_FIELDS ) {
        unless ( $r->{$field} ) {
            $self->add_error("Line $line is missing required data: $field" );
            $error++;
        }
    }

    return $error ? 0 : 1;
}

sub _has_recognised_data {
    my ( $self, $csv_columns ) = @_;
    my $error = 0;

    for my $column_name ( @{ $csv_columns } ) {
        next if $column_name =~ /^\s*$/;
        unless ( exists $CSV_FIELDS{$column_name} ) {
            $self->add_error("Unrecognised column: $column_name" );
            $error++;
        }
    }

    return $error ? 0 : 1;
}

sub _get_design {
    my ( $self, $design_id ) = @_;
    my $design = $self->schema->resultset('Design')->find( { design_id => $design_id } );

    unless ($design) {
        $self->add_error( 'Could not find design: ' . $design_id );
        return 0;
    }

    return $design;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
