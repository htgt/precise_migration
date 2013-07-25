### TargetedTrap::IVSA::SyntheticConstruct
#
# Copyright 2005 Genome Research Limited (GRL)
#
# No longer maintained by Jessica Severin (jessica@sanger.ac.uk)
# No longer Maintained by Lucy Stebbings (las@sanger.ac.uk)
#hacked about with no respect by dj3@sanger.ac.uk
# Author htgt

=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact Team87 on implemetation/design detail: htgt@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::SyntheticConstruct;

use strict;
use warnings;

require Bio::Seq::RichSeq;
require Bio::SeqIO;
require Data::Dumper;
require Bio::SeqUtils;

use DBD::Oracle qw(:ora_types);
use HTGT::Constants qw( %CASSETTES %BACKBONES );

#use Bio::EnsEMBL::Utils::Exception qw( throw warning );
#use Bio::SeqFeature::AnnotationAdaptor;
require Bio::Annotation::Comment;
require Bio::Annotation::Collection;

require HTGTDB;
require TargetedTrap::IVSA::Design;
require TargetedTrap::IVSA::ConstructClone;

require TargetedTrap::IVSA::EngineeredSeq;
our @ISA = qw( TargetedTrap::IVSA::EngineeredSeq );

our $GLOBAL_SYNTHVEC_DATADIR = $ENV{GLOBAL_SYNTHVEC_DATADIR}
    || ( $INC{q(TargetedTrap/IVSA/SyntheticConstruct.pm)}
    =~ /^(.*)\/perl(?:5|\/modules)\/+TargetedTrap\/IVSA\/SyntheticConstruct.pm/
    ? "$1/data"
    : undef );

#warn "GLOBAL_SYNTHVEC_DATADIR $GLOBAL_SYNTHVEC_DATADIR";

#################################################
# Class methods
#################################################

#################################################
# Instance methods
#################################################

sub init {
    my $self = shift;
    $self->SUPER::init;

    $self->subclass('synthetic_vector');
    $self->type('intermediate');

    $self->{'comments'}                  = undef;
    $self->{'design'}                    = undef;
    $self->{'primers'}                   = [];
    $self->{'primer_summary'}            = {};
    $self->{'calc_ok'}                   = 0;
    $self->{'sum_score'}                 = undef;
    $self->{'best_clone'}                = undef;
    $self->{'pass_status'}               = undef;
    $self->{'is_best_for_design_in_run'} = undef;
    $self->{'gateway_cassette_tag'}      = '';
    $self->{'gateway_backbone_tag'}      = undef;   # but defaults to L3L4_dta

    $self->{'sum_score'}        = undef;
    $self->{'best_clone'}       = undef;
    $self->{'cassette_formula'} = undef;
    $self->{'primer_summary'}   = {};
    $self->{'id_vector'}        = undef;

    return $self;
}

#################################################
sub comments {
    my $self = shift;
    $self->{'comments'} = shift if (@_);
    return $self->{'comments'};
}

sub synth_stage {

    #either 'intermediate' or 'gateway' or 'allele'
    my ( $self, $stage ) = @_;
    if ($stage) {
        $self->type($stage);
    }
    return $self->type;
}

# this is the TRAP id_vector for the vector we are trying to make
sub id_vector {
    my $self = shift;
    $self->{'id_vector'} = shift if (@_);
    return $self->{'id_vector'};
}

sub gateway_cassette_tag {
    my $self = shift;
    $self->{'gateway_cassette_tag'} = shift if (@_);
    return $self->{'gateway_cassette_tag'};
}

sub gateway_backbone_tag {
    my $self = shift;
    $self->{'gateway_backbone_tag'} = shift if (@_);
    return $self->{'gateway_backbone_tag'};
}

sub cassette_formula {
    my $self = shift;
    $self->{'cassette_formula'} = shift if (@_);
    return $self->{'cassette_formula'};
}

sub genbank_accession {
    my $self = shift;
    $self->{'genbank_accession'} = shift if (@_);
    return $self->{'genbank_accession'};
}

sub unique_tag {
    my $self = shift;
    if (@_) {
        $self->{unique_tag} = shift;
    }
    unless ( exists $self->{unique_tag} ) {
        my $tag = $self->SUPER::unique_tag;
        if ( $self->design ) {
            if ( $self->synth_stage eq 'intermediate' ) {
                $tag = sprintf( 'interm_%s_%s',
                    $self->design->design_id, $self->design->exon_name );
                my $cassette_tag = $self->gateway_cassette_tag;
                $cassette_tag =~ s/^[gs]t[012k]$/L1L2_$&/
                    ; # if automatically found cassette e.g. (gt0, st2, or gtk) - then convert to format we can lookup
                $tag .= "_" . $self->gateway_cassette_tag
                    if ( $cassette_tag and not $cassette_tag =~ /^L\dL\d_/ )
                    ;    #add cassette if non-gateway
                $tag .= "_" . $self->gateway_backbone_tag
                    if $self->gateway_backbone_tag;
            }
            elsif ( $self->synth_stage eq 'gateway' ) {
                $tag = join( '_',
                    'final',
                    grep {$_} $self->design->design_id,
                    $self->design->exon_name,
                    $self->gateway_cassette_tag,
                    $self->gateway_backbone_tag );
            }
            elsif ( $self->synth_stage eq 'allele' ) {
                $tag = sprintf( 'allele_%s_%s_%s',
                    $self->design->design_id, $self->design->exon_name,
                    $self->gateway_cassette_tag );
            }

            if ( $self->design->plate ) {
                $tag .= sprintf( '_%s_%s',
                    $self->design->plate, $self->design->well );
            }
        }
        $self->{unique_tag} = $tag;
    }
    return $self->{unique_tag};
}

#################################################

sub design {
    my ( $self, $design ) = @_;
    if ($design) {
        unless ( defined($design)
            && $design->isa('TargetedTrap::IVSA::Design') )
        {
            throw('design param must be a TargetedTrap::IVSA::Design');
        }
        $self->{'design'} = $design;
    }
    return $self->{'design'};
}

# just getters
sub design_inst_id {
    my $self = shift;
    return $self->{'design_inst_id'};
}

sub plate {
    my $self = shift;
    return $self->{'plate'};
}

sub well {
    my $self = shift;
    return $self->{'well'};
}

sub fetch_design {
    my $self      = shift;
    my $design_db = shift;

    if (   !defined( $self->{'design'} )
        and defined($design_db)
        and defined( $self->{'design_inst_id'} ) )
    {

        #load from database if possible
        my $design = TargetedTrap::IVSA::Design->fetch_by_id( $design_db,
            $self->{'design_inst_id'} );
        if ( defined($design) ) {
            $self->{'design'} = $design;
            $self->build_annotation;
        }
    }
    return $self->{'design'};
}

sub build_annotation {
    my $self = shift;

    return unless ( $self->design );

    #add annotation block
    my $collection = new Bio::Annotation::Collection;

    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "gene : %s\n", $self->design->gene_name )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' =>
                sprintf( "critical_exon : %s\n", $self->design->exon_name )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "design : %s\n", $self->design->design_tag )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "synvector : %s\n", $self->name )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf(
                "synvector_formula : %s\n", $self->cassette_formula
            )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "synvector_id : %s\n", $self->id )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "design_instance_id : %s\n",
                $self->design->design_inst_id )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf( "design_id : %s\n", $self->design->design_id )
        )
    );
    $collection->add_Annotation(
        'comment',
        Bio::Annotation::Comment->new(
            '-text' => sprintf(
                "design_plate_loc : %s_%s\n",
                $self->design->plate, $self->design->well
            )
        )
    );

    $self->sequence->annotation($collection);
}

#################################################
# new method to get the sequence of synthetic vector using Design.pm in HTGTDB, by wy1
sub calc_concat {
    my $self = shift;

    # get the design id from IVSA Design object
    my $design_id = $self->design->design_id;

    # create a HTGTDB Design object

    my $schema
        = HTGTDB->connect( sub { $self->design->database()->get_connection() }
        );

    my $design = $schema->resultset('HTGTDB::Design')->find($design_id);

    # get the sequence
    my $synthseq;

    my $cassette_tag = $self->gateway_cassette_tag;
    $cassette_tag =~ s/^[gs]t[012k]$/L1L2_$&/
        ; # if automatically found cassette e.g. (gt0, st2, or gtk) - then convert to format we can lookup
    $cassette_tag = undef
        if ( ( $self->synth_stage eq 'intermediate' )
        and $cassette_tag =~ /^L\dL\d_/ )
        ;    #drop cassette if gateway type and we're not at gateway stage yet
    my $backbone_tag = $self->gateway_backbone_tag;
    $backbone_tag = undef
        if ( ( $self->synth_stage eq 'intermediate' )
        and $backbone_tag =~ /^L\dL\d_/ )
        ;    #drop backbone if gateway type and we're not at gateway stage yet
    if (   $self->synth_stage eq 'gateway'
        || $self->synth_stage eq 'intermediate' )
    {
        $synthseq = $design->vector_seq( $cassette_tag, $backbone_tag );
    }
    elsif ( $self->synth_stage eq 'allele' ) {
        $synthseq = $design->allele_seq($cassette_tag);
    }
    else { die "Unknown synth stage\n"; }

    $self->cassette_formula( $synthseq->display_id );
    $synthseq->display_id( $self->unique_tag );
    $self->sequence($synthseq);
    return $synthseq;
}

##################################################

sub calc_concat_old {
    my $self = shift;

    my $design = $self->design;
    unless ( $design->five_arm && $design->three_arm ) {
        if ( $self->synth_stage eq 'allele' ) {
            $design->load_genomic_arms('allele');
        }
        else { $design->load_genomic_arms; }
    }

#my $kan = $self->create_kanamycin_sequence; #TODO: What the hell is this doing here? - dj3

    warn sprintf( "%s\n",               $design->description );
    warn sprintf( "  5arm: %d bases\n", $design->five_arm->sequence->length );
    warn sprintf( "  target_arm: %d bases\n",
        $design->target_region->sequence->length )
        unless ( $design->is_deletion or $design->is_insertion );
    warn
        sprintf( "  3arm: %d bases\n", $design->three_arm->sequence->length );

    #deal with problem of arms not being in correct orientation
    my $five_arm = $design->five_arm->sequence;
    my $target_arm;
    my $three_arm = $design->three_arm->sequence;

    ######### 5' arm #############
    my $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $five_arm->length,
        -strand       => 1,
        -primary      => 'misc_feature',          # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => '5_arm',
        -tag          => { note => '5 arm' }
    );
    $five_arm->add_SeqFeature($feat);

    #Bio::SeqFeature::AnnotationAdaptor->new(-feature=>$feat);

    ######### target arm #############
    if ( $design->is_deletion ) { #leave target region undefined if a deletion
    }
    elsif ( $design->is_insertion ) {
        $target_arm = new Bio::Seq::RichSeq( -seq => 'N' x 1000 );
        $feat = new Bio::SeqFeature::Generic(
            -start        => 1,
            -end          => $target_arm->length,
            -strand       => 1,
            -primary      => 'misc_feature',       # -primary_tag is a synonym
            -source_tag   => 'synthetic_construct',
            -display_name => 'insert_region',
            -tag => { note => 'insertion region' }
        );
        $target_arm->add_SeqFeature($feat);
    }
    else {
        $target_arm = $design->target_region->sequence;
        $feat       = new Bio::SeqFeature::Generic(
            -start        => 1,
            -end          => $target_arm->length,
            -strand       => 1,
            -primary      => 'misc_feature',       # -primary_tag is a synonym
            -source_tag   => 'synthetic_construct',
            -display_name => 'target_region',
            -tag => { note => 'target region' }
        );
        $target_arm->add_SeqFeature($feat);
    }

    ######### 3' arm #############
    $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $three_arm->length,
        -strand       => 1,
        -primary      => 'misc_feature',          # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => '3_arm',
        -tag          => { note => '3 arm' }
    );
    $three_arm->add_SeqFeature($feat);

    if ( $self->synth_stage eq 'gateway' ) {
        $self->create_final_v1( $five_arm, $target_arm, $three_arm );
    }
    elsif ( $self->synth_stage eq 'intermediate' ) {
        $self->create_intermediate_v1( $five_arm, $target_arm, $three_arm );
    }
    elsif ( $self->synth_stage eq 'allele' ) {
        $self->create_allele_v1( $five_arm, $target_arm, $three_arm );
    }
    else { die "Unknown synth stage\n"; }

    return $self->sequence;
}

sub create_intermediate_v1 {
    local $_;    #dj3 - workaround for bioperl $_ bug
    my ( $self, $five_arm, $target_arm, $three_arm ) = @_;

    #my $name = 'interm_' . $self->design->design_tag;
    my $name     = $self->unique_tag;
    my $synthseq = Bio::Seq::RichSeq->new(
        -id          => $name,
        -seq         => '',
        -is_circular => 1,
        -alphabet    => 'dna'
    );

    my $bbtag = $self->gateway_backbone_tag;
    if ( $bbtag eq 'default' or not defined $bbtag )
    {    #orginal default backbone
        Bio::SeqUtils->cat(
            $synthseq, $self->rich_r3r4_asis1_U,
            $five_arm, $self->rich_r1r2_zp,
        );
        Bio::SeqUtils->cat( $synthseq, $target_arm, $self->rich_loxp, )
            if $target_arm;    #Assume deletion if target_arm not defined.
        Bio::SeqUtils->cat( $synthseq, $three_arm, $self->rich_r3r4_asis1_D );

        $self->sequence($synthseq);
        $self->cassette_formula(
            $target_arm
            ? "r3r4_asis1_U, five_arm, r1r2_zp, target_arm, loxp, three_arm, r3r4_asis1_D"
            : "r3r4_asis1_U, five_arm, r1r2_zp, three_arm, r3r4_asis1_D"
        );
    }
    else {

# a horrid temporary hack to get Barry's alternate (extra recombineering stage) backbone in.
# Should really do this on recomb oligos and cut sites - using gateway splicing here
# as result should be the same in this case
        my ( $bbseqU, $bbseqD ) = $self->_backbone_to_bsites();
        Bio::SeqUtils->cat( $synthseq, $bbseqU, $self->junction_from_b3 );
        my $formula = $self->gateway_backbone_tag . "_U, ";
        Bio::SeqUtils->cat( $synthseq, $five_arm, $self->rich_r1r2_zp, );
        $formula .= "five_arm, r1r2_zp, ";
        Bio::SeqUtils->cat( $synthseq, $target_arm, $self->rich_loxp, )
            if $target_arm;    #Assume deletion if target_arm not defined.
        $formula .= "target_arm, loxp, " if $target_arm;
        Bio::SeqUtils->cat( $synthseq, $three_arm, );
        $formula .= "three_arm, ";
        Bio::SeqUtils->cat( $synthseq, $self->junction_to_b4, $bbseqD );
        $formula .= $self->gateway_backbone_tag . "_D";
        $self->sequence($synthseq);
        $self->cassette_formula($formula);
    }
    return $synthseq;
}

sub _backbone_to_bsites {
    my ($self) = @_;
    my ( $bbseqU, $bbseqD );
    my $bbseq = get_backbone_seq( $self->gateway_backbone_tag );
    my ($b3) = grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB3\b/
    } $bbseq->get_SeqFeatures;
    if ( $b3->strand != -1 ) {
        $bbseq = Bio::SeqUtils->revcom_with_features($bbseq);
        ($b3) = grep {
            $_->primary_tag eq q(gateway)
                and join( " ", $_->get_tag_values(q(note)) )
                =~ /\bB3\b/
        } $bbseq->get_SeqFeatures;
    }
    die "urrgh - cannot cope with backbone b3 in this ("
        . $b3->strand
        . ") orientation - yet"
        unless $b3->strand == -1;
    $bbseqU = Bio::SeqUtils->trunc_with_features( $bbseq, 1, $b3->end );
    my ($b4) = grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB4\b/
    } $bbseq->get_SeqFeatures;
    die "b4 must have opp orientation to b3" unless $b4->strand == 1;
    if ( $b3->start > $b4->end ) {
        my ($u) = grep {
            join( " ", $_->get_tag_values(q(note)) )
                =~ /\bU backbone\b/
        } $bbseq->get_SeqFeatures;
        my ($d) = grep {
            join( " ", $_->get_tag_values(q(note)) )
                =~ /\bD backbone\b/
        } $bbseq->get_SeqFeatures;
        if ( $u and $d ) {
            $bbseqU = Bio::SeqUtils->trunc_with_features( $bbseq, $u->start,
                $u->end );
            $bbseqD = Bio::SeqUtils->trunc_with_features( $bbseq, $d->start,
                $d->end );
        }
        else {
            die
                "b3 and b4 positioned such that I don't know where to start the synthetic construct";
        }
    }
    else {
        $bbseqD = Bio::SeqUtils->trunc_with_features( $bbseq, $b4->start,
            $bbseq->length );
    }
    return ( $bbseqU, $bbseqD );
}

sub create_final_v1 {
    local $_;    #dj3 - workaround for bioperl $_ bug
    my ( $self, $five_arm, $target_arm, $three_arm ) = @_;

    #my $name = 'final_' .  $self->design->design_tag;
    my $name     = $self->unique_tag;
    my $synthseq = Bio::Seq::RichSeq->new(
        -id          => $name,
        -seq         => '',
        -is_circular => 1,
        -alphabet    => 'dna'
    );
    my $design  = $self->design;
    my $formula = "";

    my ( $bbseqU, $bbseqD );
    if (   $self->gateway_backbone_tag
        && $self->gateway_backbone_tag ne 'default' )
    {
        ( $bbseqU, $bbseqD ) = $self->_backbone_to_bsites();
        Bio::SeqUtils->cat( $synthseq, $bbseqU, $self->junction_from_b3 );
        $formula .= $self->gateway_backbone_tag . "_U, ";
    }
    else {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l3l4_dta_U );
        $formula .= "l3l4_dta_U, ";
    }

    Bio::SeqUtils->cat( $synthseq, $five_arm, $self->rich_b1_junction );
    $formula .= "five_arm, b1_junction, ";

    if ( $self->gateway_cassette_tag eq 'gt0' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt0 );
        $formula .= "l1l2_gt0, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gt1' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt1 );
        $formula .= "l1l2_gt1, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gt2' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt2 );
        $formula .= "l1l2_gt2, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gtk' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gtk );
        $formula .= "l1l2_gtk, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st0' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st0 );
        $formula .= "l1l2_st0, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st1' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st1 );
        $formula .= "l1l2_st1, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st2' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st2 );
        $formula .= "l1l2_st2, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gpr' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gpr );
        $formula .= "l1l2_gpr, ";
    }
    elsif ( my $s = get_gateway_cassette( $self->gateway_cassette_tag ) ) {
        Bio::SeqUtils->cat( $synthseq, $s );
        $formula .= $self->gateway_cassette_tag . ", ";
    }
    else { die "Unknown cassette tag for final/gateway stage.\n"; }

    Bio::SeqUtils->cat( $synthseq, $self->rich_b2_junction, );
    $formula .= "b2_junction, ";
    if ($target_arm) {    #Assume deletion if target_arm not defined.
        Bio::SeqUtils->cat( $synthseq, $target_arm, $self->rich_loxp, );
        $formula .= "target_arm, loxp, ";
    }
    Bio::SeqUtils->cat( $synthseq, $three_arm, );
    $formula .= "three_arm, ";

    if (   $self->gateway_backbone_tag
        && $self->gateway_backbone_tag ne 'default' )
    {
        Bio::SeqUtils->cat( $synthseq, $self->junction_to_b4, $bbseqD );
        $formula .= $self->gateway_backbone_tag . "_D";
    }
    else {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l3l4_dta_D, );
        $formula .= "l3l4_dta_D";
    }

    $self->sequence($synthseq);
    $self->cassette_formula($formula);
    return $synthseq;
}

sub create_allele_v1 {
    local $_;    #dj3 - workaround for bioperl $_ bug
    my ( $self, $five_arm, $target_arm, $three_arm ) = @_;

    #my $name = 'allele_' .  $self->design->design_tag;
    my $name     = $self->unique_tag;
    my $synthseq = Bio::Seq::RichSeq->new(
        -id          => $name,
        -seq         => '',
        -is_circular => 0,
        -alphabet    => 'dna'
    );
    my $design = $self->design;

    Bio::SeqUtils->cat( $synthseq, $five_arm, $self->rich_b1_junction );

    my $formula = "five_arm, b1_junction, ";

    if ( $self->gateway_cassette_tag eq 'gt0' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt0 );
        $formula .= "l1l2_gt0, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gt1' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt1 );
        $formula .= "l1l2_gt1, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gt2' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gt2 );
        $formula .= "l1l2_gt2, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gtk' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gtk );
        $formula .= "l1l2_gtk, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st0' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st0 );
        $formula .= "l1l2_st0, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st1' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st1 );
        $formula .= "l1l2_st1, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'st2' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_st2 );
        $formula .= "l1l2_st2, ";
    }
    elsif ( $self->gateway_cassette_tag eq 'gpr' ) {
        Bio::SeqUtils->cat( $synthseq, $self->rich_l1l2_gpr );
        $formula .= "l1l2_gpr, ";
    }
    elsif ( my $s = get_gateway_cassette( $self->gateway_cassette_tag ) ) {
        Bio::SeqUtils->cat( $synthseq, $s );
        $formula .= $self->gateway_cassette_tag . ", ";
    }
    else { die "Unknown cassette tag for allele stage.\n"; }

    Bio::SeqUtils->cat( $synthseq, $self->rich_b2_junction, );
    $formula .= "b2_junction, ";
    if ($target_arm) {    #Assume deletion if target_arm not defined.
        Bio::SeqUtils->cat( $synthseq, $target_arm, $self->rich_loxp, );
        $formula .= "target_arm, loxp, ";
    }
    Bio::SeqUtils->cat( $synthseq, $three_arm, );
    $formula .= "three_arm";

    $self->sequence($synthseq);
    $self->cassette_formula($formula);
    return $synthseq;
}

#################################################

sub description {
    my $self = shift;
    my $str  = sprintf(
        "synvec[%s] %s (designI %s) %s %s %s_%s",
        $self->id,                     $self->name,
        $self->design->design_inst_id, $self->design->gene_name,
        $self->design->exon_name,      $self->design->plate,
        $self->design->well
    );
    return $str;
}

#################################################

sub rich_r1r2_zp {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pR6K_R1R2_ZP_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_loxp {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pR6Kloxp_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_r3r4_asis1_U {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pR3R4AsiSI_synvect_U.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_r3r4_asis1_D {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pR3R4AsiSI_synvect_D.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

#################################################
# final vector elements
#

sub get_backbone_seq {
    my $name = shift;
    die "No data available for backbone $name"
        unless my $fn = $BACKBONES{$name}{'filename'};

    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/" . $fn,
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    $seq->alphabet(q(DNA));

    #marked up for U and D parts of final targetting vector?
    return $seq;
}

sub get_cassette_vector_seq {
    my $name = shift;
    die "No data available for cassette $name"
        unless my $fn = $CASSETTES{$name}{'filename'};

    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/" . $fn,
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    $seq->alphabet(q(DNA));
    for ( $seq->get_SeqFeatures ) {
        if ( my @n = $_->get_tag_values(q(note)) ) {
            if ( $_->primary_tag eq q(misc_feature) ) {
                if ( join( " ", @n ) =~ /(LRPCR )?(LAR|RAF)/i ) {
                    $_->primary_tag(q(LRPCR_primer));

                    #add tag of type "type" with value $2 ?
                }
                elsif ( join( " ", @n ) =~ /(?i:primer)|CHK/
                    or scalar( grep {/\S+[35]'?\s*$/} @n ) )
                {
                    $_->primary_tag(q(primer_bind));
                }
                elsif ( scalar( grep {/\b[LRB][1-4]\b/} @n ) ) {
                    $_->primary_tag(q(gateway))

                        #}elsif(join(" ",@n)=~/(?:(?:ex|intr)on)|promoter/i){
                }
                elsif ( join( " ", @n ) =~ /promoter/i ) {
                    $_->primary_tag( lc $& );
                }
                elsif ( join( " ", @n ) =~ /loxp|frt/i ) {
                    $_->primary_tag(q(SSR_site));
                }
                elsif ( join( " ", @n ) =~ /\bpA\b/ ) {
                    $_->primary_tag(q(polyA_site));
                }
            }
        }
    }
    return $seq;
}

sub get_gateway_cassette {
    my $name = shift;
    if ( $name eq 'L1L2_st1' ) {
        warn "Awaiting map verified form Barry";
        return rich_l1l2_st1();
    }
    my ( $trunc_start, $trunc_end );
    my $seq = get_cassette_vector_seq($name);
    for ( $seq->get_SeqFeatures ) {
        if ( $_->primary_tag eq q(gateway)
            and my @n = $_->get_tag_values(q(note)) )
        {
            $trunc_start = $_->end + 1   if ( join( " ", @n ) =~ /\bL1\b/ );
            $trunc_end   = $_->start - 2 if ( join( " ", @n ) =~ /\bL2\b/ );
        }
    }
    if ( defined($trunc_start) and defined($trunc_end) ) {
        my $f = new Bio::SeqFeature::Generic(
            -start   => $trunc_start,
            -end     => $trunc_end,
            -primary => q(target_element)
        );
        $seq->add_SeqFeature($f);
        $seq = Bio::SeqUtils->trunc_with_features( $seq, $trunc_start,
            $trunc_end );
    }
    else {
        die
            "unable to find L1 and L2 from which to extract cassette for $name";
    }
    return $seq;
}

sub rich_l3l4_dta_U {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL3L4_DTA_synvec_U.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l3l4_dta_D {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL3L4_DTA_synvec_D.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_b1_junction {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/B1_ZP_junction.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    $seq->display_id(q(B1_junction));
    return $seq;
}

sub rich_b2_junction {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/B2_ZP_junction.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    $seq->display_id(q(B2_junction));
    return $seq;
}

sub rich_b3_junction {
    my $seq = rich_r3r4_asis1_U;
    my ($s) = map { $_->start } grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB3\b/
    } $seq->get_SeqFeatures;
    $seq = Bio::SeqUtils->trunc_with_features( $seq, $s, $seq->length );
    $seq->display_id(q(B3_junction));
    return $seq;
}

sub junction_from_b3 {
    my $seq = rich_r3r4_asis1_U;
    my ($e) = map { $_->end } grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB3\b/
    } $seq->get_SeqFeatures;
    $seq = Bio::SeqUtils->trunc_with_features( $seq, $e + 1, $seq->length );
    $seq->display_id(q(junction_from_B3));
    return $seq;
}

sub rich_b4_junction {
    my $seq = rich_r3r4_asis1_D;
    my ($e) = map { $_->end } grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB4\b/
    } $seq->get_SeqFeatures;
    $seq = Bio::SeqUtils->trunc_with_features( $seq, 1, $e );
    $seq->display_id(q(B4_junction));
    return $seq;
}

sub junction_to_b4 {
    my $seq = rich_r3r4_asis1_D;
    my ($s) = map { $_->start } grep {
        $_->primary_tag eq q(gateway)
            and join( " ", $_->get_tag_values(q(note)) )
            =~ /\bB4\b/
    } $seq->get_SeqFeatures;
    $seq = Bio::SeqUtils->trunc_with_features( $seq, 1, $s - 1 );
    $seq->display_id(q(junction_to_B4));
    return $seq;
}

sub rich_l1l2_gt0 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_GT0_EUCOMM_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_gt1 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_GT1_EUCOMM_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_gt2 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_GT2_EUCOMM_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_gtk {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_GTK_EUCOMM_synvec.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_st0 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_ST0_EUCOMM.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_st1 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_ST1_EUCOMM.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_st2 {
    my $seqio = Bio::SeqIO->new(
        -file   => $GLOBAL_SYNTHVEC_DATADIR . "/pL1L2_ST2_EUCOMM.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    return $seq;
}

sub rich_l1l2_gpr {
    my $seqio = Bio::SeqIO->new(
        -file => $GLOBAL_SYNTHVEC_DATADIR
            . "/pL1L2_GTIRES_BetactP FLFL Map.gbk",
        -format => 'genbank'
    );
    my $seq = $seqio->next_seq;
    $seq->alphabet(q(DNA));
    my ( $trunc_start, $trunc_end );
    for ( $seq->get_SeqFeatures ) {
        if ( my @n = $_->get_tag_values(q(note)) ) {
            if ( $_->primary_tag eq q(misc_feature) ) {
                if ( join( " ", @n ) =~ /primer/i ) {
                    $_->primary_tag(q(primer_bind))

                        #}elsif(join(" ",@n)=~/(?:(?:ex|intr)on)|promoter/i){
                }
                elsif ( join( " ", @n ) =~ /promoter/i ) {
                    $_->primary_tag($&);
                }
                elsif ( join( " ", @n ) =~ /loxp|frt/i ) {
                    $_->primary_tag(q(SSR_site));
                }
                elsif ( join( " ", @n ) =~ /\b[LRB][1-4]\b/ ) {
                    $_->primary_tag(q(gateway));
                }
                elsif ( join( " ", @n ) =~ /\bpA\b/ ) {
                    $_->primary_tag(q(polyA_site));
                }
            }
            $trunc_start = $_->end + 1 if join( " ", @n ) =~ /\bL1\s*site\b/i;
            $trunc_end = $_->start - 2 if join( " ", @n ) =~ /\bL2\s*site\b/i;
        }
    }
    if ( defined($trunc_start) and defined($trunc_end) ) {
        my $f = new Bio::SeqFeature::Generic(
            -start   => $trunc_start,
            -end     => $trunc_end,
            -primary => q(target_element)
        );
        $seq->add_SeqFeature($f);
        $seq = Bio::SeqUtils->trunc_with_features( $seq, $trunc_start,
            $trunc_end );
    }
    return $seq;
}

#################################################

sub create_kanamycin_sequence {
    my $seq
        = "CCTAGGTGTACAGTTTAAACGCGGCCGCATTCTACCGGGTAGGGGAGGCGCTTTTCCCAAGGCAGTCTGGAGCATGCGCT
    TTAGCAGCCCCGCTGGGCACTTGGCGCTACACAAGTGGCCTCTGGCCTCGCACACATTCCACATCCACCGGTAGGCGCCA
    ACCGGCTCCGTTCTTTGGTGGCCCCTTCGCGCCACCTTCTACTCCTCCCCTAGTCAGGAAGTTCCCCCCCGCCCCGCAGC
    TCGCGTCGTGCAGGACGTGACAAATGGAAGTAGCACGTCTCACTAGTCTCGTGCAGATGGACAGCACCGCTGAGCAATGG
    AAGCGGGTAGGCCTTTGGGGCAGCGGCCAATAGCAGCTTTGCTCCTTCGCTTTCTGGGCTCAGAGGCTGGGAAGGGGTGG
    GTCCGGGGGCGGGCTCAGGGGCGGGCTCAGGGGCGGGGCGGGCGCCCGAAGGTCCTCCGGAGGCCCGGCATTCTGCACGC
    TTCAAAAGCGCACGTCTGCCGCGCTGTTCTCCTCTTCCTCATCTCCGGGCCTTTCGACCTGCAGCAGCACGTGTTGACAA
    TTAATCATCGGCATAGTATATCGGCATAGTATAATACGACAAGGTGAGGAACTAAACCATGGGATCGGCCATTGAACAAG
    ATGGATTGCACGCAGGTTCTCCGGCCGCTTGGGTGGAGAGGCTATTCGGCTATGACTGGGCACAACAGACAATCGGCTGC
    TCTGATGCCGCCGTGTTCCGGCTGTCAGCGCAGGGGCGCCCGGTTCTTTTTGTCAAGACCGACCTGTCCGGTGCCCTGAA
    TGAACTGCAGGACGAGGCAGCGCGGCTATCGTGGCTGGCCACGACGGGCGTTCCTTGCGCAGCTGTGCTCGACGTTGTCA
    CTGAAGCGGGAAGGGACTGGCTGCTATTGGGCGAAGTGCCGGGGCAGGATCTCCTGTCATCTCACCTTGCTCCTGCCGAG
    AAAGTATCCATCATGGCTGATGCAATGCGGCGGCTGCATACGCTTGATCCGGCTACCTGCCCATTCGACCACCAAGCGAA
    ACATCGCATCGAGCGAGCACGTACTCGGATGGAAGCCGGTCTTGTCGATCAGGATGATCTGGACGAAGAGCATCAGGGGC
    TCGCGCCAGCCGAACTGTTCGCCAGGCTCAAGGCGCGCATGCCCGACGGCGAGGATCTCGTCGTGACCCATGGCGATGCC
    TGCTTGCCGAATATCATGGTGGAAAATGGCCGCTTTTCTGGATTCATCGACTGTGGCCGGCTGGGTGTGGCGGACCGCTA
    TCAGGACATAGCGTTGGCTACCCGTGATATTGCTGAAGAGCTTGGCGGCGAATGGGCTGACCGCTTCCTCGTGCTTTACG
    GTATCGCCGCTCCCGATTCGCAGCGCATCGCCTTCTATCGCCTTCTTGACGAGTTCTTCTGAGCGGGACTCTGGGGTTCG
    AATAAAGACCGACCAAGCGACGTCTGAGAGCTCCCTGGCGAATTCGGTACCAATAAAAGAGCTTTATTTTCATGATCTGT
    GTGTTGGTTTTTGTGTGCGGCGCGCCGTTTAAACGCGGCCGCCAATTGTCTAGACAATTG";

    $seq =~ s/\s//g;
    my $vector = Bio::Seq::RichSeq->new( -id => 'kanamycin', -seq => $seq );
    warn sprintf( "%s len=%d\n", $vector->display_id, $vector->length );
    return $vector;
}

sub b3 {
    my $seq = "GTTCAACTTTATTATACAAAGTTGC";
    $seq =~ s/\s//g;
    my $vector = Bio::Seq::RichSeq->new( -id => 'B3', -seq => $seq );
    warn sprintf( "%s len=%d\n", $vector->display_id, $vector->length );

    my $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $vector->length,
        -strand       => 1,
        -primary      => 'gateway',               # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => 'B3',
        -tag          => { note => 'B3' }
    );
    $vector->add_SeqFeature($feat);

    return $vector;
}

sub b4_rev {
    my $seq = "GTTCAACTTTTCTATACAAAGTTGT";
    $seq =~ s/\s//g;
    my $vector = Bio::Seq::RichSeq->new( -id => 'B4', -seq => $seq );
    $vector = $vector->revcom;
    warn sprintf( "%s len=%d\n", $vector->display_id, $vector->length );

    my $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $vector->length,
        -strand       => -1,
        -primary      => 'gateway',               # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => 'B4',
        -tag          => { note => 'B4' }
    );
    $vector->add_SeqFeature($feat);

    return $vector;
}

sub b1_rev {
    my $seq = "GTTCAGCTTTTTTGTACAAACTTGT";

    $seq =~ s/\s//g;
    my $vector = Bio::Seq::RichSeq->new( -id => 'B1', -seq => $seq );
    $vector = $vector->revcom;
    warn sprintf( "%s len=%d\n", $vector->display_id, $vector->length );
    my $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $vector->length,
        -strand       => -1,
        -primary      => 'gateway',               # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => 'B1',
        -tag          => { note => 'B1' }
    );
    $vector->add_SeqFeature($feat);
    return $vector;
}

sub b2 {
    my $seq = "GTTCAGCTTTCTTGTACAAAGTGGT";
    $seq =~ s/\s//g;
    my $vector = Bio::Seq::RichSeq->new( -id => 'B2', -seq => $seq );
    warn sprintf( "%s len=%d\n", $vector->display_id, $vector->length );
    my $feat = new Bio::SeqFeature::Generic(
        -start        => 1,
        -end          => $vector->length,
        -strand       => 1,
        -primary      => 'gateway',               # -primary_tag is a synonym
        -source_tag   => 'synthetic_construct',
        -display_name => 'B2',
        -tag          => { note => 'B2' }
    );
    $vector->add_SeqFeature($feat);
    return $vector;
}

#################################################
#
# DBObject override methods
#
#################################################

##### DBObject instance override methods #####

sub mapRow {
    my $self    = shift;
    my $rowHash = shift;
    my $dbh     = shift;

    $self->SUPER::mapRow( $rowHash, $dbh );

    $self->synth_stage( $rowHash->{'STAGE'} );
    $self->id_vector( $rowHash->{'ID_VECTOR'} );
    $self->cassette_formula( $rowHash->{'CASSETTE_FORMULA'} );
    $self->genbank_accession( $rowHash->{'GENBANK_ACCESSION'} );
    $self->sequence->accession_number( $self->genbank_accession );

    #for lazy loading
    $self->{'design_inst_id'} = $rowHash->{'DESIGN_INSTANCE_ID'};

    $self->{'plate'} = $rowHash->{'DESIGN_PLATE'};
    $self->{'well'}  = $rowHash->{'DESIGN_WELL'};

    return $self;
}

sub store {
    my $self = shift;
    my $db   = shift;
    if ($db) { $self->database($db); }

    my $sql
        = "select * from synthetic_vector JOIN engineered_seq using(engineered_seq_id) where design_instance_id=? and stage=? and cassette_formula=?";

    # BUNCH OF WARNINGS THROWN HERE
    my $ar
        = __PACKAGE__->fetch_multiple( $db, $sql,
        $self->design->design_inst_id,
        $self->synth_stage, $self->cassette_formula );
    foreach my $svdb (@$ar) {
        if ($svdb->sequence->seq eq $self->sequence->seq
            and (    #so check sequences and feature locations are the same
                join(
                    "\t",
                    map { join ",", @$_ } sort {
                        $a->[0] <=> $b->[0]
                            or $a->[1] <=> $b->[1]
                            or $a->[2] <=> $b->[2]
                        }
                        map {
                        [ $_->start, $_->end, $_->strand, $_->primary_tag ]
                        } $svdb->sequence->all_SeqFeatures
                ) eq join(
                    "\t",
                    map { join ",", @$_ } sort {
                        $a->[0] <=> $b->[0]
                            or $a->[1] <=> $b->[1]
                            or $a->[2] <=> $b->[2]
                        }
                        map {
                        [ $_->start, $_->end, $_->strand, $_->primary_tag ]
                        } $self->sequence->all_SeqFeatures
                )
            )
            )
        {
            $self->primary_id( $svdb->primary_id );

            # this is here temporarily until id vectors have been updated
            $self->fill_in_id_vector($db);

            return $self;
        }
    }

    $self->SUPER::store($db);

    my $dbh = $self->database->get_connection;
    $sql = qq/
      INSERT INTO SYNTHETIC_VECTOR (
            ENGINEERED_SEQ_ID,
            DESIGN_INSTANCE_ID,
            ID_VECTOR,
            STAGE,
            CASSETTE_FORMULA,
            DESIGN_PLATE,
            DESIGN_WELL,
            GENBANK_ACCESSION
        ) 
      VALUES(?,?,?,?,?,?,?,?)/;
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $self->id );
    $sth->bind_param( 2, ( $self->design->design_inst_id ) );
    $sth->bind_param( 3, $self->id_vector );
    $sth->bind_param( 4, $self->synth_stage );
    $sth->bind_param( 5, $self->cassette_formula );
    if ( $self->design ) {
        $sth->bind_param( 6, ( $self->design->plate ) );
        $sth->bind_param( 7, ( $self->design->well ) );
    }
    else {
        $sth->bind_param( 6, undef );
        $sth->bind_param( 7, undef );
    }
    $sth->bind_param( 8, $self->genbank_accession );
    $sth->execute();
    $sth->finish;
    return $self;
}

# use temporarily to fill in id_vectors that are missing...
sub fill_in_id_vector {

    my $self = shift;
    my $db   = shift;
    if ($db) { $self->database($db); }

    return unless ( $self->id_vector && $self->primary_id );

    my $sql
        = "select id_vector from synthetic_vector where engineered_seq_id=?";
    my $vecID = $self->fetch_col_value( $db, $sql, $self->primary_id );

    # add the vector id if its not there
    unless ($vecID) {
        warn "updating id vector on synt "
            . $self->id_vector . " "
            . $self->primary_id . "\n";
        my $dbh = $self->database->get_connection;
        $sql
            = qq/ UPDATE SYNTHETIC_VECTOR SET ID_VECTOR = ? WHERE ENGINEERED_SEQ_ID = ? /;
        my $sth = $dbh->prepare($sql);
        $sth->bind_param( 1, $self->id_vector );
        $sth->bind_param( 2, $self->primary_id );
        $sth->execute();
        $sth->finish;
    }
}

##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
    my $class = shift;
    my $db    = shift;
    my $id    = shift;

    my $sql
        = "SELECT * FROM synthetic_vector "
        . "JOIN engineered_seq using(engineered_seq_id) "
        . "WHERE engineered_seq_id = ?";
    return $class->fetch_single( $db, $sql, $id );
}

sub fetch_by_design_inst_id
{    #this is not not good - synth vec not unique by design instance....
    my $class          = shift;
    my $db             = shift;
    my $design_inst_id = shift;

    my $sql
        = "SELECT * FROM synthetic_vector "
        . "JOIN engineered_seq using(engineered_seq_id) "
        . "WHERE design_instance_id = ?";
    return $class->fetch_single( $db, $sql, $design_inst_id );
}

1;

