package HTGT::Utils::SouthernBlot;

use Moose;
use Moose::Util::TypeConstraints;
use Bio::SeqIO;
use HTGT::Utils::TargRep::Genbank;
use HTGT::Utils::Restriction::Analysis;
use IO::File;
use IO::String;
use List::MoreUtils qw( firstval lastval any );
use Try::Tiny;
use namespace::autoclean;

require HTGT::Utils::SouthernBlot::Exception;
require HTGT::Utils::SouthernBlot::FragmentSizeFilter;
require HTGT::Utils::SouthernBlot::NullFragmentSizeFilter;

with 'MooseX::Log::Log4perl';

has es_clone_name => (
    is  => 'ro',
    isa => 'Str'
);

has max_fragment_size => (
    is      => 'ro',
    isa     => 'Int',
    default => 0
);

has tolerance_pct => (
    is      => 'ro',
    isa     => 'Int',
    default => 0
);

has tolerance_bp => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1
);

has probe_seq => (
    is        => 'ro',
    isa       => 'Bio::SeqI',
    predicate => 'has_probe_seq'
);

has probe => (
    is        => 'ro',
    isa       => enum( [ qw( custom NeoR LacZ3 LacZ5 ) ] ),
    predicate => 'has_probe',
    default   => 'custom',
);

has sequence => (
    is         => 'ro',
    isa        => 'Bio::SeqI',
    lazy_build => 1
);

has preferred_enzymes_file => (
    is         => 'ro',
    isa        => 'Str',
    default    => '/software/team87/brave_new_world/conf/southern-enzymes.conf'
);

has preferred_enzymes => (
    traits     => [ 'Hash' ],
    handles    => {
        is_preferred_enzyme => 'exists',
    },
    lazy_build => 1
);

has enzymes => (
    is        => 'ro',
    isa       => 'Bio::Restriction::EnzymeCollection',
    predicate => 'has_enzymes',
);

has [ qw( five_arm three_arm probe_loc ) ] => (
    is         => 'ro',
    isa        => 'Bio::LocationI',
    init_arg   => undef,
    lazy_build => 1
);

has restriction_enzymes => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1
);

has [ qw( threep_enzymes fivep_enzymes ) ] => (
    is         => 'ro',
    isa        => 'ArrayRef',
    init_arg   => undef,
    lazy_build => 1
);

sub _build_fivep_enzymes {
    shift->_sort_enzymes( 'fivep_enzymes' );    
}

sub _build_threep_enzymes {
    shift->_sort_enzymes( 'threep_enzymes' );
}

sub BUILD {
    my $self = shift;

    if ( $self->max_fragment_size > 0 ) {
        HTGT::Utils::SouthernBlot::FragmentSizeFilter->meta->apply( $self );        
    }
    else {
        HTGT::Utils::SouthernBlot::NullFragmentSizeFilter->meta->apply( $self );
    }

    confess "probe_seq must be specified for custom probes"
        if $self->probe eq 'custom' and not $self->has_probe_seq;    

    confess "probe_seq can only be specified for custom probes"
        if $self->has_probe_seq and $self->probe ne 'custom';    
    
    HTGT::Utils::SouthernBlot::Exception->throw( "G5/probe/G3 found in unexpected order" )
        unless $self->five_arm->start < $self->probe_loc->start
            and $self->probe_loc->end < $self->three_arm->end;
}

sub _build_five_arm {
    shift->_get_feature_loc( 'misc_feature', [ '5 arm'  ] );
}

sub _build_three_arm {
    shift->_get_feature_loc( 'misc_feature', [ '3 arm'] );
}

sub _build_probe_loc {
    my $self = shift;

    if ( $self->probe eq 'custom' ) {
        my $ix = index( $self->sequence->seq, $self->probe_seq->seq );
        HTGT::Utils::SouthernBlot::Exception->throw( "failed to locate probe sequence" )
                if $ix < 0;

        return Bio::Location::Simple->new(
            -start  => $ix + 1,
            -end    => $ix + $self->probe_seq->length,
            -strand => 1
        );
    }

    if ( $self->probe eq 'NeoR' ) {
        return $self->_get_feature_loc( 'gene', ['NeoR'] );
    }

    my $lacZ_loc = $self->_get_feature_loc( 'gene', ['lacZ'] );
    my $lacZ_size = $lacZ_loc->end - $lacZ_loc->start + 1;    
    
    if ( $self->probe eq 'LacZ3' ) {
        # Probe in 3' half of LacZ
        return Bio::Location::Simple->new(
            -start  => $lacZ_loc->start + int( $lacZ_size / 2 ),
            -end    => $lacZ_loc->end,
            -strand => 1
        );
    }

    if ( $self->probe eq 'LacZ5' ) {
        # Probe in 5' half of LacZ
        return Bio::Location::Simple->new(
            -start  => $lacZ_loc->start,
            -end    => $lacZ_loc->end - int( $lacZ_size / 2 ),
            -strand => 1
        );
    }

    confess "Unrecogized probe: " . $self->probe;    
}

sub _build_tolerance_bp {
    my $self = shift;

    my $probe_length = $self->probe_loc->end - $self->probe_loc->start + 1;

    int( $probe_length * $self->tolerance_pct / 100 );    
}

sub _build_sequence {
    my $self = shift;

    defined( my $es_clone_name = $self->es_clone_name )
        or HTGT::Utils::SouthernBlot::Exception->throw( "es_clone_name must be given when sequence is not supplied" );
    
    try {
        HTGT::Utils::TargRep::Genbank::fetch_allele_seq( $es_clone_name );
    }
    catch {
        $self->log->error( $_ );
        HTGT::Utils::SouthernBlot::Exception->throw( "failed to retrieve allele sequence for $es_clone_name" );
    };        
}

sub _build_restriction_enzymes {
    my $self = shift;

    my %ra_args = ( seq => $self->sequence );
    $ra_args{ enzymes } = $self->enzymes if $self->has_enzymes;
    my $ra = HTGT::Utils::Restriction::Analysis->new( \%ra_args );

    my ( %fivep_enzymes, %threep_enzymes );

    for my $enzyme ( map $_->name, $ra->cutters->each_enzyme ) {
        $self->log->debug( "Considering enzyme " . $enzyme );
        my @cuts = sort { $a <=> $b } $ra->positions( $enzyme );
        if ( my $fivep_cut = $self->_fivep_cut( $enzyme, \@cuts ) ) {
            $fivep_enzymes{ $enzyme } = $fivep_cut
                if $self->check_fragment_size( $fivep_cut->{fragment_size} );
        }
        if ( my $threep_cut = $self->_threep_cut( $enzyme, \@cuts ) ) {
            $threep_enzymes{ $enzyme } = $threep_cut
                if $self->check_fragment_size( $threep_cut->{fragment_size} );
        }
    }

    return {
        fivep_enzymes  => \%fivep_enzymes,
        threep_enzymes => \%threep_enzymes
    };
}

sub _fivep_cut {
    my ( $self, $enzyme, $cuts ) = @_;

    # Must not cut between G5 and the probe
    return if any { $_ >= $self->five_arm->start and $_ <= ( $self->probe_loc->end - $self->tolerance_bp ) } @{$cuts};
    
    # Should cut downstream of the probe
    my $probe_cut = firstval { $_ > ( $self->probe_loc->end - $self->tolerance_bp ) } @{$cuts};

    # Should cut upstream of G5
    my $g5_cut = lastval { $_ < $self->five_arm->start } @{$cuts};    

    # If we don't get a G5 and a probe cut, we can only give a lower bound on the fragment size
    my ( $fuzzy, $fuzzy_g5, $fuzzy_probe ) = ( '' ) x 3;
    
    unless ( defined $g5_cut ) {
        $g5_cut = 0;
        $fuzzy = $fuzzy_g5 = '>';
    }

    unless ( defined $probe_cut ) {
        $probe_cut = $self->sequence->length;
        $fuzzy = $fuzzy_probe = '>';        
    }

    my $fragment_size  = $probe_cut - $g5_cut + 1;
    my $distance_probe = $probe_cut - $self->probe_loc->end;
    my $distance_g5    = $self->five_arm->start - $g5_cut;    
    
    return {
        enzyme             => $enzyme,
        fragment_size      => $fuzzy . $fragment_size,
        distance_g5        => $fuzzy_g5 . $distance_g5,
        distance_probe     => $fuzzy_probe . $distance_probe,
        is_preferred       => $self->is_preferred_enzyme( $enzyme ) ? 'yes' : 'no',
        is_fuzzy           => $fuzzy ? 1 : 0,
        fragment_size_num  => $fragment_size,
        distance_probe_num => $distance_probe,
        distance_g5_num    => $distance_g5        
    };
}

sub _threep_cut {
    my ( $self, $enzyme, $cuts ) = @_;

    # Must not cut between the probe and G3
    return if any { $_ >= ( $self->probe_loc->start + $self->tolerance_bp ) and $_ <= $self->three_arm->end } @{$cuts};
    
    # Should cut upstream of the probe
    my $probe_cut = lastval { $_ < ( $self->probe_loc->start + $self->tolerance_bp ) } @{$cuts};

    # Should cut downstream of G3
    my $g3_cut = firstval { $_ > $self->three_arm->end } @{$cuts};

    # If we don't get a G3 or probe cut, we can only give a lower bound on the fragment size
    my ( $fuzzy, $fuzzy_g3, $fuzzy_probe ) = ( '' ) x 3;
    
    unless ( defined $g3_cut ) {
        $g3_cut = $self->sequence->length;
        $fuzzy = $fuzzy_g3 = '>';
    }

    unless ( defined $probe_cut ) {
        $probe_cut = 0;
        $fuzzy = $fuzzy_probe = '>';
    }

    my $fragment_size  = $g3_cut - $probe_cut + 1;
    my $distance_g3    = $g3_cut - $self->three_arm->end;
    my $distance_probe = $self->probe_loc->start - $probe_cut;
    
    return {
        enzyme             => $enzyme,
        fragment_size      => $fuzzy . $fragment_size,
        distance_g3        => $fuzzy_g3 . $distance_g3,
        distance_probe     => $fuzzy_probe . $distance_probe,
        is_preferred       => $self->is_preferred_enzyme( $enzyme ) ? 'yes' : 'no',
        is_fuzzy           => $fuzzy ? 1 : 0,
        fragment_size_num  => $fragment_size,
        distance_g3_num    => $distance_g3,
        distance_probe_num => $distance_probe,
    };
}

sub _get_feature_loc {
    my ( $self, $primary_tag, $search_labels ) = @_;

    for my $f ( $self->sequence->get_SeqFeatures ) {
        if ( $f->primary_tag eq $primary_tag ) {
            my @labels = $f->get_tag_values('note');
            for my $search_label ( @{ $search_labels } ) {
                return $f->location if any { $_ eq $search_label } @labels;
            }
        }
    }
    
    HTGT::Utils::SouthernBlot::Exception->throw( "failed to find $primary_tag/@{ $search_labels } in "  . $self->sequence->display_id );
}

sub _sort_enzymes {
    my ( $self, $type ) = @_;

    my $enzymes = $self->restriction_enzymes->{ $type };
    
    my @sorted = sort { $b->{is_preferred} cmp $a->{is_preferred}
                            || $a->{is_fuzzy} <=> $b->{is_fuzzy}
                                || $a->{fragment_size_num} <=> $b->{fragment_size_num} }
        values %{$enzymes};

    return \@sorted;    
}

sub _build_preferred_enzymes {
    my $self = shift;

    my %preferred_enzymes;

    my $filename = $self->preferred_enzymes_file;
    return \%preferred_enzymes
        unless defined $filename;

    my $ifh = IO::File->new( $filename, O_RDONLY )
        or confess "open $filename: $!";

    while ( my $d = $ifh->getline ) {
        for ( $d ) {
            s/#.*//;
            s/^\s+//;
            s/\s+$//;
        }
        next unless $d =~ /\S/;
        $preferred_enzymes{ $d }++;        
    }
    
    return \%preferred_enzymes;    
}

__PACKAGE__->meta->make_immutable;

1;

__END__
