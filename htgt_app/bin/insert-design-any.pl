#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Const::Fast;
use YAML::Any;
use HTGT::DBFactory;
use Log::Log4perl ':easy';
use Data::Dump 'pp';
use Getopt::Long;

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

const my $GENE_BUILD_VERSION               => '65.37';
const my $CREATED_STATUS_ID                => get_design_status ( 'Created' );
const my $NOTE_TYPE_INFO_ID                => get_design_note_type( 'Info' );
const my $FALSE_INTRON_COMMENT_CATEGORY_ID => get_design_comment_category( 'Artificial intron design' );

const my %DESIGN_PARAMS => (
    primer_length              => 50,
    retrieval_primer_length_3p => 1000,
    retrieval_primer_length_5p => 1000,
    retrieval_primer_offset_3p => 4500,
    retrieval_primer_offset_5p => 6500,
    created_user               => $ENV{USER},
    score                      => 'design_finder_v2.1',
);

{
    my $log_level = $WARN;

    GetOptions(
        'debug'   => sub { $log_level = $DEBUG },
        'verbose' => sub { $log_level = $INFO },
        'commit'  => \my $commit,
    ) and @ARGV == 1 or die "Usage: $0 [--debug|--verbose|--commit] designs.yaml\n";

    Log::Log4perl->easy_init(
        {
            layout => '%m%n',
            level  => $log_level
        }
    );

    my %params = %DESIGN_PARAMS;
    for my $design ( YAML::Any::LoadFile( shift @ARGV ) ) {

        my $gene_build = get_gene_build( $GENE_BUILD_VERSION );

        my $gnm_start_exon = get_gnm_exon( $design->{ ensembl_gene_id },
                                           $design->{ ensembl_transcript_id },
                                           $design->{ first_critical_exon },
                                           $gene_build->id );
        my $gnm_end_exon = get_gnm_exon( $design->{ ensembl_gene_id },
                                         $design->{ ensembl_transcript_id },
                                         $design->{ last_critical_exon },
                                         $gene_build->id );
        ( $gnm_start_exon, $gnm_end_exon ) = check_exon_order( $gnm_start_exon, $gnm_end_exon );

        $params{gene_build_id}            = $gene_build->id;
        $params{assembly_id}              = $gene_build->assembly_id;
        $params{selected_gene_build_gene} = $design->{ensembl_gene_id};
        $params{transcript_id}            = $design->{ensembl_transcript_id};
        $params{start_exon}               = $gnm_start_exon->id;
        $params{end_exon}                 = $gnm_end_exon->id;
        $params{chr_name}                 = $design->{chromosome};
        $params{chr_strand}               = $design->{strand};
        $params{phase}                    = $design->{phase};

        $htgt->txn_do(

            sub {
                if ( $design->{design_type} eq 'Standard' ){
                    add_standard_parameters( \%params, $design );
                    $design->{design_id} = create_standard_design( \%params );
                }
                else{
                    add_false_intron_parameters( \%params, $design );
                    $design->{design_id} = create_false_intron_design( \%params );
                }
                print $design->{ensembl_gene_id} . "\t" . $design->{ design_id };
                if( $design->{transcript_overlap_status} ){
                    print "\t" . $design->{transcript_overlap_status} . "\n";
                }
                else{
                    print "\n";
                }
                unless ( $commit ) {
                    WARN( "Rollback" );
                    $htgt->txn_rollback;
                }
            }
        );
    }
}

sub get_gene_build {
    my ( $version ) = @_;

    my $gene_build = $htgt->resultset( 'GnmGeneBuild' )->find( { version => $version } )
        or die "Failed to retrieve GnmGeneBuild for version '$version'";

    DEBUG( "Gene build ID: " . $gene_build->id );
    DEBUG( "Assembly ID: " . $gene_build->assembly_id );

    return $gene_build;
}

sub get_gnm_exon{
    my ( $ens_gene_id, $ens_transcript_id, $ens_exon_id, $gene_build_id ) = @_;

    my $exon = $htgt->resultset( 'GnmExon' )->find(
        {
            'me.primary_name'              => $ens_exon_id,
            'transcript.primary_name'      => $ens_transcript_id,
            'gene_build_gene.primary_name' => $ens_gene_id,
            'gene_build_gene.build_id'     => $gene_build_id,
        },
        {
            join     => { transcript => 'gene_build_gene' },
        }
    );

    return $exon;
}

sub check_exon_order{
    my ( $start_exon, $end_exon ) = @_;

    my $strand = $start_exon->locus->chr_strand;

    if ( $strand == 1 ){
        if ( $start_exon->locus->chr_start > $end_exon->locus->chr_start ){
            ( $start_exon, $end_exon ) = ( $end_exon, $start_exon );
        }
    }
    else{
        if ( $start_exon->locus->chr_start < $end_exon->locus->chr_start ){
            ( $start_exon, $end_exon ) = ( $end_exon, $start_exon );
        }
    }
    DEBUG( "Start exon ID: " . $start_exon->id );
    DEBUG( "End exon ID: " . $end_exon->id );

    return ( $start_exon, $end_exon );
}

sub add_standard_parameters{
    my ( $params, $design ) = @_;

    ${ $params }{min_3p_exon_flanks} = $design->{min_threep_spacer};
    ${ $params }{min_5p_exon_flanks} = $design->{min_fivep_spacer};
    ${ $params }{multi_region_5p_offset_shim} = $design->{fivep_offset};
    ${ $params }{multi_region_3p_offset_shim} = $design->{threep_offset};
    ${ $params }{split_5p_target_seq_length} = $design->{fivep_block_size};
    ${ $params }{split_3p_target_seq_length} = $design->{threep_block_size};
    ${ $params }{target_start} = $design->{target_start};
    ${ $params }{target_end} = $design->{target_end};
    return;
}

sub add_false_intron_parameters{
    my ( $params, $design ) = @_;

    if ( $design->{strand} == 1 ){
        ${ $params }{cassette_start} = $design->{u5_end};
        ${ $params }{cassette_end}   = $design->{u3_start};
        ${ $params }{loxp_start}     = $design->{d5_end};
        ${ $params }{loxp_end}       = $design->{d3_start};
        ${ $params }{target_start}   = $design->{u3_start};
        ${ $params }{target_end}     = $design->{d5_end};
    }
    else {
        ${ $params }{cassette_start} = $design->{u3_end};
        ${ $params }{cassette_end}   = $design->{u5_start};
        ${ $params }{loxp_start}     = $design->{d3_end};
        ${ $params }{loxp_end}       = $design->{d5_start};
        ${ $params }{target_start}   = $design->{d5_start};
        ${ $params }{target_end}     = $design->{u3_end};
    }
}

sub get_design_status {
    my $description = shift;

    my $status = $htgt->resultset( 'DesignStatusDict' )->find( { description => $description } )
        or die "Failed to retrieve DesignStatusDict entry for '$description'";

    return $status->design_status_id;
}

sub get_design_note_type {
    my $description = shift;

    my $design_note_type = $htgt->resultset( 'DesignNoteTypeDict' )->find( { description => $description } )
        or die "failed to retrieve DesignNoteTypeDict entry for '$description'";

    return $design_note_type->design_note_type_id;
}

sub get_design_comment_category {
    my $name = shift;

    my $design_comment_category = $htgt->resultset( 'DesignUserCommentCategories' )->find( { category_name => $name } )
        or die "failed to retrieve DesignUserCommentCategories entry for '$name'";

    return $design_comment_category->category_id;
}

sub create_standard_design {
    my ( $params ) = @_;

    

    INFO( "Creating design for $params->{selected_gene_build_gene}" );
    DEBUG( "create_design: " . pp( $params ) );

    my $locus = create_locus( $params );

    my $parameter_string = join q{,}, map { "$_=$params->{$_}" } qw(
        min_3p_exon_flanks
        min_5p_exon_flanks
        multi_region_5p_offset_shim
        multi_region_3p_offset_shim
        primer_length
        retrieval_primer_length_3p
        retrieval_primer_length_5p
        retrieval_primer_offset_3p
        retrieval_primer_offset_5p
        split_5p_target_seq_length
        split_3p_target_seq_length
        score );
    my $design_parameter = create_design_parameter( $parameter_string );

    my $design = $htgt->resultset( 'Design' )->create(
        {
            start_exon_id       => $params->{start_exon},
            end_exon_id         => $params->{end_exon},
            gene_build_id       => $params->{gene_build_id},
            locus_id            => $locus->id,
            design_parameter_id => $design_parameter->id,
            created_user        => $params->{created_user},
            design_type         => 'KO',
            phase               => $params->{phase}
        }
    );

    create_design_status_and_note_type( $design );

    return $design->design_id;
}

sub create_false_intron_design {
    my ( $params ) = @_;

    INFO( "Creating design for $params->{selected_gene_build_gene}" );
    DEBUG( "create_design: " . pp( $params ) );

    my $locus = create_locus( $params );

    my $parameter_string = join q{,}, map { "$_=$params->{$_}" } qw(
        primer_length
        retrieval_primer_length_3p
        retrieval_primer_length_5p
        retrieval_primer_offset_3p
        retrieval_primer_offset_5p
        score
        cassette_start
        cassette_end
        loxp_start
        loxp_end );
    my $design_parameter = create_design_parameter( $parameter_string );

    my $design = $htgt->resultset( 'Design' )->create(
        {
            start_exon_id       => $params->{start_exon},
            end_exon_id         => $params->{end_exon},
            gene_build_id       => $params->{gene_build_id},
            locus_id            => $locus->id,
            design_parameter_id => $design_parameter->id,
            created_user        => $params->{created_user},
            design_type         => 'KO_Location',
            subtype             => 'frameshift',
            phase               => $params->{phase}
        }
    );

    create_design_status_and_note_type( $design );

    create_false_intron_design_comment( $design );

    return $design->design_id;
}

sub create_locus{
    my ( $params ) = @_;

    my $locus = $htgt->resultset( 'GnmLocus' )->create(
        {
            chr_name      => $params->{chr_name},
            chr_start     => $params->{target_start},
            chr_end       => $params->{target_end},
            chr_strand    => $params->{chr_strand},
            assembly_id   => $params->{assembly_id},
            type          => 'DESIGN'
        }
    ) or die 'failed to create GnmLocus';

    INFO( 'Created GnmLocus with id: ' . $locus->id );
    return $locus;
}

sub create_design_parameter{
    my ( $parameter_string ) = @_;
    DEBUG( "Parameter string: $parameter_string" );

    my $design_parameter = $htgt->resultset( 'DesignParameter' )
        ->create(
            {
                parameter_name  => 'custom knockout',
                parameter_value => $parameter_string
            }
        ) or die 'failed to create DesignParameter';

    return $design_parameter;
}

sub create_design_status_and_note_type{
    my ( $design ) = @_;

    my $design_status = $htgt->resultset( 'DesignStatus' )->create(
        {
            design_id        => $design->design_id,
            design_status_id => $CREATED_STATUS_ID,
            is_current       => 1
        }
    ) or die 'failed to create DesignStatus';

    INFO( 'Created DesignStatus');

    my $design_note = $htgt->resultset( 'DesignNote' )->create(
        {
            design_note_type_id => $NOTE_TYPE_INFO_ID,
            design_id           => $design->design_id,
            note                => 'Created'
        }
    ) or die 'failed to create DesignNote';

    INFO( 'Created DesignNote with type ID: ' . $design_note->design_note_type_id );

    return;
}

sub create_false_intron_design_comment{
    my ( $design ) = @_;

    my $design_comment = $htgt->resultset( 'DesignUserComments' )->create(
        {
            design_id   => $design->design_id,
            category_id => $FALSE_INTRON_COMMENT_CATEGORY_ID,
            edited_user => $ENV{USER},
            visibility  => 'public'
        }
    );

    INFO( 'Created DesignUserComments with category ID: ' . $design_comment->category_id );

    return;
}
