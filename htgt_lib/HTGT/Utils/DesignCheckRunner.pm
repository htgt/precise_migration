package HTGT::Utils::DesignCheckRunner;

=head1 NAME

HTGT::Utils::DesignCheckRunner

=head1 DESCRIPTION

This module runs all the design checks against a given design.

=cut

use Moose;
use namespace::autoclean;

use HTGT::Utils::DesignChecker::Oligo;
use HTGT::Utils::DesignChecker::DesignQuality;
use HTGT::Utils::DesignChecker::TargetRegion;
use HTGT::Utils::DesignChecker::ArtificialIntron;
use Try::Tiny;
use Const::Fast;

with 'MooseX::Log::Log4perl';
with 'HTGT::Role::EnsEMBL';

has schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1
);

has assembly_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has build_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has design => (
    is       => 'ro',
    isa      => 'HTGTDB::Design',
    required => 1
);

has update_annotations => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has design_annotation => (
    is         => 'ro',
    isa        => 'Maybe[HTGTDB::DesignAnnotation]',
    lazy_build => 1,
);

sub _build_design_annotation {
    my $self = shift;

    return unless $self->update_annotations;

    return $self->schema->resultset('DesignAnnotation')->find_or_create(
        {
            design_id   => $self->design->design_id,
            assembly_id => $self->assembly_id,
            build_id    => $self->build_id,
        }
    );
}

has features => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_features {
    my $self = shift;

    my $features = try { $self->design->validated_display_features } catch { {} };

    return $features;
}

has strand => (
    is         => 'ro',
    isa        => 'Maybe[Int]',
    lazy_build => 1,
);

sub _build_strand {
    my $self = shift;

    my $strand = try{ $self->design->info->chr_strand }; 

    return $strand;
}

has chr_name => (
    is         => 'ro',
    isa        => 'Maybe[Str]',
    lazy_build => 1,
);

sub _build_chr_name {
    my $self = shift;

    my $chr_name = try{ $self->design->info->chr_name };

    return $chr_name;
}

has design_type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_design_type {
    shift->design->design_type || 'KO';
}

has target_slice => (
    is         => 'ro',
    isa        => 'Maybe[Bio::EnsEMBL::Slice]',
    lazy_build => 1,
);

sub _build_target_slice {
    my $self = shift;

    my ( $target_region_start, $target_region_end );

    return unless defined $self->strand; 

    try{
        if ( $self->design_type =~ /^Del/ || $self->design_type =~ /^Ins/ ) {
            if ( $self->strand == 1 ) {
                $target_region_start = $self->features->{U5}->feature_end;
                $target_region_end   = $self->features->{D3}->feature_start;
            }
            else {
                $target_region_start = $self->features->{D3}->feature_end;
                $target_region_end   = $self->features->{U5}->feature_start;
            }
        }
        # Knock Out Design
        else {
            if ( $self->strand == 1 ) {
                $target_region_start = $self->features->{U3}->feature_start;
                $target_region_end   = $self->features->{D5}->feature_end;
            }
            else {
                $target_region_start = $self->features->{D5}->feature_start;
                $target_region_end   = $self->features->{U3}->feature_end;
            }
        }
    };

    return try{
        $self->slice_adaptor->fetch_by_region(
            'chromosome',
            $self->chr_name,
            $target_region_start,
            $target_region_end,
            $self->strand,
        );
    };
}

has oligo_checker => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignChecker::Oligo',
    lazy_build => 1,
);

sub _build_oligo_checker {
    my $self = shift;

    return HTGT::Utils::DesignChecker::Oligo->new(
         design             => $self->design,
         design_type        => $self->design_type,
         assembly_id        => $self->assembly_id,
         design_annotation  => $self->design_annotation,
         update_annotations => $self->update_annotations,
    );
}

has design_quality_checker => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignChecker::DesignQuality',
    lazy_build => 1,
);

sub _build_design_quality_checker {
    my $self = shift;

    return HTGT::Utils::DesignChecker::DesignQuality->new(
         target_slice       => $self->target_slice,
         design_annotation  => $self->design_annotation,
    );
}

has target_region_checker => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignChecker::TargetRegion',
    lazy_build => 1,
);

sub _build_target_region_checker {
    my $self = shift;

    return HTGT::Utils::DesignChecker::TargetRegion->new(
         design             => $self->design,
         target_slice       => $self->target_slice,
         strand             => $self->strand,
         design_annotation  => $self->design_annotation,
    );
}

has artificial_intron_checker => (
    is         => 'ro',
    isa        => 'HTGT::Utils::DesignChecker::ArtificialIntron',
    lazy_build => 1,
);

sub _build_artificial_intron_checker {
    my $self = shift;

    return HTGT::Utils::DesignChecker::ArtificialIntron->new(
         design             => $self->design,
         features           => $self->features,
         strand             => $self->strand,
         target_slice       => $self->target_slice,
         design_annotation  => $self->design_annotation,
    );
}

has final_status => (
    is      => 'rw',
    isa     => 'Str',
    default => 'valid',
    writer  => 'set_final_status',
);

const my @DESIGN_CHECK_CLASSES => qw(
oligo_checker
design_quality_checker
target_region_checker
artificial_intron_checker
);

=head2 check_design

Runs all the design checks against a design in the order specified by @DESIGN_CHECK_CLASSES array. 
If all checks pass the overall status is set to valid.

=cut
sub check_design {
    my $self = shift;

    for my $check ( @DESIGN_CHECK_CLASSES ) {
        # update_design_annotation_status returns true if checks pass
        unless ( $self->$check->update_design_annotation_status ) {
            #set the final status to the last failed status, not just invalid
            $self->set_final_status( $self->$check->status );
            last;
        }
    }

    $self->log->info('Final Status: ' . uc( $self->final_status ) );
    $self->set_design_annotation if $self->update_annotations;

    return;
}

=head2 set_design_annotation

Update the design_annotation row linked to the design.

=cut
sub set_design_annotation {
    my $self = shift;
    my %update_data;

    $update_data{edited_by}       = 'design_checker';
    $update_data{edited_date}     = \'current_timestamp';
    $update_data{final_status_id} = $self->final_status;

    for my $check ( @DESIGN_CHECK_CLASSES ) {
        my $checker = $self->$check;

        if ( $checker->has_status ) {
            $update_data{ $checker->status_field }       = $checker->status;
            $update_data{ $checker->status_notes_field } = $checker->join_notes("\r\n");

            #set the validated target gene MGI accession ID for design
            $update_data{target_gene} = $self->target_region_checker->target_mgi_accession
                if $checker->check_type eq 'target_region' &&  $checker->has_target_mgi_id;
        }
        else {
            $update_data{ $checker->status_field }       = undef;
            $update_data{ $checker->status_notes_field } = undef;
        }
    }

    $self->design_annotation->update( \%update_data );
    $self->add_target_region_genes;
}

=head2 add_target_region_genes

If the design 'hits' 1 or more target genes add this information to the design annotation.
Make sure to skip this if the design already failed a previous check.
Also delete any target genes already present so duplicate rows not created.

=cut
sub add_target_region_genes {
    my $self = shift;

    $self->design_annotation->target_region_genes->delete;

    return
        if !$self->target_region_checker->has_status
            or $self->target_region_checker->no_target_region_genes;

    for my $ensembl_id ( $self->target_region_checker->target_region_gene_names ) {
        my $mgi_ids
            = join( ',', @{ $self->target_region_checker->get_target_gene_mgi_ids($ensembl_id) } );

        $self->design_annotation->create_related(
            target_region_genes => {
                ensembl_gene_id  => $ensembl_id,
                mgi_accession_id => $mgi_ids,
            }
        );
    }
}

1;

__END__
