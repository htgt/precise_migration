#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use DateTime;
use HTGT::DBFactory;
use Pod::Usage;

my $gene_build = '65.37n:mus_musculus_core_65_37n';

my $prefix     = join '.', $ENV{USER}, DateTime->now->ymd, $$;
my $commit     = undef;

GetOptions(
    'help'         => sub { pod2usage( -verbose => 1 ) },
    'man'          => sub { pod2usage( -verbose => 2 ) },
    'gene-build=s' => \$gene_build,
    'prefix=s'     => \$prefix,
    'commit'       => \$commit,
);

my $schema = HTGT::DBFactory->connect('eucomm_vector');

$schema->txn_do(
    sub {
        load_designs();
        unless ( $commit ) {
            warn "ROLLBACK\n";
            $schema->txn_rollback();
        }
    }
);

sub load_designs {
    my $count;
    while (<>) {
        chomp;
        my $line = $_;
        $count++;

        my ($ens_gene,    $start_exon_name, $end_exon_name, $target_chr, $target_start, $target_end,  $five_block,
            $five_offset, $five_flank,      $three_block,   $three_offset, $three_flank, $dan_score
        ) = split /\s+/, $line;

        print
            "$ens_gene, $start_exon_name, $end_exon_name, $target_chr, $target_start, $target_end, $five_block, $five_offset, $five_flank, $three_block, $three_offset, $three_flank\n";

        # ENSMUSG00000037896 ENSMUSE00000529367 ENSMUSE00000529355 12 112331292 112339919 120 60 300 120 60 100 (200)

        my $gene_build_gene                 = $ens_gene;
        my $min_3p_exon_flanks              = $three_flank;
        my $min_5p_exon_flanks              = $five_flank;
        my $multi_region_5p_offset_shim     = $five_offset;
        my $multi_region_3p_offset_shim     = $three_offset;
        my $split_5p_target_sequence_length = $five_block;
        my $split_3p_target_sequence_length = $three_block;
        my $primer_length                   = 50;

        #Blocks for me.
        my $retrieval_primer_length_3p = 1000;
        my $retrieval_primer_offset_3p = 4500;
        my $retrieval_primer_offset_5p = 6500;
        my $retrieval_primer_length_5p = 1000;

        #Blocks for Molly.
        #my $retrieval_primer_length_3p = 1000;
        #my $retrieval_primer_offset_3p = 7500;
        #my $retrieval_primer_length_5p = 1000;
        #my $retrieval_primer_offset_5p = 3000;

        my $score = join ':', $prefix, $dan_score;        
        my $split_5p_target_seq_length = $five_block;
        my $split_3p_target_seq_length = $three_block;

        my ( $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id, $chr_name, $chr_strand )
            = get_gene_build_and_exon_ids( $gene_build, $ens_gene, $start_exon_name, $end_exon_name )
                or do {
                    warn "ERROR: gene_build_and_exon_ids failed: $gene_build, $ens_gene, $start_exon_name, $end_exon_name\n";
                    next;
                };
        
        print "$gene_build_id, $start_exon_id, $end_exon_id,  $assembly_id, $chr_name, $chr_strand\n";

        # create design_parameter
        my $design_parameter = create_design_parameter(
            $min_3p_exon_flanks,          $min_5p_exon_flanks,         $multi_region_5p_offset_shim,
            $multi_region_3p_offset_shim, $primer_length,              $retrieval_primer_length_3p,
            $retrieval_primer_length_5p,  $retrieval_primer_offset_3p, $retrieval_primer_offset_5p,
            $score,                       $split_5p_target_seq_length, $split_3p_target_seq_length
        );

        my $design = create_design(
            $gene_build_id, $start_exon_id, $end_exon_id, $assembly_id,      $chr_name,
            $target_start,  $target_end,    $chr_strand,  $design_parameter, $ENV{USER}
        );

        print "Inserted design " . $design->design_id . "\n";

    }
    
    print "Inserted $count designs\n";
}

sub get_gene_build_and_exon_ids {
    my ( $gene_build_string, $primary_name, $start_exon_name, $end_exon_name ) = @_;
    my ( $gene_build, $gene ) = get_gene_build_and_gene( $gene_build_string, $primary_name );

    my %exon_hash;
    if ( $gene_build && $gene ) {
        my @transcripts = $gene->transcripts;
        foreach my $transcript (@transcripts) {
            my @exons = $transcript->exons;
            foreach my $exon (@exons) {
                if ( not exists $exon_hash{ $exon->primary_name } ) {
                    $exon_hash{ $exon->primary_name } = $exon;
                }
                elsif ( $exon_hash{ $exon->primary_name }->id > $exon->id ) {
                    $exon_hash{ $exon->primary_name } = $exon;
                }
            }
        }

        unless ( exists $exon_hash{ $end_exon_name } ) {
            warn "$end_exon_name not found\n";
            return;
        }

        unless ( exists $exon_hash{$start_exon_name} ) {
            warn "$start_exon_name not found\n";
            return;
        }

        my $chr_strand = $exon_hash{$end_exon_name}->locus->chr_strand;

        # This is the default position.
        my $start_exon_id = $exon_hash{$start_exon_name}->id;
        my $end_exon_id   = $exon_hash{$end_exon_name}->id;

        # The start exon must be always nearest the U casette. Make sure of this
        # by flipping them around if necessary.
        if ( $chr_strand == 1 ) {
            if ( $exon_hash{$start_exon_name}->locus->chr_start > $exon_hash{$end_exon_name}->locus->chr_start ) {
                $start_exon_id = $exon_hash{$end_exon_name}->id;
                $end_exon_id   = $exon_hash{$start_exon_name}->id;
            }
        }
        else {
            if ( $exon_hash{$start_exon_name}->locus->chr_start < $exon_hash{$end_exon_name}->locus->chr_start ) {
                $start_exon_id = $exon_hash{$end_exon_name}->id;
                $end_exon_id   = $exon_hash{$start_exon_name}->id;
            }
        }

        return (
            $gene_build->id, $start_exon_id, $end_exon_id, $gene_build->assembly_id,
            $exon_hash{$start_exon_name}->locus->chr_name,
            $exon_hash{$end_exon_name}->locus->chr_strand
        );
    }
    else {
        return;
    }
}

sub get_gene_build_and_gene {
    my ( $gene_build_string, $primary_name ) = @_;

    $gene_build_string =~ /\s*(\S*)\s*:\s*(\S*)\s*/;
    my $version     = $1;
    my $gbname      = $2;

    my @gene_builds = $schema->resultset('HTGTDB::GnmGeneBuild')->search( { version => $version } );
    my $gene_build;
    if ( scalar(@gene_builds) == 1 ) {
        $gene_build = $gene_builds[0];
    }
    else {
        warn 'found ' . @gene_builds . ' matching GnmGeneBuild version' . "\n";
        return;
    }

    my @genes = $schema->resultset('HTGTDB::GnmGeneBuildGene')->search(
        {   build_id     => $gene_build->id,
            primary_name => $primary_name
        }
    );

    my $gene;
    if ( scalar(@genes) == 1 ) {
        $gene = $genes[0];
    }
    else {
        warn 'found ' . @genes . ' matching genes' . "\n";
        return;
    }

    return ( $gene_build, $gene );
}

sub create_design_parameter {
    my ($min_3p_exon_flanks,          $min_5p_exon_flanks,         $multi_region_5p_offset_shim,
        $multi_region_3p_offset_shim, $primer_length,              $retrieval_primer_length_3p,
        $retrieval_primer_length_5p,  $retrieval_primer_offset_3p, $retrieval_primer_offset_5p,
        $score,                       $split_5p_target_seq_length, $split_3p_target_seq_length
    ) = @_;

    my $parameter_string
        = qq[min_3p_exon_flanks=$min_3p_exon_flanks,min_5p_exon_flanks=$min_5p_exon_flanks,multi_region_5p_offset_shim=$multi_region_5p_offset_shim,multi_region_3p_offset_shim=$multi_region_3p_offset_shim,primer_length=$primer_length,retrieval_primer_length_3p=$retrieval_primer_length_3p,retrieval_primer_length_5p=$retrieval_primer_length_5p,retrieval_primer_offset_3p=$retrieval_primer_offset_3p,retrieval_primer_offset_5p=$retrieval_primer_offset_5p,split_5p_target_seq_length=$split_5p_target_seq_length,split_3p_target_seq_length=$split_3p_target_seq_length,score=$score
    ];

    my $design_parameter = $schema->resultset('HTGTDB::DesignParameter')
        ->create( { parameter_name => 'custom knockout', parameter_value => $parameter_string } );

    return $design_parameter;
}

sub create_design {
    my ($gene_build_id, $start_exon_id, $end_exon_id, $assembly_id,      $chr_name,
        $target_start,  $target_end,    $chr_strand,  $design_parameter, $created_user
    ) = @_;

    my $locus = create_locus( $assembly_id, $chr_name, $target_start, $target_end, $chr_strand );

    my $locus_id = $locus->id;

    my $design = $schema->resultset('HTGTDB::Design')->create(
        {   start_exon_id       => $start_exon_id,
            end_exon_id         => $end_exon_id,
            gene_build_id       => $gene_build_id,
            locus_id            => $locus_id,
            design_parameter_id => $design_parameter->id,
            created_user        => $created_user,

            #Added by Dan to include the type and sub type.
            design_type => 'KO'    #On the site this is presented as two distinct fields.
        }
    );

    my $design_status_dict = $schema->resultset('HTGTDB::DesignStatusDict')->search( { description => 'Created' } )->first;

    if ( !$design_status_dict ) {
        print STDERR ("Something is wrong - I cant locate a design_status_dict entry for 'Created'\n");
        return;
    }

    my $design_status = $schema->resultset('HTGTDB::DesignStatus')->create(
        {   design_id        => $design->design_id,
            design_status_id => $design_status_dict->design_status_id,
            is_current       => 1
        }
    );

    if ( !$design_status ) {
        print STDERR ("Something is wrong - I cant create a design_status\n");
        return;
    }

    my $design_note_type = $schema->resultset('HTGTDB::DesignNoteTypeDict')->search( { description => 'Info' } )->first;
    if ( !$design_note_type ) {
        print STDERR ("Cant get a design-note-type of 'Info'\n");
        return;
    }

    my $design_note = $schema->resultset('HTGTDB::DesignNote')->create(
        {   design_note_type_id => $design_note_type->design_note_type_id,
            design_id           => $design->design_id,
            note                => 'Created'
        }
    );

    return $design;
}

sub create_locus {
    my ( $assembly_id, $chr_name, $target_start, $target_end, $chr_strand ) = @_;

    my $locus = $schema->resultset('HTGTDB::GnmLocus')->create(
        {   chr_name    => $chr_name,
            chr_start   => $target_start,
            chr_end     => $target_end,
            chr_strand  => $chr_strand,
            assembly_id => $assembly_id,
            type        => 'DESIGN'
        }
    );

    return $locus;
}

sub trim($) {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

__END__

=pod

=head1 NAME

insert-designs.pl

=head1 SYNOPSIS

  insert-designs.pl [OPTIONS] DESIGN_PARAMETER_FILE

  Options:

    --commit                      Commit changes to the database (default rollback)
    --prefix=PREFIX               Prefix stamped into parameter string (default USER.YYYY-MM-DD.PID)
    --gene-build=GENE_BUILD_NAME  Gene build (default 52.37e:1510Ensembl)

=head1 DESCRIPTION

Read design parameters output by create-design and insert designs in HTGT.

=head1 AUTHOR

Dan Klose

=cut
