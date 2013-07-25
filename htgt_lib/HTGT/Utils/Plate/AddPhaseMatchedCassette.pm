package HTGT::Utils::Plate::AddPhaseMatchedCassette;

use Moose;
use namespace::autoclean;
use HTGT::Constants qw( %CASSETTES );

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,  
);

# XXX rm7 2012-01-24: the init_arg here is for
# backwards-compatibility, attribute was originally mis-named
# 'cassette', but I don't want to impose change on the callers
has phase_match_group_name => (
    is       => 'rw',
    isa      => 'Str',
    init_arg => 'cassette',
    required => 1,
    trigger  => \&_set_phase_match_group,
);

has phase_match_group => (
    is       => 'rw',
    isa      => 'HashRef',
    init_arg => undef,
    traits   => [ 'Hash' ],
    handles  => {
        get_phase_matched_cassette => 'get'
    },
);

sub _set_phase_match_group {
    my ( $self, $group_name ) = @_;

    my %phase_match_group;

    while ( my ( $cassette, $attrs ) = each %CASSETTES ) {        
        if ( $attrs->{phase_match_group} and $attrs->{phase_match_group} eq $group_name ) {
            my $phase = $attrs->{phase};
            confess "Configuration error detected: multiple phase $phase cassettes for $group_name"
                if $phase_match_group{$phase};
            $phase_match_group{$phase} = $cassette;
        }
    }

    confess "Phase match group $group_name not configured"
        unless keys %phase_match_group > 0;

    # Tony said to use phase 0 in place of phase k when no phase k cassette available
    # See <https://rt.sanger.ac.uk/Ticket/Display.html?id=227475>
    $phase_match_group{-1} ||= $phase_match_group{0};

    $self->phase_match_group( \%phase_match_group );    
}

has plate_id => (
    is       => 'ro',
    isa      => 'Int',
);

has plate => (
    is         => 'ro',
    isa        => 'HTGTDB::Plate',    
    lazy_build => 1,
);

sub _build_plate {
    my $self = shift;

    my $plate_id = $self->plate_id
        or confess "One of plate or plate_id must be specified in the constructor";
    
    my $plate = $self->schema->resultset( 'Plate' )->find(
        {
            'me.plate_id' => $plate_id
        },
        {
            prefetch => { 'wells' => [ 'well_data', { 'design_instance' => 'design' } ] }
        }
    ) or confess "Failed to retrieve plate with plate_id: $plate_id";

    return $plate;
}

has user => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has errors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => {
        add_error  => 'push',
        has_errors => 'count'
    }
);

has update_log => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => { add_update => 'push' }
);

sub add_phase_matched_cassette {
    my $self = shift;

    for my $well ( $self->plate->wells ) {
        my $new_cassette = $self->get_new_cassette( $well );
        next unless $new_cassette;
        
        my $current_cassette = $well->well_data_value( 'cassette' ) || '<undef>';
        next if $current_cassette eq $new_cassette;

        $self->add_update( "Well $well, cassette $current_cassette => $new_cassette");
        $well->related_resultset( 'well_data' )->update_or_create(
            {
                data_type  => 'cassette',
                data_value => $new_cassette,
                edit_user  => $self->user,
                edit_date  => \'current_timestamp'                    
            }
        );
    }
}

sub get_new_cassette {
    my ( $self, $well ) = @_;

    defined( my $design_phase = $self->get_design_phase( $well ) )
        or return;
    
    my $new_cassette = $self->get_phase_matched_cassette( $design_phase );
        
    unless ( $new_cassette ) {
        $self->add_error( "No phase $design_phase cassette available for group " . $self->phase_match_group_name );
        return;
    }

    return $new_cassette;
}

sub get_design_phase {
    my ( $self, $well ) = @_;

    return unless defined $well->design_instance_id;

    my $phase;
    if ( defined $well->design_instance->design->phase ) {
        $phase = $well->design_instance->design->phase;
    }
    elsif ( $well->design_instance->design->is_artificial_intron ) {
        $self->add_error( $well->well_name . " belongs to a artificial intron design with no phase");
        return;
    }
    else {
        $phase = $well->design_instance->design->start_exon->phase;            
    }

    unless ( defined $phase ) { 
        $self->add_error("Cannot determine phase for design on well $well");
        return;
    }

    return $phase;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
