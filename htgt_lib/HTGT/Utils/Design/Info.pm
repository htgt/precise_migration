package HTGT::Utils::Design::Info;

use Moose;
use namespace::autoclean;

use List::MoreUtils qw( uniq all );
use HTGT::Utils::Design::FindConstrainedElements qw( find_constrained_elements );
use HTGT::Utils::Design::FindRepeats qw( find_repeats );

with 'HTGT::Role::EnsEMBL';

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

has species => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Mus musculus',
);

has design => (
    is       => 'ro',
    isa      => 'HTGTDB::Design',
    required => 1,
);

has type => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1
);

has features => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

has oligos => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

has chr_name => (
    is         => 'ro',
    isa        => 'Str',
    init_arg   => undef,
    lazy_build => 1
);

has [
    qw( chr_strand chr_start chr_end
        cassette_start cassette_end
        floxed_exon_start floxed_exon_end
        homology_arm_start homology_arm_end
        five_arm_start five_arm_end
        three_arm_start three_arm_end)
] => (
    is         => 'ro',
    isa        => 'Int',
    init_arg   => undef,
    lazy_build => 1,
);

has [
    qw( loxp_start loxp_end target_region_start target_region_end )
] => (
    is         => 'ro',
    isa        => 'Maybe[Int]',
    init_arg   => undef,
    lazy_build => 1,
);

has mgi_gene => (
    is         => 'ro',
    isa        => 'HTGTDB::MGIGene',
    init_arg   => undef,
    lazy_build => 1
);

has [ qw(build_gene target_gene) ] => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Gene',
    init_arg   => undef,
    lazy_build => 1
);

has target_transcript => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Transcript',
    init_arg   => undef,
    lazy_build => 1
);

has [ qw(slice target_region_slice) ] => (
    is         => 'ro',
    isa        => 'Bio::EnsEMBL::Slice',
    init_arg   => undef,
    lazy_build => 1,
);

has floxed_exons => (
    is         => 'ro',
    isa        => 'ArrayRef[Bio::EnsEMBL::Exon]',
    traits     => [ 'Array' ],
    init_arg   => undef,
    lazy_build => 1,
    handles    => {
        first_floxed_exon => [ 'get',  0 ],
        last_floxed_exon  => [ 'get', -1 ],
        num_floxed_exons  => 'count',
    },
);

has constrained_elements => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1
);

has repeat_regions => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1,
);

sub _build_type {
    shift->design->design_type || 'KO';
}

sub _build_features {
    shift->design->validated_display_features
}

sub _build_oligos {
    my $self = shift;

    my %oligos;
    while ( my ( $feature_name, $display_feature ) = each %{ $self->features } ) {
        my $feature_data_rs = $display_feature->feature->search_related_rs(
            'feature_data',
            { 'feature_data_type.description' => 'sequence' },
            { join => 'feature_data_type' }
        );
        unless ( my $count = $feature_data_rs->count == 1 ) {
            confess 'Design ' . $self->design->design_id . " has $count $feature_name oligos (expected 1)";
        }

        my $oligo_seq = Bio::Seq->new( -display_id => $feature_name,
                                       -seq        => $feature_data_rs->first->data_item
                                   );        
        
        $oligos{$feature_name} = $self->chr_strand == 1 ? $oligo_seq : $oligo_seq->revcom;        
    }

    return \%oligos;
}

sub _build_chr_name {
    my $self = shift;

    my @chr_names = uniq map $_->chromosome->name, values %{ $self->features };
    confess 'Design ' . $self->design->design_id . ' features have inconsistent chromosome id'
        unless @chr_names == 1;

    return shift @chr_names;
}

sub _build_chr_strand {
    my $self = shift;

    my @strands = uniq map $_->feature_strand, values %{ $self->features };
    confess 'Design ' . $self->design->design_id . ' features have inconsistent strand'
        unless @strands == 1;

    return shift @strands;
}

sub _build_chr_start {
    my $self = shift;

    if ( $self->chr_strand == 1 ) {
        $self->features->{G5}->feature_start;
    }
    else {
        $self->features->{G3}->feature_start;        
    }
}

sub _build_chr_end {
    my $self = shift;

    if ( $self->chr_strand == 1 ) {
        $self->features->{G3}->feature_end;
    }
    else {
        $self->features->{G5}->feature_end;
    }
}

sub _build_cassette_start {
    my $self = shift;

    if ( $self->type =~ /^Del/ || $self->type =~ /^Ins/) {
        if ( $self->chr_strand == 1 ) {
            $self->features->{U5}->feature_end + 1;            
        }
        else {
            $self->features->{D3}->feature_end + 1;            
        }
    }
    else {
        if ( $self->chr_strand == 1 ) {
            $self->features->{U5}->feature_end + 1;
        }
        else {
            $self->features->{U3}->feature_end + 1;        
        }
    }
}

sub _build_cassette_end {
    my $self = shift;

    if ( $self->type =~ /^Del/ || $self->type =~ /^Ins/) {
        if ( $self->chr_strand == 1 ) {
            $self->features->{D3}->feature_start - 1;            
        }
        else {
            $self->features->{U5}->feature_start - 1;
        }
    }
    else {
        if ( $self->chr_strand == 1 ) {
            $self->features->{U3}->feature_start - 1;        
        }
        else {
            $self->features->{U5}->feature_start - 1;        
        }
    }    
}

sub _build_loxp_start {
    my $self = shift;
    
    return if $self->type =~ /^Del/ || $self->type =~ /^Ins/;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{D5}->feature_end + 1;
    }
    else {
        $self->features->{D3}->feature_end + 1;
    }
}

sub _build_loxp_end {
    my $self = shift;
    
    return if $self->type =~ /^Del/ || $self->type =~ /^Ins/;

    if ( $self->chr_strand == 1 ) {
        $self->features->{D3}->feature_start - 1;
    }
    else {
        $self->features->{D5}->feature_start - 1;
    }    
}

sub _build_homology_arm_start {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{G5}->feature_start;
    }
    else {
        $self->features->{G3}->feature_start;
    }   
}

sub _build_homology_arm_end {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{G3}->feature_end;
    }
    else {
        $self->features->{G5}->feature_end;
    }       
}

sub _build_five_arm_start {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{G5}->feature_start;
    }
    else {
        $self->features->{U5}->feature_start;
    }   
}

sub _build_five_arm_end {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{U5}->feature_end;
    }
    else {
        $self->features->{G5}->feature_end;
    }   
}

sub _build_three_arm_start {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{D3}->feature_start;
    }
    else {
        $self->features->{G3}->feature_start;
    }   
}

sub _build_three_arm_end {
    my $self = shift;
    
    if ( $self->chr_strand == 1 ) {
        $self->features->{G3}->feature_end;
    }
    else {
        $self->features->{D3}->feature_end;
    }   
}
        
sub _build_target_region_start {
    my $self = shift;
    
    if ($self->type =~ /^Del/ || $self->type =~ /^Ins/){
      if ( $self->chr_strand == 1 ) {
          return $self->features->{U5}->feature_start;
      }
      else {
          return $self->features->{D3}->feature_start;
      }   
    }
      
    if ( $self->chr_strand == 1 ) {
        return $self->features->{U3}->feature_start;
    }
    else {
        return $self->features->{D5}->feature_start;
    }   
}

sub _build_target_region_end {
    my $self = shift;
    
    if ($self->type =~ /^Del/ || $self->type =~ /^Ins/){
      if ( $self->chr_strand == 1 ) {
          return $self->features->{D3}->feature_start;
      }
      else {
          return $self->features->{U5}->feature_start;
      }   
    }
    
    if ( $self->chr_strand == 1 ) {
        return $self->features->{D5}->feature_end;
    }
    else {
        return $self->features->{U3}->feature_end;
    }   
}

sub _build_mgi_gene {
    my $self = shift;

    if ( my $project = $self->design->projects_rs->first ){
        return $project->mgi_gene;
    }
    
    my $gene_name = $self->design->start_exon->transcript->gene_build_gene->primary_name;
    my $mgi_gene_rs = $self->design->result_source->schema->resultset('MGIGene')->search(
        {
            -or => [
                ensembl_gene_id => $gene_name,
                vega_gene_id     => $gene_name
            ]
        }
    );
    
    return $mgi_gene_rs->first;
}

sub _build_slice {
    my $self = shift;

    $self->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->chr_start,
        $self->chr_end,
        $self->chr_strand
    );
}

sub _build_target_region_slice {
    my $self = shift;

    $self->slice_adaptor->fetch_by_region(
        'chromosome',
        $self->chr_name,
        $self->target_region_start,
        $self->target_region_end,
        $self->chr_strand
    );    
}

sub _build_build_gene {
    my $self = shift;

    my $build_gene_id = $self->design->start_exon->transcript->gene_build_gene->primary_name;

    my $build_gene;

    if ( $build_gene_id =~ m/^ENS/ ) {
        $build_gene = $self->gene_adaptor->fetch_by_stable_id( $build_gene_id )
            or confess "failed to fetch gene $build_gene_id";
    }
    else {
        my $genes = $self->gene_adaptor->fetch_all_by_external_name( $build_gene_id );
        confess "search for $build_gene_id returned " . @$genes . " genes"
            unless @{ $genes } == 1;
        $build_gene = $genes->[0];
    }
    
    return $build_gene;    
}

sub _build_target_gene {
    my $self = shift;

    # print STDERR "RUNNING DEV CODE\n";
    my $exons = $self->target_region_slice->get_all_Exons;
    confess "No exons found in target region"
        unless @{$exons};

    my %genes_in_target_region;
    #print STDERR "FOUND ".@{$exons}." EXONS\n";
    for my $e ( @{$exons} ) {
        my $gene = $self->gene_adaptor->fetch_by_exon_stable_id( $e->stable_id );
        $genes_in_target_region{ $gene->stable_id } ||= $gene;        
    }
    #print STDERR "FOUND GENES\n";

    my $target_gene;
    
    if ( keys %genes_in_target_region == 1 ) {
        $target_gene = (values %genes_in_target_region)[0];
    }
    else {
        my $build_gene_id = $self->build_gene->stable_id;    
        if ( $genes_in_target_region{ $build_gene_id } ) {
            $target_gene = $genes_in_target_region{ $build_gene_id } ;
        }
        else {
            confess 'target region ' . $self->target_region_slice->name . ' does not contain ' . $build_gene_id;            
        }
    }

    return $target_gene->transfer( $self->slice );
}

sub _build_target_transcript {
    my $self = shift;

    my @best_transcripts;
    my $longest_transcript_length = 0;
    my $longest_translation_length = 0;

    for my $transcript ( @{ $self->target_gene->get_all_Transcripts } ) {
        my $translation = $transcript->translation
            or next;
        if ( $translation->length > $longest_translation_length ) {
            @best_transcripts = ( $transcript );
            $longest_translation_length = $translation->length;
            $longest_transcript_length = $transcript->length;
        }
        elsif ( $translation->length == $longest_translation_length ) {
            if ( $transcript->length > $longest_transcript_length ) {
                @best_transcripts = ( $transcript );
                $longest_transcript_length = $transcript->length;
            }
            elsif ( $transcript->length == $longest_transcript_length ) {
                push @best_transcripts, $transcript;
            }
        }
    }

    confess $self->target_gene->stable_id . ' has no coding transcripts'
        unless @best_transcripts;

    return shift @best_transcripts;
}

sub _build_floxed_exons {
    my $self = shift;

    my $start = $self->target_region_start;
    my $end   = $self->target_region_end;
    
    my @exons = grep { $_->start <= $end and $_->end >= $start }
        map $_->transform( 'chromosome' ),
            @{ $self->target_transcript->get_all_Exons };

    return \@exons;
}

sub _build_floxed_exon_start {
    my $self = shift;

    if ( $self->chr_strand == 1 ) {
        $self->first_floxed_exon->start;        
    }
    else {
        $self->last_floxed_exon->start;
    }
}

sub _build_floxed_exon_end {
    my $self = shift;

    if ( $self->chr_strand == 1 ) {
        $self->last_floxed_exon->end;
    }
    else {
        $self->first_floxed_exon->end;
    }
}

sub _build_constrained_elements {
    my $self = shift;

    my ( $t5_start, $t5_end, $t3_start, $t3_end );
    if ( $self->chr_strand == 1 ) {
        $t5_start = $self->target_region_start;
        $t5_end   = $self->floxed_exon_start - 50;
        $t3_start = $self->floxed_exon_end + 30;
        $t3_end   = $self->target_region_end;
    }
    else {
        $t5_start = $self->floxed_exon_end + 50;
        $t5_end   = $self->target_region_end;
        $t3_start = $self->target_region_start;
        $t3_end   = $self->floxed_exon_start - 30;        
    }

    my %constrained_elements = (
        "cassette"  => $self->__constrained_elements( $self->cassette_start, $self->cassette_end ),
        "loxp"      => $self->__constrained_elements( $self->loxp_start, $self->loxp_end ),
        "5' target" => $self->__constrained_elements( $t5_start, $t5_end ),
        "3' target" => $self->__constrained_elements( $t3_start, $t3_end )
    );

    return \%constrained_elements;
}

sub __constrained_elements {
    my ( $self, $start, $end ) = @_;

    my $ce = find_constrained_elements( $self->chr_name, $start, $end, $self->chr_strand );

    [ map { start => $_->start, end => $_->end, score => $_->score }, @{$ce} ];
}

sub _build_repeat_regions {
    my $self = shift;

    my %repeat_regions;

    for my $feature_name ( qw( G5 U5 U3 D5 D3 G3 ) ) {
        my $feature = $self->features->{$feature_name}
            or next;
        $repeat_regions{$feature_name} = $self->__repeat_regions( $feature->feature_start, $feature->feature_end );
    }

    if ( $self->chr_strand == 1 ) {
        $repeat_regions{ "G5 5' flank" } = $self->__repeat_regions( $self->features->{G5}->feature_start - $self->G5_repeat_region_flank,
                                                                    $self->features->{G5}->feature_start );
        $repeat_regions{ "G3 3' flank" } = $self->__repeat_regions( $self->features->{G3}->feature_end,
                                                                    $self->features->{G3}->feature_end + $self->G3_repeat_region_flank );
    }
    else {
        $repeat_regions{ "G5 5' flank" } = $self->__repeat_regions( $self->features->{G5}->feature_end,
                                                                    $self->features->{G5}->feature_end + $self->G5_repeat_region_flank );
        $repeat_regions{ "G3 3' flank" } = $self->__repeat_regions( $self->features->{G3}->feature_start - $self->G3_repeat_region_flank,
                                                                    $self->features->{G3}->feature_start );
    }   

    return \%repeat_regions;
}

sub __repeat_regions {
    my ( $self, $start, $end ) = @_;

    my $repeats = find_repeats( $self->chr_name, $start, $end, $self->chr_strand );

    return unless @{ $repeats };
    
    [ map {
        start => $_->start,
        end   => $_->end,
        score => $_->score,
        class => $_->repeat_consensus->repeat_class,
        type  => $_->repeat_consensus->repeat_type        
    }, @{ $repeats } ];
}

sub as_hash {
    my $self = shift;

    my %h = (
        design_id            => $self->design->design_id,
        build_gene_id        => $self->build_gene->stable_id,
        target_gene_id       => $self->target_gene->stable_id,
        target_transcript    => $self->target_transcript->stable_id,
        floxed_exons         => [ map { id => $_->stable_id, start => $_->start, end => $_->end }, @{ $self->floxed_exons } ],
        chromosome           => $self->chr_name,
        strand               => $self->chr_strand,
        features             => {
            map
                {
                    $_ => { start => $self->features->{$_}->feature_start,
                            end   => $self->features->{$_}->feature_end }
                } keys %{ $self->features }
            },
        oligos               => { map { $_ => $self->oligos->{$_}->seq } keys %{ $self->oligos } },
        cassette_start       => $self->cassette_start,
        cassette_end         => $self->cassette_end,
        loxp_start           => $self->loxp_start,
        loxp_end             => $self->loxp_end,
        target_region_start  => $self->target_region_start,
        target_region_end    => $self->target_region_end,
        constrained_elements => $self->constrained_elements,
        repeats              => $self->repeat_regions,
    );

    return \%h;
}

1;

__END__
