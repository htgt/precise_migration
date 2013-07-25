package HTGT::Utils::Design::Validate;

use Moose;
use namespace::autoclean;
use Const::Fast;
use List::Util qw( min max );
use List::MoreUtils qw( any );
use HTGT::Utils::Design::Info;
use HTGT::Utils::Design::Validation::Error;

with 'MooseX::Log::Log4perl';

const my @KO_FEATURES  => qw( G5 U5 U3 D5 D3 G3 );
const my @INS_FEATURES => qw( G5 U5 D3 G3 );
const my @DEL_FEATURES => qw( G5 U5 U3 G3 );

const my %REQUIRED_FEATURES_FOR => (
    'KO'           => \@KO_FEATURES,
#    'Del_Block'    => \@DEL_FEATURES,
#    'Del_Location' => \@DEL_FEATURES,
#    'Ins_Block'    => \@INS_FEATURES,
#    'Ins_Location' => \@INS_FEATURES
);

const my %FILTER_REPEATS => (
    "G5"          => '__check_repeat_overlap',
    "U5"          => '__check_repeat_overlap',
    "U3"          => '__check_repeat_overlap',
    "D5"          => '__check_repeat_overlap',
    "D3"          => '__check_repeat_overlap',
    "G3"          => '__check_repeat_overlap',
    "G5 5' flank" => '__check_repeat_length',
    "G3 3' flank" => '__check_repeat_length',
);

has design => (
    is       => 'ro',
    isa      => 'HTGTDB::Design',
    required => 1
);

has design_type => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => sub { shift->design->design_type || 'KO' }
);

has min_constrained_element_score => (
    is      => 'ro',
    isa     => 'Int',
    default => 50
);

has min_repeat_overlap => (
    is      => 'ro',
    isa     => 'Int',
    default => 20
);

has min_repeat_length => (
    is      => 'ro',
    isa     => 'Int',
    default => 500
);

has G5_repeat_region_flank => (
    is      => 'ro',
    isa     => 'Int',
    default => 500
);

has G3_repeat_region_flank => (
    is      => 'ro',
    isa     => 'Int',
    default => 300
);

has design_info => (
    is         => 'ro',
    isa        => 'HTGT::Utils::Design::Info',
    init_arg   => undef,
    lazy_build => 1
);

has _required_features => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    init_arg => undef,
    default  => sub { $REQUIRED_FEATURES_FOR{ shift->design_type } },
    traits   => [ 'Array' ],
    handles  => {
        required_features => 'elements'
    }
);

has _errors => (
    is       => 'rw',
    isa      => 'ArrayRef[HTGT::Utils::Design::Validation::Error]',
    init_arg => undef,
    default  => sub { [] },
    traits   => [ 'Array' ],
    handles  => {
        _add_error => 'push',
        has_errors => 'count',
        errors     => 'elements',
    }
);

sub _build_design_info {
    my $self = shift;

    HTGT::Utils::Design::Info->new(
        design                 => $self->design,
        G5_repeat_region_flank => $self->G5_repeat_region_flank,
        G3_repeat_region_flank => $self->G3_repeat_region_flank
    );
}

sub add_error {
    my ( $self, $error_type, $error_mesg ) = @_;

    my $error = HTGT::Utils::Design::Validation::Error->new( type => $error_type, mesg => $error_mesg );    
    $self->_add_error( $error );
}

sub has_fatal_error {
    my $self = shift;

    any { $_->is_fatal } $self->errors;    
}

sub BUILD {
    my $self = shift;

    my $type = $self->design_type;    
    confess "Unsupported design_type: $type"
        unless exists $REQUIRED_FEATURES_FOR{$type};
    
    for ( qw( required_features feature_order floxed_exons constrained_elements repeat_regions ) ) {
        my $check = "_check_$_";
        $self->$check;
        last if $self->has_fatal_error;
    }
}

sub _check_required_features {
    my $self = shift;

    $self->log->debug( "check expected features present" );
    
    my $features = $self->design_info->features;

    for my $feature_name ( $self->required_features ) {
        my $feature = $features->{ $feature_name };
        $self->log->debug( "check $feature_name exists" );
        unless ( $feature ) {
            $self->add_error( "missing_feature", "missing feature $feature_name" );
            next;            
        }
        $self->log->debug( "check $feature_name start/end" );
        unless ( $feature->feature_start < $feature->feature_end ) {
            $self->add_error( "invalid_feature", "$feature_name feature_start >= feature_end" );
        }
    }
}

sub _check_feature_order {
    my $self = shift;

    $self->log->debug( "check feature order" );
    
    my $features = $self->design_info->features;

    my @order = $self->design_info->chr_strand == 1 ? $self->required_features
              :                                        reverse $self->required_features;

    while ( my $this = shift @order ) {
        my $next = $order[0] or last;
        $self->log->debug( "check $this end <= $next start" );
        unless ( $features->{$this}->feature_end <= $features->{$next}->feature_start ) {
            $self->add_error( "feature_order", "$this end > $next start" );
        }
    }
}

sub _check_floxed_exons {
    my $self = shift;

    $self->log->debug(  "check floxed exons" );

    unless ( $self->design_info->num_floxed_exons > 0 ) {        
        $self->add_error( "floxed_exon", "no floxed exons" );
    }
}

sub _check_constrained_elements {
    my $self = shift;

    $self->log->debug( "check constrained elements" );
    
    my $constrained_elements = $self->design_info->constrained_elements;

    while ( my ( $region, $ce ) = each %{ $constrained_elements } ) {
        $self->log->debug( "check for constrained elements in $region region" );
        my @ce = grep $_->{score} >= $self->min_constrained_element_score, @{$ce}
            or next;
        for ( @ce ) {
            $self->add_error( "constrained_element",
                              sprintf( "constrained element in %s region: start: %d, end: %d, score: %d",
                                       $region, $_->{start}, $_->{end}, $_->{score} ) );
        }
    }
}

sub _check_repeat_regions {
    my $self = shift;
    
    $self->log->debug( "check repeat regions" );

    my $repeat_regions = $self->design_info->repeat_regions;

    while ( my ( $region, $repeats ) = each %{ $repeat_regions } ) {
        $self->log->debug( "check for repeats in $region region" );
        my $wanted = $FILTER_REPEATS{ $region };        
        for my $r ( grep $self->$wanted($_), @{ $repeats } ) {
            $self->add_error( "repeat_region",
                              sprintf( "repeats found in %s region: start: %d, end: %d, score: %d, class: %s, type: %s",
                                       $region, map $r->{$_}, qw( start end score class type ) ) );
        }
    }
}
        
sub __check_repeat_overlap {
    my ( $self, $repeat ) = @_;    
    
    my $start = max(  0, $repeat->{start} );
    my $end   = min( 50, $repeat->{end}   ); # Assume 50bp oligo
    
    $end - $start >= $self->min_repeat_overlap;    
}

sub __check_repeat_length {
    my ( $self, $repeat ) = @_;
    
    $repeat->{end} - $repeat->{start} >= $self->min_repeat_length;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
