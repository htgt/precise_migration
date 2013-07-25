package HTGT::Utils::MutagenesisPrediction::Design;

use Moose;
use HTGT::Utils::MutagenesisPrediction;
use HTGT::Utils::DesignFinder::Gene;
use List::MoreUtils qw( uniq );
use Try::Tiny;
use namespace::autoclean;

has design => (
    is       => 'ro',
    isa      => 'HTGTDB::Design',
    required => 1
);

has ensembl_gene_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has design_type => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has features => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

has [ qw( target_region_start target_region_end ) ] => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1,
);

has target_gene => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignFinder::Gene',
    lazy_build => 1,
    handles    => [ qw( all_transcripts complete_transcripts template_transcript ) ]
);

has _predictions => (
    isa        => 'HashRef[HTGT::Utils::MutagenesisPrediction]',
    init_arg   => 0,
    traits     => [ 'Hash' ],
    handles    => {
        prediction_for     => 'get',
        set_prediction_for => 'set',
        has_prediction_for => 'exists',
    },
    init_arg   => undef,
    default    => sub { {} }
);

with qw( MooseX::Log::Log4perl );

around prediction_for => sub {
    my ( $orig, $self, $transcript_id ) = @_;

    unless ( $self->has_prediction_for( $transcript_id ) ) {
        $self->set_prediction_for( $transcript_id,
                                   HTGT::Utils::MutagenesisPrediction->new(
                                       target_gene         => $self->target_gene,
                                       transcript_id       => $transcript_id,
                                       target_region_start => $self->target_region_start,
                                       target_region_end   => $self->target_region_end
                                   )
                               );
    }

    $self->$orig( $transcript_id );
};

sub _build_ensembl_gene_id {
    my $self = shift;

    my @ensembl_gene_ids = uniq grep defined, map $_->mgi_gene->ensembl_gene_id, $self->design->projects;

    confess "missing or inconsistent EnsEMBL gene ids for " . $self->design->design_id
        unless uniq( @ensembl_gene_ids ) == 1;

    my $ensembl_gene_id = shift @ensembl_gene_ids;
    $self->log->debug( "Target gene: $ensembl_gene_id" );

    return $ensembl_gene_id;
}

sub _build_target_gene {
    my $self = shift;

    return HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $self->ensembl_gene_id );
}

sub _build_design_type {
    my $self = shift;

    $self->design->design_type || 'KO';
}

sub _build_features {
    shift->design->validated_display_features
}

sub _build_target_region_start {
    my $self = shift;

    if ( $self->design_type =~ /^Del_/ or $self->design_type =~ /^KO/ ) {
        if ( $self->target_gene->strand == 1 ) {
            $self->features->{U5}->feature_end + 1;
        }
        else {
            $self->features->{D3}->feature_end + 1;
        }
    }
    else {
        confess "Unsupported design_type " . $self->design_type;
    }
}

sub _build_target_region_end {
    my $self = shift;

    if ( $self->design_type =~ /^Del_/ or $self->design_type =~ /^KO/ ) {
        if ( $self->target_gene->strand == 1 ) {
            $self->features->{D3}->feature_start - 1;
        }
        else {
            $self->features->{U5}->feature_start - 1;
        }
    }
    else {
        confess "Unsupported design_type " . $self->design_type;
    }
}

sub summary {
    my $self = shift;

    my @summary;

    for my $t ( $self->all_transcripts ) {
        my $desc = 'No analysis available';
        try {
            my $p = $self->prediction_for( $t->stable_id );
            if ( $p->has_error ) {
                $desc = $p->error;
            }
            else {
                $desc = $p->floxed_transcript->description;
            }
        }
        catch {
            warn "Design ID: " . $self->design->design_id . "\n";
            $self->log->error( $_ );
        };
        push @summary, [ $t->stable_id, $t->biotype, $desc ];
    }

    return \@summary;
}

sub detail {
    my $self = shift;

    my @detail;

    for my $t ( map $_->stable_id, $self->all_transcripts ) {
        my $prediction = {
            ensembl_transcript_id         => $t,
            floxed_transcript_description => 'No analysis available',
            is_warning                    => 1,
        };
        try {
            $prediction = $self->prediction_for( $t )->to_hash;
        }
        catch {
            warn "Design ID: " . $self->design->design_id . "\n";
            $self->log->error( $_ );
        };
        push @detail, $prediction;
    }

    \@detail;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
