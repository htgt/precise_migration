#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use IO::File;
use Log::Log4perl ':easy';
use Pod::Usage;
use Const::Fast;
use Perl6::Slurp;
use Try::Tiny;
use List::MoreUtils qw( uniq );

my $loglevel         = $INFO;
const my $PLATE_TYPE => 'PC';
const my $USER       => $ENV{ USER };

GetOptions(
    'help'     => sub { pod2usage( -verbose => 1 ) },
    'man'      => sub { pod2usage( -verbose => 2 ) },
    'debug'    => sub { $loglevel = $DEBUG },
    'commit'   => \my $commit,
    'plate=s'  => \my $plate_name
)   or pod2usage( 2 );

my $vector_qc = HTGT::DBFactory->connect( 'vector_qc',     { FetchHashKeyName => 'NAME_uc' } );
my $htgt      = HTGT::DBFactory->connect( 'eucomm_vector', { FetchHashKeyName => 'NAME_uc' } );

Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %m%n' } );

my @plate_names;
if ($plate_name) {
    push @plate_names, $plate_name;
}
else {
    @plate_names = split( /\n/, slurp $ARGV[0]);
}

foreach my $plate_name ( @plate_names ) {
    INFO( "Considering $plate_name" );

    my $exists = $htgt->resultset( 'Plate' )->search( { name => { like => $plate_name . '_%' } } );
    if ( $exists->count > 0 ) {
        WARN( "Skipping already-existing plate " . $plate_name );
        next;
    }

    $htgt->txn_do(
        sub {
            try{
                for my $iterate ( get_plate_iterates($plate_name) ) {
                    my $wells = get_plate_wells( $plate_name, $iterate );
                    create_pc_plate($plate_name, $iterate, $wells);
                }
                
                unless ($commit) {
                    $htgt->txn_rollback;
                }
            }
            catch {
                WARN('Error creating plate: ' . $_ );
                $htgt->txn_rollback;
            };
        }
    );
}

sub get_plate_iterates{
    my $plate_name = shift;
    
    my @clones = $vector_qc->resultset('ConstructClone')->search(
        {
            plate => $plate_name
        },
        {
            columns => [ 'clone_number' ],
            distinct => 1,
        }
    );
    my @iterates = map{ $_->clone_number } @clones;
    my $num_iterates = @iterates;

    if ($num_iterates % 4) {
        die"Number of iterates $num_iterates not multiple of 4";
    }
    else {
        return @iterates;
    }
}

sub create_pc_plate {
    my ( $plate_name, $iterate, $wells ) = @_;
    my $plate_name_384 = $plate_name . '_' . $iterate;
    
    INFO( "creating plate: $plate_name_384" );
    my $plate = $htgt->resultset( 'Plate' )->create(
        {
            name         => $plate_name_384,
            type         => $PLATE_TYPE,
            created_user => $USER,
            created_date => \"current_timestamp",
            edited_user  => $USER,
            edited_date  => \"current_timestamp"
        }
    ) or die "failed to create plate $plate_name_384: $@";
    
    my @design_plates = get_parent_design_plates( $wells );

    foreach my $parent_plate_name ( @design_plates ) {
        my $parent_plate = $htgt->resultset('Plate')->find( { name => $parent_plate_name } );
        die "Parent plate $parent_plate_name does not exist" unless $parent_plate;
        DEBUG( "inserting parent plate relation: " . $parent_plate->name . '/' . $plate->name );
        $htgt->resultset( 'PlatePlate' )->create(
            {
                parent_plate_id => $parent_plate->plate_id,
                child_plate_id  => $plate->plate_id,
            }
        ) or die "failed to create parent plate relation " . $parent_plate->name . ": $@";
    }
    
    DEBUG( "Creating is_384 plate data for:" . $plate->plate_id );
    $htgt->resultset( 'PlateData' )->create(
        {
            plate_id   => $plate->plate_id,
            data_type  => 'is_384',
            data_value => 'yes',
            edit_user  => $USER,
            edit_date  => \"current_timestamp"
        }
    ) or die "failed to create is_384 plate_data for " . $plate->name . ": $@";
    
    create_pc_wells( $wells, $plate );
    
    my $plate_qctest_run_id = get_qctest_run_id( $wells );
    INFO( "Loading QC results for $plate_name_384 QC run: $plate_qctest_run_id" );
    
    $plate->load_384well_qc(
        {
            qc_schema     => $vector_qc,
            user          => $USER,
            qctest_run_id => $plate_qctest_run_id,
            log           => \&DEBUG,
        }
    );
}

sub get_qctest_run_id {
    my ( $wells ) = @_;
    
    return $wells->[0][4];
}

sub create_pc_wells {
    my ( $wells, $plate ) = @_;

    my $well_number = scalar(@{ $wells });
    die "We have $well_number wells to load, not 96" unless $well_number == 96;

    foreach my $well ( @{ $wells } ) {
        my ( $clone_name, $plate_name, $well_name, $clone_number, $qctest_run_id, $design_plate, $design_well ) = @{ $well };
        my $well_desc  = sprintf( '%s[%s]', $plate->name, $well_name );
        
        my $parent_well = $htgt->resultset('Well')->find(
            {
                well_name    => $design_well,
                'plate.name' => $design_plate,
                'plate.type' => 'DESIGN',
            },
            {
                join => 'plate'
            }
        );

        my $design_instance_id = $parent_well->design_instance_id;
        die "failed to determine design_instance_id for $well_desc" unless $design_instance_id;
        
        DEBUG( "Creating well: $well_desc with di $design_instance_id, parent " . $parent_well->well_id );
        my $pc_well = $htgt->resultset( 'Well' )->create(
            {
                plate_id           => $plate->plate_id,
                well_name          => $well_name,
                design_instance_id => $design_instance_id,
                parent_well_id     => $parent_well->well_id,
                edit_user          => $USER,
                edit_date          => \"current_timestamp"
            }
        ) or die "failed to create well: $well_desc";
    }
    
    INFO( "Loaded $well_number wells for " . $plate->name );
}

sub get_parent_design_plates {
    my $wells = shift;
    
    return uniq map{ $_->[5] } @{ $wells };
}



sub get_plate_wells {
    my ( $plate_name, $iterate )  = @_;

    my $sql = <<EOT;    
SELECT
distinct construct_clone.name, construct_clone.plate, construct_clone.well, construct_clone.clone_number, qctest_result.qctest_run_id,
synthetic_vector.design_plate, synthetic_vector.design_well                                                                                                                                                                                 
FROM
construct_clone                                                                                                                                                                          
inner join qctest_result on construct_clone.construct_clone_id = qctest_result.construct_clone_id                                                                                                                
inner join engineered_seq on engineered_seq.engineered_seq_id = qctest_result.engineered_seq_id                                                                                                                                                               
inner join synthetic_vector on synthetic_vector.engineered_seq_id = engineered_seq.engineered_seq_id                                                                                                                                                                
WHERE                                                                                                                                                                                         
qctest_result.is_best_for_construct_in_run = 1
and qctest_result.is_valid is not null
and construct_clone.plate = ?
and construct_clone.clone_number = ?
and qctest_result.qctest_run_id = ( 
  select max(qctest_run_id) 
  from qctest_result inner join construct_clone on construct_clone.construct_clone_id = qctest_result.construct_clone_id
  where construct_clone.plate = ?
    and construct_clone.clone_number = ? )
ORDER BY 1
EOT

    my $sth = $vector_qc->storage()->dbh()->prepare( $sql );
    $sth->bind_param( 1, $plate_name );
    $sth->bind_param( 2, $iterate );
    $sth->bind_param( 3, $plate_name );
    $sth->bind_param( 4, $iterate );
    $sth->execute;
    my $plate_wells = $sth->fetchall_arrayref;

    return @{ $plate_wells } ? $plate_wells : undef;
}

__END__

=head1 NAME

create_384_well_PC_plate

=head1 SYNOPSIS



=cut
