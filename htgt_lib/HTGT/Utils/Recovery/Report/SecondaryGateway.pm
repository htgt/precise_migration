package HTGT::Utils::Recovery::Report::SecondaryGateway;

use Moose;
use namespace::autoclean;
use Iterator::Util 'ilist';
use List::MoreUtils 'any';
use Readonly;

Readonly my @PCS_PLATE_TYPES => qw( PCS );
Readonly my @PG_PLATE_TYPES  => qw( PGD PGR GR GRD );

with qw( HTGT::Utils::Report::GenericIterator MooseX::Log::Log4perl );

has plate_name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1
);

has vector_qc_schema => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1
);

sub _build_name {    
    "Secondary Gateway Candidates for " . shift->plate_name;    
}

sub _build_columns {
    [
        qw( pcs_plate_name pcs_well_name pcs_pass_level pcs_primers pg_plate_name pg_well_name pg_pass_level pg_primers )
    ]
}

sub _build_iterator {
    my $self = shift;  

    my $plate_name = $self->plate_name;       
    my @plates = $self->schema->resultset( 'Plate' )->search( { name => { like => $plate_name . '%' } } )
        or confess "plate $plate_name not found\n";

    my ( @data, %seen );

    for my $design_well ( map $self->_get_design_well( $_ ), map $_->wells, @plates ) {
        next unless $design_well->design_instance_id;
        my @descendants = $self->_get_descendants( $design_well );
    PCS_WELL:
        for my $pcs_well ( grep $self->_is_pcs_well( $_ ), @descendants ) {
            next if $seen{ "$pcs_well" }++;
            next unless $pcs_well->design_instance_id;
            my $pcs_primers = $self->_get_valid_primers( $pcs_well );            
            for my $pg_well ( grep $self->_is_pg_well( $_ ), @descendants ) {
                next unless $pg_well->design_instance_id;
                my $pass_level = $pg_well->well_data_value( 'pass_level' );
                next PCS_WELL if $pass_level and $pass_level =~ /^pass/;
                my $pg_primers = $self->_get_valid_primers( $pg_well );
                push @data, {
                    pcs_plate_name => $pcs_well->plate->name,
                    pcs_well_name  => $pcs_well->well_name,
                    pcs_pass_level => $pcs_well->well_data_value( 'pass_level' ) || '',
                    pcs_primers    => $self->_stringify_primers( $pcs_primers ),
                    pg_plate_name  => $pg_well->plate->name,
                    pg_well_name   => $pg_well->well_name,
                    pg_pass_level  => $pg_well->well_data_value( 'pass_level' ) || '',
                    pg_primers     => $self->_stringify_primers( $pg_primers )
                } if $pcs_primers->{lr} or $pcs_primers->{lrr} or $pg_primers->{lr} or $pg_primers->{lrr};
            }
        }
    }

    return ilist sort { $a->{pcs_plate_name} cmp $b->{pcs_plate_name }
                            || $a->{pcs_well_name} cmp $b->{pcs_well_name} } @data;
}

sub _stringify_primers {
    my ( $self, $primers ) = @_;

    uc join( q{ }, sort keys %{ $primers } );
}

sub _get_design_well {
    my ( $self, $well ) = @_;

    do {
        return $well if $well->plate->type eq 'DESIGN';
        $well = $well->parent_well;
    } while ( $well );

    return;
}

sub _get_descendants {
    my ( $self, $well ) = @_;

    my @children = $well->child_wells;

    ( @children, map $self->_get_descendants( $_ ), @children );
}

sub _is_pcs_well {
    my ( $self, $well ) = @_;
    my $plate_type = $well->plate->type;
    any { $plate_type eq $_ } @PCS_PLATE_TYPES;
}

sub _is_pg_well {
    my ( $self, $well ) = @_;
    my $plate_type = $well->plate->type;
    any { $plate_type eq $_ } @PG_PLATE_TYPES;
}

sub _get_valid_primers {
    my ( $self, $well ) = @_;

    my $qctest_result_id = $well->well_data_value( 'qctest_result_id' );
    unless ( defined $qctest_result_id ) {
        $self->log->info( "$well: no QC test result id" );
        return {};
    }

    my $qctest_result = $self->vector_qc_schema->resultset( 'QctestResult' )->find(
        {
            qctest_result_id => $qctest_result_id
        }
    );

    unless ( $qctest_result ) {
        $self->log->warn( "$well: QC test result $qctest_result_id not found" );
        return {};
    }

    my %valid_primers;
    
    foreach my $primer ( $qctest_result->qctestPrimers ) {
        my $primer_name = lc( $primer->primer_name );
        my $seq_align_feature = $primer->seqAlignFeature
            or next;
        my $loc_status = $seq_align_feature->loc_status
            or next;
        $valid_primers{ $primer_name } = 1        
            if $loc_status eq 'ok';
    }

    return \%valid_primers;
}

1;

__END__
