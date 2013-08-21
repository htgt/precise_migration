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

const my $GENE_BUILD_VERSION  => '63.37';
const my $CREATED_STATUS_ID   => get_design_status( 'Created' );
const my $NOTE_TYPE_INFO_ID   => get_design_note_type( 'Info' );
const my $COMMENT_CATEGORY_ID => get_design_comment_category( 'Artificial intron design' );

const my %DESIGN_PARAMS => (
    design_type                => 'KO_Location',
    oligo_select_method        => 'Location Specified',
    subtype                    => 'frameshift',
    gene_build_id              => get_gene_build_id( $GENE_BUILD_VERSION ),
    primer_length              => 50,
    retrieval_primer_length_3p => 1000,
    retrieval_primer_length_5p => 1000,
    retrieval_primer_offset_3p => 4500,
    retrieval_primer_offset_5p => 6500,
    created_user               => $ENV{USER},
    score                      => 'design_finder_v1.3.2'
);

{
    my $log_level = $WARN;

    GetOptions(
        'debug'    => sub { $log_level = $DEBUG },
        'verbose'  => sub { $log_level = $INFO },
        'commit'   => \my $commit,
        'skip=s@'  => \my @skip,
    ) and @ARGV == 1 or die "Usage: $0 [--debug|--verbose|--commit] designs.yaml\n";

    Log::Log4perl->easy_init(
        {
            layout => '%m%n',
            level  => $log_level
        }
    );

    my %skip = map { $_ => 1 } @skip;
    
    for my $design ( YAML::Any::LoadFile( shift @ARGV ) ) {
        next if $skip{ $design->{ensembl_gene_id} };
        my %params = %DESIGN_PARAMS;
        $params{selected_gene_build_gene} = $design->{ensembl_gene_id};
        $params{transcript_id}            = $design->{ensembl_transcript_id};
        $params{start_exon}               = $design->{ensembl_exon_id};
        $params{end_exon}                 = $design->{ensembl_exon_id};
        $params{phase}                    = $design->{phase} eq 'K' ? -1 : $design->{phase};

        if ( $design->{strand} == 1 ) {
            $params{cassette_start} = $design->{U5_end};
            $params{cassette_end}   = $design->{U3_start};
            $params{loxp_start}     = $design->{D5_end};
            $params{loxp_end}       = $design->{D3_start};
            $params{target_start}   = $params{cassette_end};
            $params{target_end}     = $params{loxp_start};                    
        }
        else {
            $params{cassette_start} = $design->{U3_end};
            $params{cassette_end}   = $design->{U5_start};
            $params{loxp_start}     = $design->{D3_end};
            $params{loxp_end}       = $design->{D5_start};
            $params{target_start}   = $params{loxp_end};
            $params{target_end}     = $params{cassette_start};            
        }

        $htgt->txn_do(
            sub {
                $design->{design_id} = create_design( \%params );
                print YAML::Any::Dump( $design );
                unless ( $commit ) {
                    WARN( "Rollback" );
                    $htgt->txn_rollback;
                }
            }
        );
    }
}

sub get_gene_build_id {
    my $version = shift;

    my $gene_build = $htgt->resultset( 'GnmGeneBuild' )->find( { version => $version } )
        or die "Failed to retrieve GnmGeneBuild for version '$version'";

    return $gene_build->id;
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

sub create_design {
    my $params = shift;

    INFO( "Creating design for $params->{selected_gene_build_gene}" );
    DEBUG( "create_design: " . pp( $params ) );

    my $exon = $htgt->resultset( 'GnmExon' )->find(
        {
            'me.primary_name'              => $params->{start_exon},
            'transcript.primary_name'      => $params->{transcript_id},
            'gene_build_gene.primary_name' => $params->{selected_gene_build_gene},
            'gene_build_gene.build_id'     => $params->{gene_build_id}
        },
        {
            join     => { transcript => 'gene_build_gene' },
            prefetch => { transcript => 'gene_build_gene' }
        }
    );

    DEBUG( "GnmExon: " . $exon->primary_name );
    
    my $gene_build_gene = $exon->transcript->gene_build_gene;

    DEBUG( "GnmGeneBuildGene: " . $gene_build_gene->primary_name );    
    
    my $parameter_string = join q{,}, map { "$_=$params->{$_}" } qw( primer_length 
                                                                     retrieval_primer_length_3p retrieval_primer_length_5p
                                                                     retrieval_primer_offset_3p retrieval_primer_offset_5p
                                                                     score cassette_start cassette_end loxp_start loxp_end
                                                               );
    DEBUG( "Parameter string: $parameter_string" );

    my $design_parameter = $htgt->resultset( 'DesignParameter' )->create(
        {
            parameter_name  => 'custom knockout',
            parameter_value => $parameter_string
        }
    ) or die "failed to create DesignParameter";

    INFO( "Created DesignParameter with id: " . $design_parameter->design_parameter_id );

    my $locus = $htgt->resultset( 'GnmLocus' )->create(
        {
            chr_name    => $gene_build_gene->locus->chr_name,
            chr_start   => $params->{target_start},
            chr_end     => $params->{target_end},
            chr_strand  => $gene_build_gene->locus->chr_strand,
            assembly_id => $gene_build_gene->gene_build->assembly_id,
            type        => 'DESIGN'
        }
    ) or die "failed to create GnmLocus";

    INFO( "Created GnmLocus with id: " . $locus->id );

    my $design = $htgt->resultset( 'Design')->create(
        {
            start_exon_id       => $exon->id,
            end_exon_id         => $exon->id,
            gene_build_id       => $gene_build_gene->gene_build->id,
            locus_id            => $locus->id,
            design_parameter_id => $design_parameter->id,
            created_user        => $params->{created_user},
            design_type         => $params->{design_type},
            subtype             => $params->{subtype},
            phase               => $params->{phase}
        }
    ) or die "failed to create Design";

    INFO( "Created Design with id: " . $design->design_id );

    my $design_status = $htgt->resultset( 'DesignStatus' )->create(
        {   design_id        => $design->design_id,
            design_status_id => $CREATED_STATUS_ID,
            is_current       => 1
        }
    ) or die "failed to create DesignStatus";

    INFO( "Created DesignStatus" );

    my $design_note = $htgt->resultset( 'DesignNote' )->create(
        {
            design_note_type_id => $NOTE_TYPE_INFO_ID,
            design_id           => $design->design_id,
            note                => 'Created'
        }
    );
    
    INFO( "Created DesignNote with id: " . $design_note->design_note_id );

    my $design_comment = $htgt->resultset( 'DesignUserComments' )->create(
        {   design_id    => $design->design_id,
            category_id  => $COMMENT_CATEGORY_ID,
            edited_user  => $ENV{USER},
            visibility   => 'public'
        }
    );    
    
    return $design->design_id;
}    
