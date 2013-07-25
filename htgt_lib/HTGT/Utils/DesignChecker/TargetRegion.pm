package HTGT::Utils::DesignChecker::TargetRegion;

=head1 NAME

HTGT::Utils::DesignChecker::TargetRegion

=head1 DESCRIPTION

Collection of design checks relating to the region targeted by the design.

=cut

use Moose;
use namespace::autoclean;

use List::MoreUtils qw( uniq any none );
use Try::Tiny;
use Const::Fast;

use HTGT::Utils::DesignPhase qw( get_phase_from_design_and_transcript );

with 'HTGT::Utils::DesignCheckRole';

const my @TARGET_REGION_CHECKS => qw(
target_gene_matches_project_gene
target_start_codon_for_transcript
all_coding_transcripts_targeted
phase_shift_induced_in_transcripts
transcript_phase_match
);

sub _build_check_type {
    return 'target_region';
}

has target_region_start => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_target_region_start {
    return shift->target_slice->start;
}

has target_region_end => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_target_region_end {
    return shift->target_slice->end;
}

has strand => (
    is       => 'ro',
    isa      => 'Maybe[Int]',
    required => 1,
);

=head2 target_region_genes

Genes that will have coding portions of a transcript targeted.

=cut
has target_region_genes => (
    is         => 'ro',
    isa        => 'HashRef[Bio::EnsEMBL::Gene]',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        no_target_region_genes     => 'is_empty',
        target_region_genes_list   => 'values',
        target_region_gene_names   => 'keys',
        get_target_gene            => 'get', 
        num_target_region_genes    => 'count',
    }
);

sub _build_target_region_genes {
    my $self = shift;

    my %target_genes;
    for my $gene ( @{ $self->target_slice->get_all_Genes } ) {
        next if $gene->biotype ne 'protein_coding';
        $target_genes{$gene->stable_id} = $gene;
    }

    return \%target_genes;
}

=head2 target_region_genes_mgi_ids

For the target genes list the MGI accession ids to them, using mgi_gene view.

=cut
has target_region_genes_mgi_ids =>  (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        no_target_gene_mgi_ids        => 'is_empty',
        get_target_gene_mgi_ids       => 'get',
        target_gene_has_mgi_ids       => 'exists',
        num_target_genes_with_mgi_ids => 'count',
    }
);

sub _build_target_region_genes_mgi_ids {
    my $self = shift;

    my $schema = $self->design->result_source->schema;
    my %target_gene_mgi_ids;

    for my $target_gene ( $self->target_region_gene_names ) {
        # may be multiple mgi_gene rows with given mgi_gene_id so I am not just calling
        # mgi_gene on $project here as it is a belongs_to relationship so only returns one
        # mgi_gene row
        my @mgi_accession_ids = $schema->resultset('MGIGene')->search(
            {
                ensembl_gene_id => $target_gene
            },
            { 
                columns => [ 'mgi_accession_id' ],
                distinct => 1,
            }
        )->get_column('mgi_accession_id')->all;

        @mgi_accession_ids = uniq grep { defined } @mgi_accession_ids;
        if ( @mgi_accession_ids ) {
            $target_gene_mgi_ids{$target_gene} = [@mgi_accession_ids];
            $self->add_note( "Target gene $target_gene linked to mgi accession ids: "
                    . join( ' ', @mgi_accession_ids ) );
        }
    }

    return \%target_gene_mgi_ids;
}

=head2 target_gene

The verified target gene for given design.

=cut
has target_gene => (
    is     => 'ro',
    isa    => 'Bio::EnsEMBL::Gene',
    writer => 'set_target_gene',
);

has target_mgi_accession => (
    is     => 'ro',
    isa    => 'Str',
    writer => 'set_target_mgi_id',
    predicate => 'has_target_mgi_id',
);

=head2 coding_transcripts

Coding transcripts for target gene.

=cut
has coding_transcripts => (
    is         => 'ro',
    isa        => 'ArrayRef[Bio::EnsEMBL::Transcript]',
    lazy_build => 1,
    traits     => ['Array'],
    handles    => {
        get_coding_transcripts => 'elements',
    }
);

sub _build_coding_transcripts {
    my $self = shift;

    die 'target_gene attribute must be set' unless $self->target_gene;

    return $self->_coding_transcripts( $self->target_gene );
}

=head2 coding_transcript_targeted_bases

Number of bases targeted by design for each transcript of target gene.

=cut
has coding_transcript_targeted_bases => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        transcript_has_targeted_coding_bases => 'exists',
        coding_bases_for_transcript          => 'get',
    }
);

sub _build_coding_transcript_targeted_bases {
    my $self = shift;

    my %base_count;
    for my $tran ( $self->get_coding_transcripts ) {
        my $coding_bases = $self->_targeted_coding_bases_in_transcript( $tran );
        $base_count{ $tran->stable_id } = $coding_bases if $coding_bases;
    }

    return \%base_count;
}

=head2 _build_checks

Populate the checks array of the parent class

=cut
sub _build_checks {
    my $self = shift;

    return [
        'target_gene_matches_project_gene',
        'target_start_codon_for_transcript',
        'all_coding_transcripts_targeted',
        'phase_shift_induced_in_transcripts',
        'transcript_phase_match',
    ];
}

=head2 target_gene_matches_project_gene

Are the genes targeted by the design the same as the ones we report as being targeted.
Compares genes on target slice to the genes linked to the design projects.

=cut
sub target_gene_matches_project_gene {
    my ( $self ) = @_;
    
    if ( $self->no_target_region_genes ) {
        $self->set_status('no_genes_in_target_region');
        return;
    }

    if ( $self->no_target_gene_mgi_ids ) {
        $self->set_status( 'unable_to_validate'
            , ['Unable to verify design, no mgi accession ids linked to target genes ensembl ids' ] );
        return;
    }

    my $project_mgi_accession_id = $self->get_projects_mgi_accession_id();
    return unless $project_mgi_accession_id;

    my $matched_gene = $self->get_matched_gene( $project_mgi_accession_id );

    if ( $matched_gene ) {
        if ( $self->num_target_genes_with_mgi_ids == 1 ) {
            $self->set_target_gene( $self->get_target_gene( $matched_gene ) );
            $self->set_target_mgi_id( $project_mgi_accession_id );
            $self->add_note( "Target gene and project gene match : $matched_gene" );
            return 1;
        }
        # multiple target genes that link to mgi accession ids, we hit one of them
        else {
            $self->set_status('project_gene_matches_one_of_multiple_target_genes');
            $self->add_note( "Project gene: $matched_gene" );
            return 0;
        }
    }
    # no match and only one target gene
    elsif ( $self->num_target_region_genes == 1 ) {
        $self->set_status('target_gene_does_not_match_project_gene');
    }
    #no match and multiple target genes
    else {
        $self->multiple_target_region_genes;
    }

    return 0;
}

=head2 get_matched_gene

Find the project gene mgi accession id that matches against a list of target genes mgi accesion ids.
If we find one match return that, no matches return nothing.
If there are multiple matches ( multiple target gene matches found ) throw a error.

=cut
sub get_matched_gene {
    my ( $self, $project_gene ) = @_;

    my @matched_genes;
    for my $target_gene ( $self->target_region_gene_names ) {
        next unless $self->target_gene_has_mgi_ids( $target_gene );

        push @matched_genes, $target_gene
            if any{ $project_gene eq $_ } @{ $self->get_target_gene_mgi_ids( $target_gene ) };
    }

    if ( scalar( @matched_genes ) == 1 ) {
        return shift @matched_genes; 
    }
    elsif ( scalar( @matched_genes ) > 1 ) {
        $self->add_note( "Project gene $project_gene matches multiple target genes: "
                . join( '', @matched_genes ) );
    }

    return;
}

=head2 multiple_target_region_genes

Add extra information when multiple target region genes found.

=cut
sub multiple_target_region_genes {
    my ( $self ) = @_;

    $self->set_status( 'multiple_non_matching_genes_in_target_region' );
    $self->add_note( 'Multiple genes found in target region, none of which match the project gene: '
        . join( ' ', $self->target_region_gene_names  ) );

    my @genes_on_strand = map{ $_->stable_id } grep{ $_->strand == 1 } $self->target_region_genes_list;
    
    if ( scalar( @genes_on_strand ) == 1 ) {
        $self->add_note( 'One gene on design strand ' . $self->strand . ':' . $genes_on_strand[0] ); 
    }
    elsif ( scalar( @genes_on_strand ) > 1 ) {
        $self->add_note( 'Multiple possible target genes on design strand '
                         . $self->strand . ':' . join(' ', @genes_on_strand) );
    }
    else {
        $self->add_note( 'No genes on design strand ' . $self->strand );
    }

    return;
}

=head2 get_projects_mgi_accession_id

For a design get all the MGI accession ids linked to its projects.

=cut
sub get_projects_mgi_accession_id { 
    my $self = shift;

    my @projects = $self->design->projects->all;
    unless ( @projects ) {
        $self->set_status( 'unable_to_validate'
            , ['Unable to verify design, no projects found for design' ] );
        return;
    }

    my @project_mgi_accession_ids;
    my $schema = $self->design->result_source->schema;
    for my $project ( @projects ) {
        # may be multiple mgi_gene rows with given mgi_gene_id so I am not just calling
        # mgi_gene on $project here as it is a belongs_to relationship so only returns one
        # mgi_gene row
        my @mgi_accession_ids = $schema->resultset('MGIGene')->search(
            {
                mgi_gene_id => $project->mgi_gene_id
            },
            { 
                columns => [ 'mgi_accession_id' ],
                distinct => 1,
            }
        )->get_column('mgi_accession_id')->all;

        push @project_mgi_accession_ids, grep { defined } @mgi_accession_ids if @mgi_accession_ids;
    }
    @project_mgi_accession_ids = uniq @project_mgi_accession_ids;

    if ( !@project_mgi_accession_ids ) {
        $self->set_status( 'unable_to_validate'
            , ['Unable to verify design, no mgi accession ids linked to projects for design' ] );
        return;
    }
    # a design should never be linked with multiple mgi accession ids
    elsif ( scalar( @project_mgi_accession_ids ) > 1 ) {
        $self->set_status(
            'design_projects_linked_to_multiple_mgi_genes',
            [   'Design has projects linked to multiple mgi accession ids: '
                    . join( ' ', @project_mgi_accession_ids )
            ]
        );
        return;
    }

    my $project_mgi_accession_id = shift @project_mgi_accession_ids;
    $self->add_note( "Project mgi accession id for design: $project_mgi_accession_id" );

    return $project_mgi_accession_id;
}

=head2 target_start_codon_for_transcript

Add note if the start codon on the targeted transcripts is hit by the design.

=cut
sub target_start_codon_for_transcript {
    my $self = shift;

    for my $tran ( $self->get_coding_transcripts ) {
        # transform to chromosome coordinates for comparison
        $tran = $tran->transform( 'chromosome' );

        $self->add_note( 'Transcript ' . $tran->stable_id . ' has start codon within target region' )
            if $self->target_start_codon( $tran );
    }

    return 1;
}

=head2 all_coding_transcripts_targeted

Are all the coding transcripts for the target gene hit by this design.

=cut
sub all_coding_transcripts_targeted {
    my $self = shift;

    my @non_targeted_transcripts
        = grep { !$self->transcript_has_targeted_coding_bases( $_->stable_id ) }
            $self->get_coding_transcripts;

    my @non_targeted_valid_transcripts
        = grep { $self->valid_coding_transcript($_) } @non_targeted_transcripts;

    return 1 unless @non_targeted_valid_transcripts;

    #design may already have comment about alternative variant not targeted
    my $variant_not_targeted = $self->design->design_user_comments(
        {
            'category.category_name' => 'Alternative variant not targeted'
        },
        {
            join => 'category'
        }
    )->count;

    return 1 if $variant_not_targeted;
    
    $self->set_status(
        'non_targeted_coding_transcripts',
        [   'Valid coding transcripts not targeted: '
                . join( ' ', map { $_->stable_id } @non_targeted_valid_transcripts )
        ]
    );
    return;
}

=head2 phase_shift_induced_in_transcripts

Check if a phase shift is induced in all the coding transcripts for the target gene.

=cut
sub phase_shift_induced_in_transcripts {
    my $self = shift;

    return 1 if $self->design->subtype && $self->design->subtype eq 'domain';

    my @non_phase_shifted_transcripts;
    for my $tran ( $self->get_coding_transcripts ) {
        my $bases = $self->coding_bases_for_transcript( $tran->stable_id );
        push @non_phase_shifted_transcripts, $tran if $bases and $bases % 3 == 0;
    }

    #filter out transcripts we are not interested in
    my @non_phase_shifted_valid_transcripts
        = grep { $self->valid_coding_transcript($_) }
            grep { !$self->target_start_or_end_codon($_) }
                grep { !$self->transcript_exons_same_phase($_) } 
                    grep { !$self->design_targets_majority_of_transcript($_) }
                        @non_phase_shifted_transcripts;

    return 1 unless @non_phase_shifted_valid_transcripts;
    
    $self->set_status(
        'no_phase_shift_for_transcript',
        [   'Coding transcripts do not have phase shifted by design: '
                . join( ' ', map { $_->stable_id } @non_phase_shifted_valid_transcripts )
        ]
    );
    return;
}

=head2 design_targets_majority_of_transcript

Does the design target more than 50% of the coding bases for this transcript.

=cut
sub design_targets_majority_of_transcript {
    my ( $self, $transcript ) = @_;

    my $total_length = ( $transcript->cdna_coding_end - $transcript->cdna_coding_start ) + 1;
    my $targeted_length = $self->coding_bases_for_transcript( $transcript->stable_id );

    return if !$total_length || !$targeted_length;

    my $targeted_ratio = $targeted_length / $total_length;
    return 1 if $targeted_ratio > 0.5;
    return 0;
}

=head2 transcript_exons_same_phase

Return true if the phase of all the exons in the transcript are the same.
In this case we can't induce a phase shift.

=cut
sub transcript_exons_same_phase {
    my ( $self, $transcript ) = @_;
    my $initial_phase;

    for my $e ( @{ $transcript->get_all_Exons } ){
        next unless $e->coding_region_start( $transcript );

        my $exon_phase;
        if ( $e->phase == -1 ) {
            if ( $e->end_phase == -1 ) {
                $self->log->error('Both end_phase and phase -1 for exon: ' . $e->stable_id );
                return 0;
            }
            $exon_phase = $e->end_phase; 
        }
        elsif ( $e->end_phase == -1 ) {
            $exon_phase = $e->phase;
        }
        elsif ( $e->phase == $e->end_phase ) {
            $exon_phase = $e->phase;
        }
        else {
            return 0;
        }

        unless ( defined $initial_phase ){
            $initial_phase = $exon_phase;
            next;
        }

        return 0 if $initial_phase != $exon_phase;
    }

    return 1;
}

=head2 transcript_phase_match

Are the transcript design phases the same for all the transcripts.
Just make a note if its not, does not effect status

=cut
sub transcript_phase_match {
    my $self = shift;

    my @valid_coding_transcripts
        = grep { $self->valid_coding_transcript( $_ ) } $self->get_coding_transcripts;

    my %transcript_phases;
    for my $tran ( @valid_coding_transcripts ) {
        my $phase = try { get_phase_from_design_and_transcript( $self->design, $tran->stable_id ); };
        next unless defined $phase;
        $transcript_phases{$tran->stable_id} = $phase;
    }
    my @uniq_phases = uniq values %transcript_phases;

    unless ( scalar(@uniq_phases) == 1 ) {
        $self->add_note( "Transcript $_ has a design phase of " . $transcript_phases{$_} )
            for keys %transcript_phases;
    }

    return 1;
}

=head2 valid_coding_transcript

Return true if the transcript is a valid transcript by our measure:
Not nonsense mediated decay.
CDS region in complete ( has proper start and end ).

=cut
sub valid_coding_transcript {
    my ( $self, $transcript ) = @_;

    if ( $transcript->biotype eq 'nonsense_mediated_decay') {
        $self->log->debug('Transcript ' . $transcript->stable_id . ' is NMD');
        return 0;
    }

    # CDS incomplete check, both 5' and 3'
    if ( _get_transcript_attribute( $transcript, 'cds_end_NF' ) ) {
        $self->log->debug('Transcript ' . $transcript->stable_id . ' has incomplete CDS end');
        return 0;
    }

    if ( _get_transcript_attribute( $transcript, 'cds_start_NF' ) ) {
        $self->log->debug('Transcript ' . $transcript->stable_id . ' has incomplete CDS start');
        return 0;
    }

    return 1;
}

=head2 target_start_or_end_codon

Does the design target the start or end codon for a given transcript.

=cut
sub target_start_or_end_codon {
    my ( $self, $tran ) = @_;

    $tran = $tran->transform( 'chromosome' );

    if ( $self->target_start_codon( $tran ) || $self->target_end_codon( $tran ) ) {
        return 1;
    }

    return;
}

sub target_start_codon {
    my ( $self, $tran ) = @_;

    if (   $tran->coding_region_start > $self->target_slice->start
        && $tran->coding_region_start < $self->target_slice->end )
    {
        $self->log->debug( 'Transcript ' . $tran->stable_id . ' has start codon within target region.' );
        return 1;
    }

    return;
}

sub target_end_codon {
    my ( $self, $tran ) = @_;

    if (   $tran->coding_region_end < $self->target_slice->end
        && $tran->coding_region_end > $self->target_slice->start )
    {
        $self->log->debug( 'Transcript ' . $tran->stable_id . ' has end codon within target region.' );
        return 1;
    }

    return;
}

=head2 _targeted_coding_bases_in_transcript

For a given transcript work out how many coding bases would be removed by the design

=cut
sub _targeted_coding_bases_in_transcript {
    my ( $self, $transcript ) = @_;
    # transform to chromosome coordinates for comparison
    $transcript = $transcript->transform( 'chromosome' );
    my $coding_bases = 0;

    if (   $transcript->coding_region_start > $self->target_region_end
        or $transcript->coding_region_end < $self->target_region_start )
    {
        return;
    }

    for my $e ( @{ $transcript->get_all_Exons } ){
        next unless $e->coding_region_start( $transcript );
        if ( $transcript->strand == 1 ) {
            last if $e->seq_region_start > $self->target_region_end;
            next if $e->seq_region_end < $self->target_region_start;
        }
        else {
            last if $e->seq_region_end < $self->target_region_start;
            next if $e->seq_region_start > $self->target_region_end;
        }
        if ( $e->coding_region_start( $transcript ) < $self->target_region_start ) {
            #art intron, target region splits this exon
            my $bases = $e->coding_region_end( $transcript ) - $self->target_region_start;
            $coding_bases += $bases if $bases > 0;
        }
        elsif ( $e->coding_region_end( $transcript ) > $self->target_region_end ) {
            #art intron, target region splits this exon
            my $bases += $self->target_region_end - $e->coding_region_start( $transcript ); 
            $coding_bases += $bases if $bases > 0;
        }
        else{
            $coding_bases += $e->coding_region_end( $transcript ) - $e->coding_region_start( $transcript ) + 1;
        }
    }

    return $coding_bases;
}

sub _get_transcript_attribute {
    my ( $transcript, $code ) = @_;

    my ( $attr ) = @{ $transcript->get_all_Attributes($code) };
    if ( $attr ) {
        return $attr->value();
    }
    return 0;
}

sub _coding_transcripts {
    my ( $self, $gene )  = @_;

    return [ grep { $_->translation } @{ $gene->get_all_Transcripts } ];
}

1;

__END__
