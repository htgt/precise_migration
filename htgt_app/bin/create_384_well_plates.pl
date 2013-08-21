#!/usr/bin/env perl
#
# $Id: create_384_well_plates.pl,v 1.6 2009-09-23 15:22:12 rm7 Exp $

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use IO::File;
use Log::Log4perl ':easy';
use Pod::Usage;
use Readonly;

Readonly my $PLATE_TYPE => 'PGD';
Readonly my $USER       => $ENV{ USER };

GetOptions(
    'help'               => sub { pod2usage( -verbose => 1 ) },
    'man'                => sub { pod2usage( -verbose => 2 ) },
    'commit'             => \my $commit,
    'insert-empty-wells' => \my $insert_empty_wells,
    'include=s'          => \my $include,
    'exclude=s'          => \my $exclude,
) or pod2usage( 2 );

my $vector_qc = HTGT::DBFactory->connect( 'vector_qc', { FetchHashKeyName => 'NAME_uc' } );
my $htgt  = HTGT::DBFactory->connect( 'eucomm_vector', { FetchHashKeyName => 'NAME_uc' } );

Log::Log4perl->easy_init( { level => $DEBUG, layout => '%p %m%n' } );

my @plate_names = $include ? names_from_file( $include ) : @ARGV;
if ( $exclude ) {
    my %is_excluded = map { $_ => 1 } names_from_file( $exclude );
    @plate_names = grep !$is_excluded{ $_ }, @plate_names;
}

my $plates = get_plates_to_create( @plate_names );

foreach my $plate ( @{ $plates } ) {
    my ( $plate_name, $design_plate_name, $qctest_run_id, $num_clones ) = @{ $plate };
    DEBUG( "Considering $plate_name" );
    my $exists = $htgt->resultset( 'HTGTDB::Plate' )->search( { name => { like => $plate_name . '_%' } } );
    if ( $exists->count > 0 ) {
        WARN( "Skipping already-existing plate " . $plate_name );
        next;
    }
    my $related_wells = get_related_wells_by_clone_name( $plate_name );
    dump_related_wells( $related_wells );
    unless ( @{ $related_wells } ) {
        ERROR( "No wells found containing clones from $plate_name" );
        next;
    }
    DEBUG( @{ $related_wells } . " related wells for ${plate_name}" );
    eval { $htgt->txn_do( \&create_plate_iterates, $plate_name, $qctest_run_id, $num_clones, $related_wells ); };
    WARN( $@ ) if $@;
}

sub create_plate_iterates {
    my ( $plate_name, $qctest_run_id, $num_clones, $related_wells ) = @_;
    foreach my $iteration ( 1 .. $num_clones ) {
        create_plate( $plate_name . '_' . $iteration, $qctest_run_id, $related_wells );
    }
    die "Rollback $plate_name\n" unless $commit;
}

sub create_plate {
    my ( $plate_name, $qctest_run_id, $related_wells ) = @_;

    INFO( "creating plate: $plate_name" );
    my $plate_obj = $htgt->resultset( 'HTGTDB::Plate' )->create(
        {
            name         => $plate_name,
            type         => $PLATE_TYPE,
            created_user => $USER,
            created_date => \"current_timestamp",
            edited_user  => $USER,
            edited_date  => \"current_timestamp"
        }
    ) or die "failed to create plate $plate_name: $@";

    my @pcs_plates = get_pcs_plates( $related_wells )
        or die "failed to determine PCS plates for $plate_name";

    foreach my $parent_plate ( @pcs_plates ) {
        DEBUG( "inserting parent plate relation: " . $parent_plate->name . '/' . $plate_obj->name );
        $htgt->resultset( 'HTGTDB::PlatePlate' )->create(
            {
                parent_plate_id => $parent_plate->plate_id,
                child_plate_id  => $plate_obj->plate_id,
            }
        ) or die "failed to create parent plate relation " . $parent_plate->name . ": $@";
    }

    DEBUG( "Creating is_384 plate data for:" . $plate_obj->plate_id );
    $htgt->resultset( 'HTGTDB::PlateData' )->create(
        {
            plate_id   => $plate_obj->plate_id,
            data_type  => 'is_384',
            data_value => 'yes',
            edit_user  => $USER,
            edit_date  => \"current_timestamp"
        }
    ) or die "failed to create is_384 plate_data for " . $plate_obj->name . ": $@";

    foreach my $row ( 'A' .. 'H' ) {
        foreach my $col ( 1 .. 12 ) {
            my $well_name = sprintf( '%s%02d', $row,             $col );
            my $well_desc = sprintf( '%s[%s]', $plate_obj->name, $well_name );
            my @related_wells = grep $_->well_name =~ /$well_name/, @{ $related_wells };

            #dump_related_wells( \@related_wells );
            my $design_instance_id = unique( map $_->design_instance_id, @related_wells );
            if ( $design_instance_id ) {
                my $parent_well_id = unique( map $_->parent_well_id, @related_wells )
                    or die "failed to determine parent_well_id for $well_desc";
                my $cassette = unique( map $_->well_data_value( 'cassette' ), @related_wells )
                    or die "failed to determine cassette for $well_desc";
                my $backbone = unique( map $_->well_data_value( 'backbone' ), @related_wells )
                    or die "failed to determine backbone for $well_desc";

                DEBUG( "Creating well: $well_desc with di $design_instance_id, parent $parent_well_id" );

                my $well = $htgt->resultset( 'HTGTDB::Well' )->create(
                    {
                        plate_id           => $plate_obj->plate_id,
                        well_name          => $well_name,
                        design_instance_id => $design_instance_id,
                        parent_well_id     => $parent_well_id,
                        edit_user          => $USER,
                        edit_date          => \"current_timestamp"
                    }
                ) or die "failed to create well: $well_desc";

                DEBUG( "Setting cassette to: $cassette" );
                $well->well_data->create( { data_type => 'cassette', data_value => $cassette }, { key => 'well_id_data_type' } )
                    or die "create cassette well_data for $well_desc failed: $@";

                DEBUG( "Setting backbone to: $backbone" );
                $well->well_data->create( { data_type => 'backbone', data_value => $backbone }, { key => 'well_id_data_type' } )
                    or die "create backbone well_data for $well_desc failed: $@";
            }
            elsif ( $insert_empty_wells ) {
                WARN( "inserting empty well $well_desc" );
                $htgt->resultset( 'HTGTDB::Well' )->create(
                    {
                        plate_id           => $plate_obj->plate_id,
                        well_name          => $well_name,
                        edit_user          => $USER,
                        edit_date          => \"current_timestamp"
                    }
                );
            }
            else {
                die "failed to determine design_instance_id for $well_desc";
            }
        }
    }

    DEBUG( "Loading QC results for QC run: $qctest_run_id" );
    $plate_obj->load_384well_qc(
        {
            qc_schema     => $vector_qc,
            user          => $USER,
            qctest_run_id => $qctest_run_id,
            log           => \&DEBUG,
        }
    );
}

sub get_plates_to_create {
    my ( @plate_names ) = @_;

    my $placeholders = join q{,}, ( '?' ) x @plate_names;

    $vector_qc->storage->dbh->selectall_arrayref( <<"EOT", undef, @plate_names );
select clone_plate, design_plate,
       qctest_run_id,
       max(clone_number) as num_clones
from qctest_run qr1 left join construct_clone on clone_plate = plate
where stage = 'post_gateway'
and clone_plate in ( $placeholders )
and qctest_run_id in (select max(qctest_run_id) from qctest_run qr2 where qr1.clone_plate = qr2.clone_plate )
group by clone_plate, design_plate, qctest_run_id
order by clone_plate, qctest_run_id
EOT
}

sub get_related_wells_by_clone_name {
    my ( $plate_name ) = @_;

    my $plate_rs = $htgt->resultset( 'HTGTDB::Plate' )->search(
        {
            'me.type'              => 'PGD',
            'me.name'              => { 'not like' => $plate_name . '%' },
            'well_data.data_type'  => 'clone_name',
            'well_data.data_value' => { 'like' => $plate_name . '%' },
        },
        { join => { wells => 'well_data' } }
    );

    my %uniq_plates;
    while ( my $p = $plate_rs->next ) {
        $uniq_plates{ $p->name } = $p;
    }

    [ map $_->wells, values %uniq_plates ];
}

#{ Debugging only
sub dump_related_wells {
    my ( $related_wells ) = @_;
    my @data = map [ map { defined( $_ ) ? $_ : "" } $_->well_data_value( 'clone_name' ),
        $_->plate->name, $_->well_name, $_->design_instance_id,
        $_->well_data_value( 'cassette' ),
        $_->well_data_value( 'backbone' ),
        ],
        @{ $related_wells };

    foreach my $well ( sort { $a->[ 0 ] cmp $b->[ 0 ] } @data ) {
        DEBUG( join "\t", "===>", @{ $well } );
    }
}

#}

sub get_pcs_plates {
    my ( $wells ) = @_;

    my %pcs_plates;

    foreach my $w ( @{ $wells } ) {
        my $this_well = $w;
        while ( $this_well and $this_well->plate->type ne 'PCS' ) {
            $this_well = $this_well->parent_well;
        }
        $pcs_plates{ $this_well->plate->name } = $this_well->plate
            if $this_well and $this_well->plate;
    }

    values %pcs_plates;
}

sub names_from_file {
    my ( $filename ) = @_;
    my $ifh = IO::File->new( $filename, O_RDONLY )
        or die "open $filename: $!";
    map { chomp; $_ } $ifh->getlines;
}

sub unique {
    my %seen;
    $seen{ $_ }++ for grep defined, @_;
    my @uniq = keys %seen;
    if ( @uniq == 1 ) {
        return shift @uniq;
    }
    DEBUG( "unique values: @uniq" );
    return;
}

__END__

=head1 NAME

create_384_well_plates

=head1 SYNOPSIS

    create_384_well_plates [--commit] PLATE [PLATE ...]

=cut
