package HTGT::Utils::Plate::Create;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/trunk/lib/HTGT/Utils/Plate/Create.pm $
# $LastChangedRevision: 7441 $
# $LastChangedDate: 2012-07-03 15:05:02 +0100 (Tue, 03 Jul 2012) $
# $LastChangedBy: rm7 $

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'create_plate' ] };
use Iterator;
use Iterator::Util 'imap';
use List::MoreUtils 'uniq';
use Readonly;

Readonly my $PC_CLONE_NAME_RX => qr{
    ^
    (PC\S+)       # plate
    _
    ([A-H]\d\d)   # well
    _
    \d+           # iteration
    \s*
    $
}x;

Readonly my $PCS_CLONE_NAME_RX => qr{
    ^
    (PCS\S+)       # plate
    _
    ([A-H]\d\d)    # well
    _
    \d+            # iteration
    \s*
    $
}x;

Readonly my $CLONE_NAME_RX => qr{
    ^
    (\S+)       # plate
    _
    ([A-H]\d\d) # well
    _
    (\d+)       # iteration
    \s*
    $
}x;

Readonly my $PLATE_WELL_RX => qr{
  ^
  (\S+)                # plate name
  \[
  ((?:\w+_)?[A-H]\d\d) # well name
  \]
  \s*
  $
}x;

# Specification for creating a plate of the given type
# wells         - the number wells on this plate
# inherit       - well_data to inherit from the parent plate
# include_plate - include the plate name in the well name

Readonly my %SPEC_FOR => (
    EP   => { wells => 25, inherit => [ 'cassette' ], include_plate => 1 },
    EPD  => { wells => 96, inherit => [ 'cassette' ], include_plate => 1 },
    REPD => { wells => 96, inherit => [ 'cassette' ], include_plate => 1 },
    FP   => { wells => 96, inherit => [ 'cassette' ], include_plate => 1 },
    GRD  => { wells => 96, inherit => [ 'cassette', 'backbone' ] },
    GRQ  => { wells => 96, inherit => [ 'cassette', 'backbone' ] },
    GT   => { wells => 96, inherit => [ 'cassette', 'backbone' ] },
    PGG  => { wells => 96, inherit => [ 'cassette', 'backbone' ] },
    VTP  => { wells => undef, inherit => [ 'cassette', 'backbone' ] },
    PCS  => { wells => 96, inherit => [] },
    PGD  => { wells => 96, inherit => [] },
    GR   => { wells => 96, inherit => [] },
);

sub create_plate {
    my ( $schema,  %args ) = @_;

    for ( qw( plate_name plate_type plate_data created_by ) ) {
        die "$_ not specified\n"
            unless defined $args{$_};
    }

    my $spec = $SPEC_FOR{ $args{plate_type} }
        or die "Invalid plate type: $args{plate_type}\n";
    
    my $plate;

    die "Plate $args{plate_name} already exists\n"
        if $schema->resultset( 'Plate' )->find( { name => $args{plate_name} } );
            
    my @parent_wells  = map get_well( $schema, $_ ), @{ $args{plate_data} };
    my $num_wells = @parent_wells;
    
    die "Expected $spec->{wells} wells for plate of type $args{plate_type}, but got $num_wells\n"
        if defined $spec->{wells} and $num_wells != $spec->{wells};

    # Create the plate
    $plate = insert_plate( $schema, \%args );

    # Create parent plates
    my @parent_plate_ids = uniq map $_->plate_id, grep defined, @parent_wells;            
    insert_plate_plate( $schema, $plate->plate_id, @parent_plate_ids ); 
    
    # Create wells and inherited well_data
    my $well_name = well_name_iterator( $spec->{wells}, $spec->{include_plate}, $plate->name );
    while ( @parent_wells ) {
        insert_well( $plate, $well_name->value, shift @parent_wells, $spec->{inherit}, $args{created_by} );                
    }
    
    return $plate;
}

sub insert_plate {
    my ( $schema, $args ) = @_;

    $schema->resultset( 'Plate' )->create(
        {
            name         => $args->{plate_name},
            type         => $args->{plate_type},
            created_user => $args->{created_by},
            edited_user  => $args->{created_by},
            created_date => \'current_timestamp',
            edited_date  => \'current_timestamp',
        }
    );
}

sub insert_plate_plate {
    my ( $schema, $plate_id, @parent_plate_ids ) = @_;

    for my $parent_plate_id ( @parent_plate_ids ) {
        $schema->resultset( 'PlatePlate' )->create(
            {
                parent_plate_id => $parent_plate_id,
                child_plate_id  => $plate_id
            }
        );        
    }
}

sub insert_well {
    my ( $plate, $well_name, $parent_well, $inherit, $created_by ) = @_;

    if ( not defined $parent_well ) {
        $plate->wells_rs->create(
            {
                well_name => $well_name,
                edit_user => $created_by,
                edit_date => \'current_timestamp'
            }
        );
        return;        
    }
    
    my $well = $plate->wells_rs->create(
        {
            well_name          => $well_name,
            parent_well_id     => $parent_well->well_id,            
            design_instance_id => $parent_well->design_instance_id,
            edit_user          => $created_by,
            edit_date          => \'current_timestamp'
        }
    );

    for my $data_type ( @{ $inherit } ) {
        defined( my $data_value = $parent_well->well_data_value( $data_type ) )
            or next;
        $well->well_data_rs->create(
            {
                data_type  => $data_type,
                data_value => $data_value,
                edit_user  => $created_by,
                edit_date  => \'current_timestamp'
            }
        );
    }
}

sub get_well {
    my ( $schema, $data ) = @_;

    my ( $plate_name, $well_name ) = parse_plate_well( $data )
        or die "Invalid well specification: " . join( q{, }, @{ $data } ) . "\n";

    return undef if is_empty( $plate_name ) or is_empty( $well_name );
    
    my $well = $schema->resultset( 'Well' )->find(
        {
            'plate.name' => $plate_name,
            'well_name'  => $well_name,
        },
        {
            join => 'plate'
        }
    ) or die "Failed to retrieve well: $plate_name\[$well_name\]\n";    

    return $well;
}

sub is_empty {
    my ( $name ) = @_;

    return 1 unless defined $name and length $name > 0;

    return 1 if $name eq '-';

    return;
}

sub parse_plate_well {
    my ( $data ) = @_;

    if ( @{ $data } == 2 ) {
        return @{ $data };
    }

    return unless @{ $data } == 1;

    if ( $data->[0] eq '' or $data->[0] eq '-' ) { # empty well
        return ( '-', '-' );         
    }
    
    if ( my ( $plate_name, $well_name ) = $data->[0] =~ $PLATE_WELL_RX ) {
        return ( $plate_name, $well_name ); 
    }

    # Special case for PCS clones: ignore the iteration, as the 384-well
    # PCS plates are not in the database
    if ( my ( $plate_name, $well_name ) = $data->[0] =~ $PCS_CLONE_NAME_RX ) {
        return ( $plate_name, $well_name );        
    }

    # Special case for PC clones: ignore the iteration, and pretend they
    # are on a PCS plate
    if ( my ( $plate_name, $well_name ) = $data->[0] =~ $PC_CLONE_NAME_RX ) {
        $plate_name =~ s/^PC/PCS/;
        return ( $plate_name, $well_name );
    }
    
    if ( my ( $plate_name, $well_name, $iteration ) = $data->[0] =~ $CLONE_NAME_RX ) {
        $plate_name = $plate_name . '_' . $iteration; 
        return ( $plate_name, $well_name );        
    }

    return;
}

sub well_name_iterator {
    my ( $num_wells, $include_plate_name, $plate_name ) = @_;

    my ( $last_row, $last_col );

    if ( ! $num_wells ) {
        my $count = 1;
        return Iterator->new( sub { $count++ } );
    }
    elsif ( $num_wells == 25 ) {
        $last_row = 'E';
        $last_col = 5;
    }
    elsif ( $num_wells == 96 ) {
        $last_row = 'H';
        $last_col = 12;
    }

    my $row = 'A';
    my $col = 1;

    my $it = Iterator->new(        
        sub {
            if ( $col > $last_col ) {
                Iterator::is_done() if $row eq $last_row;
                $row++;
                $col = 1;
            }
            sprintf( '%s%02d', $row, $col++ );
        }
    );

    if ( $include_plate_name ) {
        return imap { $plate_name . '_' . $_ } $it;
    }
    else {
        return $it;        
    }
}

1;

__END__
