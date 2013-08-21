package HTGT::Utils::TaqMan::Design;

use Moose;
use namespace::autoclean;
use Const::Fast;
use List::MoreUtils qw( uniq );
use Perl6::Slurp;
use MooseX::Types::Path::Class;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

use HTGT::Utils::TaqMan::Design::Sequence;
use HTGT::Utils::TaqMan::Design::Coordinates;

use Try::Tiny;

with qw( MooseX::Log::Log4perl HTGT::Utils::TaqMan::DesignsByGene );

const my @REQUIRED_FEATURES        => qw( U5 U3 D5 D3 );
const my @REQUIRED_FEATURES_NON_KO => qw( U5 D3 );

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
);

has target => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => \&_target_check,
);

sub _target_check {
    my ( $self, $target ) = @_;

    unless ( $target eq 'critical' || $target eq 'deleted' ) {
        die("Invalid target: $target, must be either 'critical' or 'deleted'");
    }
}

has sequence => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has role => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_role {
    my $self = shift;

    return $self->sequence ? 'HTGT::Utils::TaqMan::Design::Sequence'
                           : 'HTGT::Utils::TaqMan::Design::Coordinates';
}

has input_file => (
    is       => 'ro',
    isa      => 'IO::File',
    required => 1,
);

has input_data => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_input_data {
    my $self = shift;

    return [ split /\r\n|\r|\n/, slurp( $self->input_file ) ];
}

has include_duplicates => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0
);

has target_region_code => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_target_region_code {
    my $self = shift;

    if ( $self->target eq 'critical' ) {
        return [ 'c' ];
    }
    elsif ( $self->target eq 'deleted' ) {
        return [ 'd', 'u' ];
    }
}

has temp_output_files => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

has output_file => (
    is         => 'ro',
    isa        => 'Archive::Zip',
    lazy_build => 1,
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

sub BUILD {
    my $self = shift;

    $self->role->meta->apply( $self );

    for my $data ( @{ $self->input_data } ) {
        Log::Log4perl::NDC->push( "$data" );
        try {
            $self->get_taqman_design_info( $data );
        }
        catch {
            $self->add_error( $_ );
        };
        Log::Log4perl::NDC->pop;
    }
}

sub get_taqman_target_data {
    my ( $self, $design_id ) = @_;

    my $design = $self->get_design_by_id( $design_id );
    my $data = $self->fetch_data_for_design( $design );

    if ( !$self->include_duplicates ) {
        my @taqman_assays = $design->taqman_assays->search(
            { deleted_region => { IN => $self->target_region_code } } );

        if ( scalar(@taqman_assays) > 0 ) {
            my $current_taqman_assay = $taqman_assays[0];
            $self->log->warn( 'design already has taqman assay '
                              . $current_taqman_assay->assay_id
                              . ' for ' . $self->target . ' region ' );
            return {
                marker_symbol => $data->{marker_symbol},
                design_id     => $data->{design_id},
                has_primer    => 'design already has a taqman primer for selected target',
            };
        }
    }

    return $data;
}

sub fetch_data_for_design {
    my ( $self, $design ) = @_;
    my %data;

    $data{design_type}   = $design->design_type ? $design->design_type : 'KO';
    my $features         = $design->validated_display_features;
    $self->assert_required_features_present( $features, $data{design_type} );

    $data{design_id}     = $design->design_id;
    $data{marker_symbol} = $self->get_marker( $design );
    $data{chromosome}    = $self->get_chromosome( $features );
    $data{strand}        = $self->get_strand( $features );

    my @projects = $design->projects;
    my @sponsors
        = map { my $sponsor = $_->sponsor; $sponsor =~ s/:MGP// if $sponsor; $sponsor; } @projects;
    my $sponsors = join ',', uniq grep defined, @sponsors;
    $data{sponsor} = $sponsors;

    if ( $data{design_type} =~ /KO/  ) {
        if ( $self->target eq 'critical' ) {
            $self->fetch_wildtype_critical_data( \%data, $features );
        }
        elsif ( $self->target eq 'deleted' ) {
            $self->fetch_wildtype_deleted_data( \%data,  $features );
        }
    }
    else {
        $self->fetch_wildtype_data_non_KO_design( \%data, $features );
    }

    return \%data;
}

sub coordinates_plus {
    my ( $self, $fivep, $threep, $features ) = @_;

    my $c = {
        start => $features->{$fivep}->feature_end + 1,
        end   => $features->{$threep}->feature_start - 1
    };

    if ( $c->{start} > $c->{end} ) {
        $c->{start} = $c->{start} - 1;
        $c->{end}   = '-';
    }

    return $c;
}

sub coordinates_minus {
    my ( $self, $fivep, $threep, $features ) = @_;

    my $c = {
        start => $features->{$threep}->feature_end + 1,
        end   => $features->{$fivep}->feature_start - 1
    };

    if ( $c->{start} > $c->{end} ) {
        $c->{start} = $c->{start} - 1;
        $c->{end}   = '-';
    }

    return $c;
}

sub assert_required_features_present {
    my ( $self, $features, $design_type ) = @_;

    if ( $design_type =~ /KO/ ) {
        for my $name ( @REQUIRED_FEATURES ) {
            die "missing required feature $name\n"
                unless $features->{$name};
        }
    }
    else {
        for my $name ( @REQUIRED_FEATURES_NON_KO ) {
            die "missing required feature $name\n"
                unless $features->{$name};
        }
    }
    return 1;
}

sub get_marker {
    my ( $self, $design ) = @_;
    my $marker_symbol;

    try {
        $marker_symbol = $design->projects_rs->first->mgi_gene->marker_symbol;
    }
    catch {
        $self->log->error('Unable to find marker symbol for design: ' . $_ );
        $marker_symbol = '-';
    };

    return $marker_symbol;
}

sub get_strand {
    my ( $self, $features ) = @_;

    my @feature_strands = uniq grep defined, map $_->feature_strand, values %{ $features };

    die "display features have missing or inconsistent strand"
        unless @feature_strands == 1;

    pop @feature_strands;
}

sub get_chromosome {
    my ( $self, $features ) = @_;

    my @feature_chromosomes = uniq map $_->name, grep defined, map $_->chromosome, values %{ $features };

    die "display features have missing or inconsistent chromosome"
        unless @feature_chromosomes == 1;

    pop @feature_chromosomes;
}

sub get_designs {
    my ( $self, $data ) = @_;
    my @designs;

    if ( $data =~ /^\d+$/ ) {
        push @designs, $data;
    }
    else {
        push @designs, @{ $self->get_designs_by_gene( $data ) };
    }

    return \@designs;
}

sub get_design_by_id {
    my ( $self, $design_id ) = @_;

    my $design = $self->schema->resultset( 'Design' )->find( { design_id => $design_id } )
        or die "failed to retrieve design $design_id\n";

    return $design;
}

sub create_zip_file {
    my $self = shift;
    my $zip = Archive::Zip->new();

    foreach my $file_type ( keys %{ $self->temp_output_files } ) {
        my $output_file = $self->temp_output_files->{$file_type};
        #need to move back to start of file
        $output_file->seek(0,0);
        $zip->addFile( $output_file->filename, 'taqman_design_info.' . $file_type );
    }

    return $zip;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
