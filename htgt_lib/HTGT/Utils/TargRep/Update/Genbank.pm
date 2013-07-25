package HTGT::Utils::TargRep::Update::Genbank;

use strict;
use warnings FATAL => 'all';
use Sub::Exporter -setup => {
    exports => [
        'get_targeting_vector_and_allele_seq', 'get_mirko_seq',
        'get_regeneron_seq',                   'get_norcomm_seq'
    ]
};
use MooseX::Params::Validate;
use EngSeqBuilder::Compat;
use Bio::SeqIO;
use HTGT::Utils::DesignFinder::Gene;
use Try::Tiny;
use Log::Log4perl ':easy';
use IO::String;

{
    my $eng_seq_builder;

    sub set_eng_seq_builder {
        $eng_seq_builder = shift;
    }

    sub get_eng_seq_builder {
        my $eng_seq_params = shift;
        if ( %{ $eng_seq_params } ) {
            set_eng_seq_builder( EngSeqBuilder::Compat->new( %{ $eng_seq_params } ) );
        }
        else {
            set_eng_seq_builder( EngSeqBuilder::Compat->new() );
        }

        return $eng_seq_builder;
    }
}

sub get_targeting_vector_and_allele_seq {
    my %params = validated_hash(
        \@_,
        eng_seq_config   => { isa => 'Path::Class::File', optional => 1 },
        project          => { isa => 'HTGTDB::Project' },
        cassette         => { isa => 'Str' },
        backbone         => { isa => 'Str' },
        design_id        => { isa => 'Int' },
        strand           => { isa => 'Str' },
        chromosome_name  => { isa => 'Str' },
        marker_symbol    => { isa => 'Str' },
        mgi_accession_id => { isa => 'Str' },
        targeted_trap    => { isa => 'Bool', default => 0 },
    );

    my $design        = $params{project}->design;
    my $design_type   = $design->info->type;
    my $mutation_type = _get_mutation_type( $design_type, $params{targeted_trap} );
    my $project_ids   = _get_design_projects( $design, \%params );
    my $design_params
        = get_design_params( \%params, $mutation_type, $project_ids, $design, $design_type );

    my %targ_vec_params = %{ $design_params };
    $targ_vec_params{backbone}    = $params{backbone};
    $targ_vec_params{description} = _create_seq_description(
            $mutation_type, $project_ids, $params{marker_symbol}, $params{backbone} );

    my %allele_params =%{ $design_params };
    $allele_params{targeted_trap} = $params{targeted_trap};
    $allele_params{description}   = _create_seq_description(
            $mutation_type, $project_ids, $params{marker_symbol} );

    if ( $params{targeted_trap} and $design_type =~ /^KO/ ) {
        $allele_params{loxp_start} = $design->info->loxp_start;
        $allele_params{loxp_end}   = $design->info->loxp_end;
    }

    my %eng_seq_params;
    $eng_seq_params{configfile} = $params{eng_seq_config} if $params{eng_seq_config};
    my $eng_seq = get_eng_seq_builder( \%eng_seq_params );

    return _create_sequences( \%targ_vec_params, \%allele_params, $eng_seq );
}

sub get_mirko_seq {
    my %params = validated_hash(
        \@_,
        allele         => { isa => 'Tarmits::Schema::Result::TargRepAllele' },
        eng_seq_config => { isa => 'Path::Class::File', optional => 1 },
        gene_id        => { isa => 'Str' },
        cassette       => { isa => 'Str' },
        backbone       => { isa => 'Str' },
    );

    my %eng_seq_params;
    $eng_seq_params{configfile} = $params{eng_seq_config} if $params{eng_seq_config};
    $eng_seq_params{append_seq_length} = 10000;
    my $eng_seq = get_eng_seq_builder( \%eng_seq_params );

    my %genbank_params = (
        chromosome      => $params{allele}->chromosome,
        cassette        => $params{cassette},
        strand          => $params{allele}->strand eq '+' ? 1 : -1,
        design_type     => 'Del_Block',
        five_arm_start  => $params{allele}->homology_arm_start,
        five_arm_end    => $params{allele}->cassette_start,
        three_arm_start => $params{allele}->cassette_end,
        three_arm_end   => $params{allele}->homology_arm_end,
    );

    my %targ_vec_params = %genbank_params;
    $targ_vec_params{backbone}   = $params{backbone},
    $targ_vec_params{display_id} = $params{gene_id} . '(TV-Puro)#' . $params{allele}->project_design_id;

    my %allele_params = %genbank_params;
    $allele_params{display_id} = $params{gene_id} . '(Puro-Allele)#' . $params{allele}->project_design_id;

    return _create_sequences( \%targ_vec_params, \%allele_params, $eng_seq );
}

sub get_norcomm_seq {
    my %params = validated_hash(
        \@_,
        allele         => { isa => 'Tarmits::Schema::Result::TargRepAllele' },
        eng_seq_config => { isa => 'Path::Class::File', optional => 1 },
        gene_id        => { isa => 'Str' },
        cassette       => { isa => 'Str' },
        backbone       => { isa => 'Str' },
    );

    my %eng_seq_params;
    $eng_seq_params{configfile} = $params{eng_seq_config} if $params{eng_seq_config};
    $eng_seq_params{append_seq_length} = 10000;
    my $eng_seq = get_eng_seq_builder( \%eng_seq_params );

    my %genbank_params = (
        chromosome      => $params{allele}->chromosome,
        cassette        => $params{cassette},
        strand          => $params{allele}->strand eq '+' ? 1 : -1,
        design_type     => 'Del_Block',
        five_arm_start  => $params{allele}->homology_arm_start,
        five_arm_end    => $params{allele}->cassette_start,
        three_arm_start => $params{allele}->cassette_end,
        three_arm_end   => $params{allele}->homology_arm_end,
    );

    my %targ_vec_params = %genbank_params;
    $targ_vec_params{backbone}   = $params{backbone},
    $targ_vec_params{display_id} = 'vector_' . $params{gene_id}
                                 . '_' . $params{cassette} . '_' . $params{backbone};

    my %allele_params = %genbank_params;
    $allele_params{display_id} = 'allele' . '_' . $params{gene_id}
                               . '_' . $params{cassette};

    return _create_sequences( \%targ_vec_params, \%allele_params, $eng_seq );
}

sub get_regeneron_seq {
    my %params = validated_hash(
        \@_,
        allele         => { isa => 'Tarmits::Schema::Result::TargRepAllele' },
        eng_seq_config => { isa => 'Path::Class::File', optional => 1 },
        gene_id        => { isa => 'Str' },
        cassette       => { isa => 'Str' },
    );

    my %eng_seq_params;
    $eng_seq_params{configfile} = $params{eng_seq_config} if $params{eng_seq_config};
    $eng_seq_params{append_seq_length} = 10000;
    my $eng_seq = get_eng_seq_builder( \%eng_seq_params );

    my %genbank_params = (
        chromosome      => $params{allele}->chromosome,
        cassette        => $params{cassette},
        strand          => $params{allele}->strand eq '+' ? 1 : -1,
        design_type     => 'Del_Block',
        five_arm_start  => $params{allele}->homology_arm_start,
        five_arm_end    => $params{allele}->cassette_start,
        three_arm_start => $params{allele}->cassette_end,
        three_arm_end   => $params{allele}->homology_arm_end,
        display_id      => $params{gene_id} . '#' . $params{allele}->id,
    );

    my $allele_seq = $eng_seq->allele_seq( %genbank_params );
    return _stringify_bioseq($allele_seq);
}

sub _create_sequences {
    my ( $targ_vec_params, $allele_params , $eng_seq ) = @_;

    my $final_vector_seq = $eng_seq->vector_seq( %{$targ_vec_params} );
    my $allele_seq       = $eng_seq->allele_seq( %{$allele_params} );

    my %genbank_files;
    $genbank_files{targeting_vector} = _stringify_bioseq($final_vector_seq);
    $genbank_files{escell_clone}     = _stringify_bioseq($allele_seq);

    return \%genbank_files;
}

sub get_design_params {
    my ( $params, $mutation_type, $project_ids, $design, $design_type ) = @_;

    my %params = (
        chromosome  => $params->{chromosome_name},
        cassette    => $params->{cassette},
        strand      => $params->{strand} eq '+' ? 1 : -1,
        design_type => $design_type,
        design_id   => $params->{design_id},
        map { $_ => $design->info->$_ }
            qw( five_arm_start five_arm_end three_arm_start three_arm_end ),
    );

    $params{display_id} = _create_display_id( $mutation_type, $project_ids, $params->{mgi_accession_id} );
    my $transcript_id   = _get_transcript_id( $design );
    $params{transcript} = $transcript_id if $transcript_id;

    return \%params if $design_type =~ /^Del/ || $design_type =~ /^Ins/;
    map{ $params{$_} = $design->info->$_ } qw( target_region_start target_region_end );

    return \%params;
}

sub _get_mutation_type {
    my ( $design_type, $targeted_trap ) = @_;
    my $mutation_type;

    $mutation_type
        = $design_type =~ /^Del/                   ? 'deletion'
        : $design_type =~ /^Ins/                   ? 'insertion'
        : $design_type =~ /^KO/ && $targeted_trap  ? 'non-conditional'
        : $design_type =~ /^KO/ && !$targeted_trap ? 'KO-first, conditional ready'
        :                                             undef;

    unless ($mutation_type) {
        die 'Mutation type could not be set for design_type: ' . $design_type;
    }

    return $mutation_type;
}

sub _create_display_id {
    my ( $mutation_type, $project_ids, $mgi_accession_id ) = @_;

    my $formated_mutation_type = $mutation_type =~ 'KO-first' ? 'KO-first_condition_ready' : $mutation_type;
    return  $formated_mutation_type . '_' . $project_ids . '_' . $mgi_accession_id;
}

sub _create_seq_description {
    my ( $mutation_type, $project_ids, $marker_symbol, $backbone ) = @_;

    my $seq_description = 'Mus musculus targeted ';
    $seq_description .= $mutation_type . ', lacZ-tagged mutant ';
    $seq_description .= $backbone ? 'vector ' : 'allele ';
    $seq_description .= $marker_symbol;
    $seq_description .= ' targeting project(s): ' . $project_ids;

    return $seq_description;
}

sub _get_design_projects {
    my ( $design, $params ) = @_;
    my @projects;

    if ( $params->{backbone} ){
        @projects = $design->projects->search(
            { cassette => $params->{cassette}, backbone => $params->{backbone} },
            { columns  => [qw/project_id/] } );
    }
    else {
        @projects = $design->projects->search(
            { cassette => $params->{cassette} },
            { columns => [qw/project_id/] } );
    }

    my @project_ids = map { $_->project_id } @projects;

    unless ( scalar(@project_ids) ) {
        my $msg = 'No project found for design: ' . $design->design_id
                . ' with cassette: ' . $params->{cassette};
        $msg .= ' and backbone: ' . $params->{backbone} if $params->{backbone};
        die $msg;
    }

    return join ':', @project_ids;
}

sub _get_transcript_id {
    my $design = shift;
    my $ensembl_gene_id = $design->info->mgi_gene->ensembl_gene_id;
    unless ( $ensembl_gene_id ) {
        WARN('No ensembl gene id, unable to find transcript');
        return;
    }

    my $gene = HTGT::Utils::DesignFinder::Gene->new( ensembl_gene_id => $ensembl_gene_id );

    my $transcript;
    try {
        $transcript = $gene->template_transcript;
    }
    catch {
        die $_ unless $_ =~ m/Failed to find a template transcript/;
        $transcript = ( $gene->all_transcripts )[0];
    };
    unless ($transcript) {
        WARN('Unable to find gene transcript');
        return;
    }
    return $transcript->stable_id;
}

sub _stringify_bioseq {
    my $seq = shift;
    my $str = '';
    my $io  = Bio::SeqIO->new(
        -fh     => IO::String->new($str),
        -format => 'genbank',
    );
    $io->write_seq($seq);
    return $str;
}
1;
