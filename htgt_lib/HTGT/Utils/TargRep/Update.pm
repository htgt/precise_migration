package HTGT::Utils::TargRep::Update;

use Moose;
use namespace::autoclean;
use Const::Fast;
use Try::Tiny;
use List::MoreUtils qw( uniq any all );
use HTGT::Constants qw( %RANKED_QC_RESULTS %SPONSOR_FOR %CASSETTES );
use Data::Dumper::Concise;
use HTGT::Utils::MutagenesisPrediction::FloxedExons qw( get_floxed_exons );
use HTGT::Utils::TargRep::Update::Genbank qw( get_targeting_vector_and_allele_seq );
use List::Compare;
use Switch;

const my %VALIDATION_AND_METHODS => (
    allele => {
        fields => [
            qw(
                cassette_type
                mutation_type_name
                mutation_subtype_name
                mutation_method_name
                project_design_id
            )
        ],
        optional_fields => [
            qw(
                floxed_start_exon
                floxed_end_exon
            )
        ],
        update        => \&update_allele,
        update_method => 'update_allele',
        create_method => 'create_allele',
    },
    genbank_file => {
        fields => [
            qw(
                escell_clone
                targeting_vector
            )
        ],
        update        => \&update_genbank,
        update_method => 'update_genbank_file',
        create_method => 'create_genbank_file',
    },
    es_cell => {
        fields => [
            qw(
                targeting_vector_id
                ikmc_project_id
                parental_cell_line
                pipeline_id
                report_to_public

                production_qc_five_prime_screen
                production_qc_three_prime_screen
            )
        ],
        sanger_epd  => [
             qw(
                mgi_allele_symbol_superscript
                production_qc_loxp_screen
                production_qc_loss_of_allele
             )
        ],
        update        => \&update_es_cell,
        update_method => 'update_es_cell',
        create_method => 'create_es_cell',
    },
    distribution_qc => {
        fields => [
            qw(
                five_prime_sr_pcr
                three_prime_sr_pcr
                karyotype_low
                karyotype_high
                copy_number
                loa
                loxp
                lacz
                chr1
                chr8a
                chr8b
                chr11a
                chr11b
                chry
            )
        ],
        update        => \&update_distribution_qc,
        update_method => 'update_distribution_qc',
        create_method => 'create_distribution_qc',
    },
    targeting_vector => {
        fields => [
            qw(
                ikmc_project_id
                intermediate_vector
                pipeline_id
                report_to_public
            )
        ],
        update        => \&update_targeting_vector,
        update_method => 'update_targeting_vector',
        create_method => 'create_targeting_vector',
    },
);

has htgt_schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
);

with qw( MooseX::Log::Log4perl HTGT::Utils::TargRep::TargVecProject );

has targrep_schema => (
    is       => 'ro',
    isa      => 'Tarmits::Schema',
    required => 1,
);

has idcc_api => (
    is       => 'ro',
    isa      => 'HTGT::Utils::Tarmits',
    required => 1,
);

has eng_seq_config => (
    is     => 'ro',
    isa    => 'Path::Class::File',
    coerce => 1,
);

has genes => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    handles => { has_genes => 'count', }
);

has projects => (
    is      => 'ro',
    isa     => 'ArrayRef',
    traits  => ['Array'],
    handles => { has_projects => 'count', }
);

has commit => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

has hide_non_distribute => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

has optional_checks => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

has check_genbank_info => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

has pipeline_ids => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        pipeline_exists => 'exists',
        get_pipeline    => 'get',
    }
);

has name_for_assembly => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        assembly_exists => 'exists',
        get_assembly    => 'get',
    }
);

has epd_loa_qc_results => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        has_loa_qc => 'exists',
        get_loa_qc => 'get',
    }
);

has epd_taqman_loxp_qc_results => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        has_taqman_loxp_qc => 'exists',
        get_taqman_loxp_qc => 'get',
    }
);

has epd_distribution_qc_results => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
    traits     => ['Hash'],
    handles    => {
        has_distribution_qc => 'exists',
        get_distribution_qc => 'get',
    }
);

has targeting_vectors => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        seen_targeting_vector      => 'exists',
        targeting_vector_processed => 'set',
        get_targeting_vector_id    => 'get',
    }
);

has es_cells => (
    is      => 'ro',
    isa     => 'HashRef',
    traits  => ['Hash'],
    default => sub { {} },
    handles => {
        seen_es_cell      => 'exists',
        es_cell_processed => 'set',
    }
);

has stats => (
    is  => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);

sub htgt_to_targ_rep {
    my $self = shift;

    $self->process_projects( $self->get_projects );

    $self->process_projects( $self->get_mgp_only_projects );

    Log::Log4perl::NDC->remove();
    Log::Log4perl::NDC->push( 'Update Stats' );

    if ($self->hide_non_distribute) {
        $self->hide_non_distributable_products('TargRepTargetingVector');
        $self->hide_non_distributable_products('TargRepEsCell');
    }
    $self->log->info( Dumper($self->stats) );
}

sub process_projects {
    my ( $self, $projects_rs ) = @_;

    while ( my $project = $projects_rs->next ) {
        Log::Log4perl::NDC->remove();
        Log::Log4perl::NDC->push( $project->mgi_gene->marker_symbol  );
        Log::Log4perl::NDC->push( $project->project_id  );

        try {
            $self->update_project( $project );
        }
        catch {
            $self->log->error( 'Error processing project: ' . $_ );
        };
    }
}

sub hide_non_distributable_products {
    my ( $self, $type ) = @_;

    return if $self->has_genes || $self->has_projects;

    my @products = $self->targrep_schema->resultset($type)->search(
        {
            pipeline_id      => { IN => [ 1, 4, 6, 7, 8 ] },
            report_to_public => 1,
        },
        {
            columns => [ 'name', 'ikmc_project_id' ],
        }
    );

    my @targ_rep_product_names = map { $_->name } @products;
    my @htgt_product_names     = $type eq 'TargRepTargetingVector' ? keys %{ $self->targeting_vectors }
                               : $type eq 'TargRepEsCell'          ? keys %{ $self->es_cells }
                               :                              '';
    $self->log->error("Unknown product type: $type") unless @htgt_product_names;

    my $product_list_comp = List::Compare->new(\@targ_rep_product_names, \@htgt_product_names);
    my @non_dist_products = $product_list_comp->get_unique; #appear in the first list only

    $self->log->info('We have ' . scalar(@non_dist_products) . " $type to hide");

    $self->hide_targ_rep_product($type, \@non_dist_products);
}

sub hide_targ_rep_product {
    my ( $self, $type, $product_names ) = @_;

    for my $name ( @{ $product_names }) {
        my $object = $self->targrep_schema->resultset($type)->find({ name => $name });
        unless ($object) {
            $self->log->error("Cannot find $type $name in targ vec, unable to hide");
            next;
        }

        try {
            if ( $type eq 'TargRepEsCell') {
                $self->update_es_cell( $object, $name , { report_to_public => 0 } );
            }
            elsif ( $type eq 'TargRepTargetingVector') {
                $self->update_targeting_vector( $object, $name , { report_to_public => 0 } );
            }
        }
        catch {
            $self->log->error( "Error hiding $type $name" . $_ );
        };
    }
}

sub update_project {
    my ( $self, $project ) = @_;

    $self->log->info('.. started work on project: ');

    my @ws_entries   = $project->new_ws_entries;
    my $project_data = $self->project_data_for($project);

    my $cond_allele = $self->find_create_update_allele($project_data);
    $self->find_create_update_genbank( $project, $project_data, $cond_allele );
    my $non_conditional_allele;

    if ( any { $_->targeted_trap and $_->targeted_trap eq 'yes' } @ws_entries ) {
        $non_conditional_allele = $self->find_create_update_allele( $project_data, targeted_trap => 1 );
        $self->find_create_update_genbank( $project, $project_data, $non_conditional_allele, targeted_trap => 1 );
    }

    $self->check_and_update_allele_products( \@ws_entries, $project_data, $cond_allele,
        $non_conditional_allele );
}

sub check_and_update_allele_products {
    my ( $self, $ws_entries, $project_data, $cond_allele, $non_conditional_allele ) = @_;

    my %targ_vecs                = map { $_->name => $_ } $cond_allele->targ_rep_targeting_vectors if $cond_allele;
    my %conditional_es_cells     = map { $_->name => $_ } $cond_allele->targ_rep_es_cells if $cond_allele;
    my %non_conditional_es_cells = map { $_->name => $_ } $non_conditional_allele->targ_rep_es_cells
        if $non_conditional_allele;

    my @ws_data = map { $self->get_well_data($_) } @{$ws_entries};

    for my $targ_vec ( @{ $self->uniq_targ_vec( \@ws_data ) } ) {
        next if $self->seen_targeting_vector( $targ_vec->{targ_vec_name} );
        my $targ_vec_id = $self->find_create_update_targ_vec( $targ_vec, \%targ_vecs, $project_data,
            $cond_allele );
        $self->targeting_vector_processed( $targ_vec->{targ_vec_name} => $targ_vec_id );
    }

    for my $cond_es_cell ( @{ $self->uniq_dist_cond_es_cells( \@ws_data ) } ) {
        next if $self->seen_es_cell( $cond_es_cell->{es_cell_name} );
        $self->find_create_update_es_cell( $cond_es_cell, \%conditional_es_cells, $project_data,
            $cond_allele );
        $self->es_cell_processed( $cond_es_cell->{es_cell_name} => 1 );
    }

    for my $non_cond_es_cell ( @{ $self->uniq_dist_non_cond_es_cells( \@ws_data ) } ) {
        next if $self->seen_es_cell( $non_cond_es_cell->{es_cell_name} );
        $self->find_create_update_es_cell( $non_cond_es_cell, \%non_conditional_es_cells,
            $project_data, $non_conditional_allele );
        $self->es_cell_processed( $non_cond_es_cell->{es_cell_name} => 1 );
    }
}

sub uniq_targ_vec {
    my ( $self, $ws_data ) = @_;

    my @targ_vecs;
    for my $ws ( @{$ws_data} ) {
        if ( $ws->{targ_vec_distribute} and $ws->{targ_vec_distribute} eq 'yes' ) {
            push @targ_vecs, $ws;
        }
        elsif (( $ws->{es_cell_distribute} and $ws->{es_cell_distribute} eq 'yes' )
            or ( $ws->{targeted_trap} and $ws->{targeted_trap} eq 'yes' ) )
        {
            push @targ_vecs, $ws;
        }
    }

    return $self->uniq_ws_rows_by( 'targ_vec_name', \@targ_vecs );
}

sub uniq_dist_cond_es_cells {
    my ( $self, $ws_data ) = @_;

    my @dist_es_cells = grep {
        ( $_->{es_cell_distribute} and $_->{es_cell_distribute} eq 'yes' )
    } @{$ws_data};

    return $self->uniq_ws_rows_by( 'es_cell_name', \@dist_es_cells );
}

sub uniq_dist_non_cond_es_cells {
    my ( $self, $ws_data ) = @_;

    my @dist_es_cells = grep {
        ( $_->{targeted_trap} and $_->{targeted_trap} eq 'yes' )
    } @{$ws_data};

    return $self->uniq_ws_rows_by( 'es_cell_name', \@dist_es_cells );
}

sub uniq_ws_rows_by {
    my ( $self, $key_col, $ws_data ) = @_;

    my ( %seen, @uniq );
    for my $row ( @{$ws_data} ) {
        my $key_val = $row->{$key_col};
        next unless defined $key_val and not $seen{$key_val}++;
        push @uniq, $row;
    }

    return \@uniq;
}

#
#ALLELES
#
{
    const my @ALLELE_UNIQUE_FIELDS => qw(
        gene.mgi_accession_id
        assembly
        chromosome
        strand
        cassette
        backbone
        homology_arm_start
        homology_arm_end
        cassette_start
        cassette_end
        loxp_start
        loxp_end
        project_design_id
    );

    sub find_create_update_allele {
        my ( $self, $project_data, %args ) = @_;
        my $has_loxp_site = 1;
        my %allele_info = map { $_ => $project_data->{$_} } @ALLELE_UNIQUE_FIELDS;

        if ( $args{targeted_trap} || !$project_data->{design_type} =~ /^KO/ ) {
            $allele_info{loxp_start} = undef;
            $allele_info{loxp_end}   = undef;
            $has_loxp_site           = 0;
        }

        if ($args{targeted_trap}) {
            $project_data->{mutation_type_name} = 'Targeted Non Conditional';
            $project_data->{mutation_subtype_name} = undef unless $project_data->{mutation_subtype_name} eq 'Artificial Intron';
        }
        my @alleles = $self->targrep_schema->resultset('TargRepAllele')->search(
              \%allele_info
              ,
              { join => 'gene'
           }
        );
        unless ( scalar(@alleles) ) {
            $self->log->info('Found no matching allele');
            return $self->create_allele( $project_data, $has_loxp_site );
        }

        if ( scalar(@alleles) == 1 ) {
            my $allele = $alleles[0];
            $self->log->debug( 'Found allele: ' . $allele->id );
            $self->check_and_update_allele_info( $allele, $project_data, $has_loxp_site );
            return $allele;
        }
        else {
            die( 'Found ' . scalar(@alleles) . ' matching alleles' );
        }
    }
}

sub check_and_update_allele_info {
    my ( $self, $allele, $project_data, $has_loxp_site ) = @_;

    $self->get_floxed_exons_data( $project_data, $has_loxp_site ) if $self->optional_checks;

    $self->validate_object_data( $allele, $project_data, 'allele' );
}

sub update_allele {
    my ( $self, $allele, $object_name , $update_data ) = @_;

    $self->update( $allele, $object_name , $update_data, 'allele' );
}

{
    const my @ALLELE_CREATE_FIELDS => qw (
        chromosome
        cassette
        cassette_start
        cassette_end
        cassette_type
        backbone
        gene_id
        mutation_type_name
        mutation_subtype_name
        mutation_method_name
        strand
        homology_arm_start
        homology_arm_end
        assembly
        project_design_id
        floxed_start_exon
        floxed_end_exon
    );

    sub create_allele {
        my ( $self, $data, $has_loxp_site ) = @_;

        $self->get_floxed_exons_data( $data, $has_loxp_site );
        $data->{gene_id} = $self->targrep_schema->resultset('Gene')->search_rs( { mgi_accession_id => $data->{'gene.mgi_accession_id'} } )->first->id;
        unless ($data->{gene_id}){
            die( 'Unrecognised gene: ' . $data->{'gene.mgi_accession_id'} );
        }
        my %allele_data = map { $_ => $data->{$_} } @ALLELE_CREATE_FIELDS;

        if ($has_loxp_site) {
            $allele_data{loxp_start} = $data->{loxp_start};
            $allele_data{loxp_end}   = $data->{loxp_end};
        }

        my $new_allele = $self->create( \%allele_data, 'allele' );
        return unless $self->commit;

        #api returns a hash ref for a newly created allele, we need a Dbix class allele object
        return $self->targrep_schema->resultset('TargRepAllele')->find( { id => $new_allele->{id} } );
    }
}

sub get_floxed_exons_data {
    my ( $self, $project_data, $has_loxp_site  ) = @_;
    my $design_type = $project_data->{design_type};
    my ( $start, $end );

    if ( $design_type =~ /^KO/ ) {
        if ( $has_loxp_site ) {
            $start = $project_data->{cassette_end};
            $end   = $project_data->{loxp_start};
        }
        else { # targeted trap
            $start = $project_data->{cassette_start};
            $end   = $project_data->{homology_arm_end};
        }
    }
    elsif ( $design_type =~ /^Del/ or $design_type =~ /^Ins/ ) {
        $start = $project_data->{cassette_start};
        $end   = $project_data->{cassette_end};
    }

    my $floxed_exons = get_floxed_exons(
        $project_data->{ensembl_gene_id},
        $start,
        $end,
    );

    $project_data->{floxed_start_exon} = $floxed_exons->[0];
    $project_data->{floxed_end_exon}   = $floxed_exons->[-1];
}

#
#GENBANK FILES
#
sub find_create_update_genbank {
    my ( $self, $project, $project_data, $allele, %args ) = @_;
    my $genbank_data;

    return unless $allele;

    my @genbank_files
        = $self->targrep_schema->resultset('TargRepGenbankFile')->search( { allele_id => $allele->id, } );

    unless ( scalar(@genbank_files) ) {
        $self->log->info('Found no matching genbank files');

        $genbank_data = $self->get_htgt_genbank_files( $project, $project_data, $args{targeted_trap} );

        return $self->create_genbank( $project_data, $genbank_data, $allele->id );
    }

    if ( scalar(@genbank_files) == 1 ) {
        my $genbank = $genbank_files[0];
        $self->log->debug( 'Found genbank files: ' . $genbank->id );

        if ( $self->check_genbank_info ) {
            $genbank_data = $self->get_htgt_genbank_files( $project, $project_data, $args{targeted_trap} );
            $self->check_and_update_genbank( $genbank, $genbank_data );
        }
        return $genbank;
    }
    else {
        die( 'Found ' . scalar(@genbank_files) . ' matching genbank files for allele: ' . $allele->id );
    }
}

sub check_and_update_genbank{
    my ( $self, $genbank, $genbank_data ) = @_;

    $self->validate_object_data( $genbank, $genbank_data, 'genbank_file' );
}

sub update_genbank {
    my ( $self, $genbank, $object_name, $update_data ) = @_;

    $self->update( $genbank, $object_name , $update_data, 'genbank_file' );
}

sub create_genbank {
    my ( $self, $project_data, $genbank_data, $allele_id) = @_;
    $genbank_data->{allele_id} = $allele_id;
    return $self->create( $genbank_data, 'genbank_file' );
}

sub get_htgt_genbank_files {
    my ( $self, $project, $project_data, $targeted_trap ) = @_;

    my %genbank_config = (
        design_id        => $project_data->{project_design_id},
        cassette         => $project_data->{cassette},
        project          => $project,
        strand           => $project_data->{strand},
        chromosome_name  => $project_data->{chromosome},
        marker_symbol    => $project_data->{marker_symbol},
        mgi_accession_id => $project_data->{'gene.mgi_accession_id'},
        backbone         => $project_data->{backbone},
    );
    $genbank_config{eng_seq_config} = $self->eng_seq_config if $self->eng_seq_config;
    $genbank_config{targeted_trap} = 1 if $targeted_trap;


    return get_targeting_vector_and_allele_seq( %genbank_config );
}

#
#TARGETING VECTORS
#
sub find_create_update_targ_vec {
    my ( $self, $ws_data, $targ_vecs_for_allele, $project_data, $allele ) = @_;

    my $public_report = ($ws_data->{targ_vec_distribute} and $ws_data->{targ_vec_distribute} eq 'yes') ? 1 : 0;
    #deal with komp eucomm switch targ vecs pipeline id
    my $project     = $self->project_for_targ_vec($ws_data->{new_ws_row});
    my $pipeline_id = $self->_get_pipeline_id($project->sponsor);
    my %tv_data = (
        ikmc_project_id     => $project->project_id,
        name                => $ws_data->{targ_vec_name},
        allele_id           => $allele ? $allele->id : 'new_allele',
        intermediate_vector => $ws_data->{intermediate_vector},
        pipeline_id         => $pipeline_id,
        report_to_public    => $public_report,
    );

    my $targ_vec;
    if ( exists $targ_vecs_for_allele->{ $tv_data{name} } ) {
        $targ_vec = $targ_vecs_for_allele->{ $tv_data{name} };
        $self->log->debug( 'Found targeting vector: ' . $targ_vec->name );
    }
    else {
        $self->log->info( 'Not found targeting vector: ' . $tv_data{name} );
        $targ_vec = $self->targrep_schema->resultset('TargRepTargetingVector')->find( { name => $tv_data{name} } );
        if ($targ_vec) {
            $self->log->warn( $targ_vec->name
                    . " targeting vector assigned to wrong allele: "
                    . $targ_vec->allele_id . ' should be: ' .  $tv_data{allele_id});
            $self->update_targeting_vector( $targ_vec, 'allele_id', { allele_id => $tv_data{allele_id} } );
        }
        else {
            my $targ_vec = $self->create_targeting_vector( \%tv_data );
            return $self->commit ? $targ_vec->{id} : 0;
        }
    }
    $self->check_and_update_targeting_vector_info( $targ_vec, \%tv_data );
    return $targ_vec->id;
}

sub check_and_update_targeting_vector_info {
    my ( $self, $targ_vec, $tv_data ) = @_;

    $self->validate_object_data( $targ_vec, $tv_data, 'targeting_vector' );
}

sub update_targeting_vector {
    my ( $self, $targ_vec, $object_name , $update_data ) = @_;

    $self->update( $targ_vec, $object_name , $update_data, 'targeting_vector' );
}

sub create_targeting_vector {
    my ( $self, $tv_data ) = @_;

    return $self->create( $tv_data, 'targeting_vector' );
}

#
#ES CELLS
#

{
    const my @ES_CELL_CREATE_FIELDS => qw(
        ikmc_project_id
        name
        allele_id
        targeting_vector_id
        parental_cell_line
        pipeline_id
        report_to_public
        mgi_allele_symbol_superscript
        allele_symbol_superscript
        production_qc_five_prime_screen
        production_qc_three_prime_screen
        production_qc_loxp_screen
        production_qc_loss_of_allele
        production_qc_vector_integrity
    );

    sub find_create_update_es_cell {
        my ( $self, $ws_data, $es_cells_for_allele, $project_data, $allele ) = @_;

        $ws_data->{pipeline_id}                   = $project_data->{pipeline_id};
        $ws_data->{ikmc_project_id}               = $project_data->{project_id};
        $ws_data->{name}                          = $ws_data->{es_cell_name};
        $ws_data->{allele_id}                     = $allele ? $allele->id : 'new_allele';
        $ws_data->{report_to_public}              = 1;
        $ws_data->{mgi_allele_symbol_superscript} = $ws_data->{allele_symbol_superscript};

        if ( $self->seen_targeting_vector($ws_data->{targ_vec_name}) ) {
            $ws_data->{targeting_vector_id} = $self->get_targeting_vector_id($ws_data->{targ_vec_name} );
        }
        else {
            $self->log->error('Can not find targeting vector: ' . $ws_data->{targ_vec_name}
                              . ' associated with es cell: ' . $ws_data->{name});
        }

        my %es_cell_data = map { $_ => $ws_data->{$_} } @ES_CELL_CREATE_FIELDS;

        my $es_cell = undef;
        if ( exists $es_cells_for_allele->{ $es_cell_data{name} } ) {
            $es_cell = $es_cells_for_allele->{ $es_cell_data{name} };
            $self->log->debug( 'Found es cell: ' . $es_cell->name );
        }
        else {
            $self->log->info( "Not found es cell $es_cell_data{name} for allele: " . $ws_data->{allele_id} );

            $es_cell = $self->targrep_schema->resultset('TargRepEsCell')->find( { name => $es_cell_data{name} } );
            if ($es_cell) {
                $self->log->warn( $es_cell->name . " es cell assigned to wrong allele: "
                                  . $es_cell->allele_id . ' should be: ' . $ws_data->{allele_id} );
                $self->update_es_cell( $es_cell, 'allele_id', { allele_id => $ws_data->{allele_id} } );
            }
            else {
                $es_cell = $self->create_es_cell( \%es_cell_data );
                if ($self->commit){
                    $es_cell = $self->targrep_schema->resultset('TargRepEsCell')->find( { name => $es_cell_data{name} } );
                    $self->validate_es_cell_distribution_qc( $es_cell, $ws_data,) unless $es_cell_data{name} =~ /^DEPD/;
                    return $es_cell->{id};
                }
                else {
                    return 0;
                }
            }
        }

        if (!$es_cell->production_centre_auto_update) {
          $self->log->debug( '"production_cente_auto_update" is set to false. EsCell ' . $es_cell->name . ' has not been updated.' );
          # do NOT update es_cell if production_centre_auto_update is false.
          return 0;
        }
        $self->check_and_update_es_cell_info( $es_cell, \%es_cell_data, $ws_data,);
        return $es_cell->id;
    }
}

sub check_and_update_es_cell_info {
    my ( $self, $es_cell, $es_cell_data, $ws_data ) = @_;

    $self->validate_es_cell_production_qc ( $es_cell, $es_cell_data );
    $self->validate_es_cell_distribution_qc( $es_cell, $ws_data,) unless $es_cell_data->{name} =~ /^DEPD/;
    $self->validate_object_data( $es_cell, $es_cell_data, 'es_cell' );
}

sub validate_es_cell_production_qc {
    my ( $self, $es_cell, $es_cell_data) = @_;
    my $update_subroutine = $VALIDATION_AND_METHODS{'es_cell'}{update};

    my @check_fields;
    unless ( $es_cell_data->{name} =~ /^DEPD/ ) {
        push @check_fields, @{ $VALIDATION_AND_METHODS{es_cell}{sanger_epd} };
    }

    $self->check_and_update_fields( \@check_fields, $es_cell, 'es_cell', $es_cell_data->{name},
                         $es_cell_data, $update_subroutine );

}

sub update_es_cell {
    my ( $self, $es_cell, $object_name , $update_data ) = @_;

    $self->update( $es_cell, $object_name , $update_data, 'es_cell' );
}

sub create_es_cell {
    my ( $self, $es_cell_data ) = @_;

    return $self->create( $es_cell_data, 'es_cell' );
}
{
    const my @DISTRIBUTION_QC_CREATE_FIELDS => qw(
        karyotype_high
        karyotype_low
        copy_number
        three_prime_sr_pcr
        five_prime_sr_pcr
        loa
        loxp
        lacz
        chr1
        chr8a
        chr8b
        chr11a
        chr11b
        chry
    );

    sub validate_es_cell_distribution_qc {
        my ( $self, $es_cell, $ws_data ) = @_;

        return unless $es_cell;

        my %distribution_qc_data = map { $_ => $ws_data->{$_} } grep{ $ws_data->{$_} } @DISTRIBUTION_QC_CREATE_FIELDS;
        my $centre = $self->targrep_schema->resultset('TargRepEsCellDistributionCentre')->find({'name' => 'WTSI'})->id;
        my $update_subroutine = $VALIDATION_AND_METHODS{'distribution_qc'}{update};

        my @check_fields = @{ $VALIDATION_AND_METHODS{'distribution_qc'}{fields} };
        my $distribution_qc = $es_cell->targ_rep_distribution_qcs->find( { 'targ_rep_es_cell_distribution_centre.name' => 'WTSI' }, { join => 'targ_rep_es_cell_distribution_centre'} );

        if (defined $distribution_qc) {
            my %distribution_qc_update_data = map{ $_ => $distribution_qc_data{$_} } grep{ $distribution_qc_data{$_} } @check_fields;
            $distribution_qc_update_data{es_cell_distribution_centre_id}= $centre;
            $self->check_and_update_fields( \@check_fields, $distribution_qc, 'distribution_qc', $es_cell->name . '_distribution_qc',
                         \%distribution_qc_update_data, $update_subroutine );
        }
        else {
            return unless %distribution_qc_data;
            $distribution_qc_data{es_cell_distribution_centre_id}= $centre;
            $distribution_qc_data{es_cell_id} = $es_cell->id;
            $self->create_distribution_qc( \%distribution_qc_data );
        }


    }
}

sub create_distribution_qc {
    my ($self, $distribution_qc_data) = @_;
    return $self->create( $distribution_qc_data, 'distribution_qc' );
}

sub update_distribution_qc {
    my ( $self, $distribution_qc, $object_name , $update_data ) = @_;

    $self->update( $distribution_qc, $object_name , $update_data, 'distribution_qc' );
}


#
#COMMON FUNCTIONS FOR ALLELES / TARGETING VECTORS OR ES CELLS
#
sub validate_object_data {
    my ( $self, $object, $data, $object_type ) = @_;
    my $object_name       = $object->can('name') ? $object->name : $object->id;
    my @check_fields      = @{ $VALIDATION_AND_METHODS{$object_type}{fields} };
    my $update_subroutine = $VALIDATION_AND_METHODS{$object_type}{update};

    push @check_fields, @{ $VALIDATION_AND_METHODS{$object_type}{optional_fields} }
        if $self->optional_checks and exists $VALIDATION_AND_METHODS{$object_type}{optional_fields};

    $self->check_and_update_fields( \@check_fields, $object, $object_type, $object_name, $data, $update_subroutine );
}

sub check_and_update_fields {
    my ( $self, $check_fields, $object, $object_type, $object_name, $data, $update_subroutine ) = @_;


    my %update_data;
    for my $field ( @{$check_fields} ) {
        die("Cannot call $field method on $object_type object") unless $object->can($field);

        if ( !defined $data->{$field} ) {
            if ( $object->$field ) {
                $self->log->warn( "$object_type $object_name field $field has no value in HTGT"
                                  . ' but has following value in targ vec: ' . $object->$field );
                $update_data{$field} = undef;
            }
        }
        else {
            if ( !defined $object->$field ) {
                $self->log->info( "$object_type $object_name field $field not set: " . $data->{$field} );
                $update_data{$field} = $data->{$field};
            }
            elsif ( $object->$field ne $data->{$field} ) {
                if ($object_type eq 'genbank_file') {
                    $self->log->warn( "Incorrect $field for $object_type $object_name ");
                }
                else {
                    $self->log->warn( "Incorrect $field for $object_type $object_name : "
                                     . $object->$field . ', htgt value:' . $data->{$field} );
                }
                $update_data{$field} = $data->{$field};
            }
        }
    }
    $self->$update_subroutine( $object, $object_name , \%update_data ) if %update_data;
}

sub update {
    my ( $self, $object, $object_name , $update_data, $object_type ) = @_;
    $self->stats->{$object_type}{update}++;
    return unless $self->commit;

    my $update_method = $VALIDATION_AND_METHODS{$object_type}{update_method};

    try {
        $self->idcc_api->$update_method( $object->id, $update_data );
        $self->log->info( "Updating $object_type: $object_name " . Dumper($update_data) );
    }
    catch {
        $self->stats->{$object_type}{update}--;
        die ( "Unable to update $object_type: $object_name " . $_ );
    };

}

sub create {
    my ( $self, $object_data, $object_type ) = @_;

    $self->stats->{$object_type}{create}++;
    return unless $self->commit;

    my $object;
    my $object_name = $object_type eq 'es_cell'          ? $object_data->{name}
                    : $object_type eq 'targeting_vector' ? $object_data->{name}
                    : $object_type eq 'allele'           ? 'for project-' . $object_data->{project_design_id}
                    : $object_type eq 'genbank_file'     ? 'for allele-'  . $object_data->{allele_id}
                    :                                     '-';
    my $create_method = $VALIDATION_AND_METHODS{$object_type}{create_method};

    try {
        $object = $self->idcc_api->$create_method( $object_data );
        $self->log->info( "Created new $object_type $object_name: " . $object->{id} );
        $self->log->debug( 'Object info: ' . Dumper($object_data) );
    }
    catch {
        $self->stats->{$object_type}{create}--;
        die( "Unable to create $object_type: $object_name " . $_ );
    };

    return $object
}

#
#GRAB DATA FOR PROJECT AND ITS WELLS FROM HTGT
#
sub get_projects {
    my $self = shift;

    my $search_criteria = {
        -and => [
            -or => [
                is_eucomm           => 1,
                is_komp_csd         => 1,
                is_eucomm_tools     => 1,
            ],
            -or => [
                'new_ws_entries.epd_distribute'   => 'yes',
                'new_ws_entries.pgdgr_distribute' => 'yes',
                'new_ws_entries.targeted_trap'    => 'yes',
            ],
            is_publicly_reported => 1,
        ],
    };

    if ( $self->has_genes ) {
        push @{ $search_criteria->{-and} }, 'mgi_gene.marker_symbol' => { 'IN' => $self->genes };
    }
    elsif ( $self->has_projects ) {
        push @{ $search_criteria->{-and} }, 'me.project_id' => { 'IN' => $self->projects };
    }

    my $projects_rs = $self->htgt_schema->resultset('Project')->search_rs(
        $search_criteria,
        {
            join     => [ 'new_ws_entries' ],
            prefetch => [ 'mgi_gene', 'design', 'new_ws_entries' ],
            order_by => [ qw( mgi_gene.mgi_accession_id ) ],
        }
    );

    $self->log->debug("Fetched ".$projects_rs->count()." projects");
    return $projects_rs;
}

sub get_mgp_only_projects {
    my $self = shift;

    my $search_criteria = {
        -and => [
            -or => [
                'new_ws_entries.epd_distribute'   => 'yes',
                'new_ws_entries.pgdgr_distribute' => 'yes',
                'new_ws_entries.targeted_trap'    => 'yes',
            ],
            is_publicly_reported => 1,
            is_mgp => 1,
        ],
    };

    for my $sponsor_column ( grep { $_ ne 'is_mgp' } keys %SPONSOR_FOR ) {
        push @{ $search_criteria->{-and} }, '-or' => [ $sponsor_column => 0, $sponsor_column => undef ] ;
    }

    if ( $self->has_genes ) {
        push @{ $search_criteria->{-and} }, [ 'mgi_gene.marker_symbol' => { 'IN' => $self->genes } ];
    }
    elsif ( $self->has_projects ) {
        push @{ $search_criteria->{-and} }, [ 'me.project_id' => { 'IN' => $self->projects } ];
    }

    my $mgp_projects_rs = $self->htgt_schema->resultset('Project')->search_rs(
        $search_criteria,
        {
            join     => [ 'new_ws_entries' ],
            prefetch => [ 'mgi_gene', 'design', 'new_ws_entries' ],
            order_by => [ qw( mgi_gene.mgi_accession_id ) ],
        }
    );

    return $mgp_projects_rs;
}

{
    # key = name of data field in targ rep, value = name of that field in htgt
    const my %PROJECT_AND_DESIGN_DATA => (
        project => {
            'project_id' => 'project_id',
            'cassette'   => 'cassette',
            'backbone'   => 'backbone',
            'sponsor'    => 'sponsor',
        },
        design => {
            'project_design_id'     => 'design_id',
            'design_type'           => 'design_type',
            'mutation_subtype_name' => 'subtype',
        },
        mgi_gene => {
            'gene.mgi_accession_id' => 'mgi_accession_id',
            'ensembl_gene_id'  => 'ensembl_gene_id',
            'marker_symbol'    => 'marker_symbol',
        },
    );

    sub project_data_for {
        my ( $self, $project ) = @_;
        my %project_data;

        for my $table ( keys %PROJECT_AND_DESIGN_DATA ) {
            my $object;
            if ( $table eq 'project' ) {
                $object = $project;
            }
            else {
                $object = $project->$table;
            }

            for my $field ( keys %{ $PROJECT_AND_DESIGN_DATA{$table} } ) {
                my $method = $PROJECT_AND_DESIGN_DATA{$table}{$field};
                try {
                    $project_data{$field} = $object->$method;
                }
                catch {
                    die( "Error getting $table $method data: " . $_ );
                };
            }
        }

        $self->get_design_info( $project, \%project_data );
        $self->format_project_data( \%project_data );
        return \%project_data;
    }
}

{
    const my %WELL_DATA => (
        int_vec_plate                    => 'pcs_plate_name',
        int_vec_well                     => 'pcs_well_name',
        targ_vec_plate                   => 'pgdgr_plate_name',
        targ_vec_well                    => 'pgdgr_well_name',
        targ_vec_distribute              => 'pgdgr_distribute',
        targ_vec_well_id                 => 'pgdgr_well_id',
        parental_cell_line               => 'es_cell_line',
        es_cell_name                     => 'epd_well_name',
        es_cell_distribute               => 'epd_distribute',
        es_well_id                       => 'epd_well_id',
        targeted_trap                    => 'targeted_trap',
        allele_symbol_superscript        => 'allele_name',
        production_qc_five_prime_screen  => 'epd_five_arm_pass_level',
        production_qc_three_prime_screen => 'epd_three_arm_pass_level',
    );

    sub get_well_data {
        my ( $self, $ws ) = @_;
        my %ws_data;
        $ws_data{new_ws_row} = $ws;

        try {
            while ( my ( $field, $method ) = each %WELL_DATA ) {
                $ws_data{$field} = $ws->$method;
            }
            my $epd_dist = $ws->epd_distribute || $ws->targeted_trap ? 1 : 0;
            if ( $ws->epd_well_id ) {
                $self->get_distribution_qc_data( $ws, \%ws_data );
            }

            $self->format_well_data( \%ws_data, $epd_dist );
        }
        catch {
            $self->log->error('problem processing well data: ' . $_ );
            undef %ws_data;
        };

        return \%ws_data;
    }
}

{

    const my %DISTRIBUTION_QC_DATA => (
        loa    => 'loa_pass',
        loxp   => 'loxp_pass',
        lacz   => 'lacz_pass',
        chr1   => 'chr1_pass',
        chr8a  => 'chr8a_pass',
        chr8b  => 'chr8b_pass',
        chr11a => 'chr11a_pass',
        chr11b => 'chr11b_pass',
        chry   => 'chry_pass',
    );


    sub get_distribution_qc_data {
        my ( $self, $ws, $ws_data ) = @_;

        if ( $self->has_loa_qc( $ws->epd_well_id ) ) {
            $ws_data->{production_qc_loss_of_allele} = $self->get_loa_qc( $ws->epd_well_id );
        }

        $self->get_production_qc_loxp_result( $ws, $ws_data );

        if ( $self->has_distribution_qc( $ws->epd_well_id ) ) {
            my $dist_qc_results = $self->get_distribution_qc( $ws->epd_well_id );

            for my $qc_result_name ( keys %DISTRIBUTION_QC_DATA ) {
                my $result = $dist_qc_results->{ $DISTRIBUTION_QC_DATA{ $qc_result_name } };
                $ws_data->{ $qc_result_name } = $result;
            }
        }
    }
}

{

    const my %COMPUTED_LOXP_RESULTS => (
        'pass' => 'pass',
        'nd'   => 'no reads detected',
        'fail' => 'not confirmed',
    );

    const my %TAQMAN_LOXP_RESULTS => (
        'pass' => 'pass',
        'fa'   => 'not confirmed',
        'fail' => 'not confirmed',
        'na'   => 'na',
    );

    const my %LOXP_QC_RESULT_RANKING => (
        'na'                  => 1, #set to undef
        'pass'                => 2,
        'no reads detected' => 3,
        'not confirmed'     => 4,
    );

    sub get_production_qc_loxp_result {
        my ( $self, $ws, $ws_data ) = @_;
        my $loxp_result;

        my $computed_loxp_result
            = $ws->epd_loxp_pass_level
            ? $COMPUTED_LOXP_RESULTS{ lc( $ws->epd_loxp_pass_level ) }
            : undef;
        my $taqman_loxp_result
            = $self->has_taqman_loxp_qc( $ws->epd_well_id )
            ? $TAQMAN_LOXP_RESULTS{ lc( $self->get_taqman_loxp_qc( $ws->epd_well_id ) ) }
            : undef;

        if ( $computed_loxp_result && $taqman_loxp_result ) {
            if ( $LOXP_QC_RESULT_RANKING{ lc($computed_loxp_result) }
                < $LOXP_QC_RESULT_RANKING{ lc($taqman_loxp_result) } )
            {
                $loxp_result = $computed_loxp_result;
            }
            else {
                $loxp_result = $taqman_loxp_result;
            }
        }
        else {
            $loxp_result = $computed_loxp_result ? $computed_loxp_result
                         : $taqman_loxp_result   ? $taqman_loxp_result
                         :                         undef;
        }

        $ws_data->{production_qc_loxp_screen} = $loxp_result if $loxp_result && $loxp_result ne 'na';
    }
}

sub get_design_info {
    my ( $self, $project, $project_data ) = @_;

    $project_data->{design_type} = 'KO'
        unless $project_data->{design_type};

    my $display_features = $project->design->validated_display_features;

    $project_data->{assembly}   = $self->_get_assembly($display_features);
    $project_data->{strand}     = $self->_get_chr_strand($display_features);
    $project_data->{chromosome} = $self->_get_chr_name($display_features);

    $self->_get_loxp_coords( $display_features, $project_data );
    $self->_get_cassette_coords( $display_features, $project_data );
    $self->_get_homology_arm_coords( $display_features, $project_data );

}

#grab assembly from relationship
sub _get_assembly {
    my ( $self, $display_features ) = @_;

    my @assemblies = uniq map $_->assembly_id, values %{$display_features};
    die('features have inconsistent assembly ids')
        unless @assemblies == 1;

    if ( $self->assembly_exists( $assemblies[0] ) ) {
        return $self->get_assembly( $assemblies[0] );
    }
    else {
        die( 'Unrecognies assembly id: ' . $assemblies[0] );
    }
}

sub _get_loxp_coords {
    my ( $self, $display_features, $project_data ) = @_;

    if (    $project_data->{design_type} =~ /KO/
        and $display_features->{D5}
        and $display_features->{D3} )
    {
        if ( $project_data->{strand} == 1 ) {
            $project_data->{loxp_start} = $display_features->{D5}->feature_end;
            $project_data->{loxp_end}   = $display_features->{D3}->feature_start;
        }
        else {
            $project_data->{loxp_start} = $display_features->{D5}->feature_start;
            $project_data->{loxp_end}   = $display_features->{D3}->feature_end;
        }
    }
}

sub _get_cassette_coords {
    my ( $self, $display_features, $project_data ) = @_;

    if (    ( $project_data->{design_type} =~ /^Del/ || $project_data->{design_type} =~ /^Ins/ )
        and $display_features->{U5}
        and $display_features->{D3} )
    {
        if ( $project_data->{strand} == 1 ) {
            $project_data->{cassette_start} = $display_features->{U5}->feature_end;
            $project_data->{cassette_end}   = $display_features->{D3}->feature_start;
        }
        else {
            $project_data->{cassette_start} = $display_features->{U5}->feature_start;
            $project_data->{cassette_end}   = $display_features->{D3}->feature_end;
        }
    }
    elsif ( $project_data->{design_type} =~ /KO/
        and $display_features->{U5}
        and $display_features->{U3} )
    {
        if ( $project_data->{strand} == 1 ) {
            $project_data->{cassette_start} = $display_features->{U5}->feature_end;
            $project_data->{cassette_end}   = $display_features->{U3}->feature_start;
        }
        else {
            $project_data->{cassette_start} = $display_features->{U5}->feature_start;
            $project_data->{cassette_end}   = $display_features->{U3}->feature_end;
        }
    }
}

sub _get_homology_arm_coords {
    my ( $self, $display_features, $project_data ) = @_;

    if ( $display_features->{G5} and $display_features->{G3} ) {
        if ( $project_data->{strand} == 1 ) {
            $project_data->{homology_arm_start} = $display_features->{G5}->feature_end;
            $project_data->{homology_arm_end}   = $display_features->{G3}->feature_start;
        }
        else {
            $project_data->{homology_arm_start} = $display_features->{G5}->feature_start;
            $project_data->{homology_arm_end}   = $display_features->{G3}->feature_end;
        }
    }
}

sub _get_chr_strand {
    my ( $self, $display_features ) = @_;

    my @strands = uniq map $_->feature_strand, values %{$display_features};
    die('features have inconsistent strand')
        unless @strands == 1;

    return shift @strands;
}

sub _get_chr_name {
    my ( $self, $display_features ) = @_;

    my @chr_names = uniq map $_->chromosome->name, values %{$display_features};
    die('features have inconsistent chromosome id')
        unless @chr_names == 1;

    return shift @chr_names;
}

#
#FORMAT HTGT DATA INTO TARG REP COMPLIANT VALUES
#
sub format_project_data {
    my ( $self, $project_data ) = @_;

    $self->_format_design_type($project_data);
    $self->_format_design_subtype($project_data);
    $project_data->{mutation_method_name} = 'Targeted Mutation';
    $self->_format_strand($project_data);
    $project_data->{pipeline_id}   = $self->_get_pipeline_id( $project_data->{sponsor} );
    $project_data->{cassette_type} = $self->_get_cassette_type( $project_data->{cassette} );

}

    sub _format_design_type {
        my ( $self, $project_data ) = @_;

        if (exists $CASSETTES{$project_data->{cassette}} && $CASSETTES{$project_data->{cassette}}{cre_knock_in}){
            $project_data->{mutation_type_name} = 'Cre Knock In';
            return;
        }
        elsif ($project_data->{design_type} =~ /^KO/) {

            $project_data->{mutation_type_name} = 'Conditional Ready';
            return;
        }
        elsif ($project_data->{design_type} =~ /^Del/) {
            $project_data->{mutation_type_name} = 'Deletion';
            return;
        }
        elsif ($project_data->{design_type} =~ /^Ins/) {
            $project_data->{mutation_type_name} = 'Insertion';
            return;
        }
        die( 'Unrecognised design type: ' . $project_data->{design_type} );
    }



    sub _format_design_subtype {
        my ( $self, $project_data ) = @_;

        if ($project_data->{design_type} =~ /^KO/ && $project_data->{mutation_type_name} ne 'Cre Knock In'){

            if (exists $CASSETTES{$project_data->{cassette}} && $CASSETTES{$project_data->{cassette}}{artificial_intron}){
                $project_data->{mutation_subtype_name} = 'Artificial Intron';
                return;
            }
            elsif (!defined $project_data->{mutation_subtype_name}){
                $project_data->{mutation_subtype_name} = 'Frameshift';
                return;
            }
            elsif ($project_data->{mutation_subtype_name} =~ /^domain$/) {
                $project_data->{mutation_subtype_name} = 'Domain Disruption';
                return;
            }
            else {
                $project_data->{mutation_subtype_name} = 'Frameshift';
                return;
            }
        }
        $project_data->{mutation_subtype_name} = undef;
    }



{
    my %STRAND_FORMATTING = (
        '+' => qr/^1$/,
        '-' => qr/^-1$/,
    );

    sub _format_strand {
        my ( $self, $project_data ) = @_;

        return
            if !$project_data->{strand}
                || $project_data->{strand} eq '+'
                || $project_data->{strand} eq '-';

        for my $strand ( keys %STRAND_FORMATTING ) {
            if ( $project_data->{strand} =~ $STRAND_FORMATTING{$strand} ) {
                $project_data->{strand} = $strand;
                return;
            }
        }
        die( 'Unrecognised strand: ' . $project_data->{strand} );
    }
}

{
    const my %SPONSORS => (
        'KOMP'               => 'KOMP-CSD',
        'EUCOMM'             => 'EUCOMM',
        'EUCOMM-Tools'     => 'EUCOMMTools',
        'EUCOMM-Tools-Cre' => 'EUCOMMToolsCre',
        'REGENERON'          => 'KOMP-Regeneron',
        'NORCOMM'            => 'NorCOMM',
        'MGP'                => 'Sanger MGP',
    );

    sub _get_pipeline_id {
        my ( $self, $sponsor ) = @_;

        if ( $sponsor ) {
            $sponsor =~ s/:MGP$//;
        }
        else {
            $sponsor = 'MGP';
        }

        if ( exists $SPONSORS{$sponsor} ) {
            my $targ_rep_sponsor = $SPONSORS{$sponsor};
            if ( $self->pipeline_exists($targ_rep_sponsor) ) {
                return $self->get_pipeline($targ_rep_sponsor);
            }
            else {
                die( 'Unrecognised sponsor in Targ Rep data: ' . $targ_rep_sponsor );
            }
        }
        else {
            die( 'Unrecognised sponsor in HTGT data: ' . $sponsor );
        }
    }
}

{
    const my %CASSETTE_TYPES => (
        'ZEN-UB1.GB'                                   => 'Promotor Driven',
        'L1L2_st0'                                     => 'Promotorless',
        'L1L2_NTARU-1'                                 => 'Promotorless',
        'L1L2_Pgk_P'                                   => 'Promotor Driven',
        'TM-ZEN-UB1'                                   => 'Promotor Driven',
        'L1L2_NTARU-0'                                 => 'Promotorless',
        'ZEN-Ub1'                                      => 'Promotor Driven',
        'L1L2_Bact_P'                                  => 'Promotor Driven',
        'L1L2_6XOspnEnh_Bact_P'                        => 'Promotor Driven',
        'L1L2_gt1'                                     => 'Promotorless',
        'L1L2_st1'                                     => 'Promotorless',
        'L1L2_Del_BactPneo_FFL'                        => 'Promotor Driven',
        'L1L2_gtk'                                     => 'Promotorless',
        'L1L2_NTARU-2'                                 => 'Promotorless',
        'L1L2_NTARU-K'                                 => 'Promotorless',
        'L1L2_gt2'                                     => 'Promotorless',
        'L1L2_gt0'                                     => 'Promotorless',
        'L1L2_st2'                                     => 'Promotorless',
        'PGK_EM7_PuDtk_bGHpA'                          => 'Promotor Driven',
        'pL1L2_PAT_B0'                                 => 'Promotor Driven',
        'pL1L2_PAT_B1'                                 => 'Promotor Driven',
        'pL1L2_PAT_B2'                                 => 'Promotor Driven',
        'L1L2_hubi_P'                                  => 'Promotor Driven',
        'L1L2_GOHANU'                                  => 'Promotor Driven',
        'L1L2_Pgk_PM'                                  => 'Promotor Driven',
        'pL1L2_GT0_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT1_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT2_bsd_frt15_neo_barcode'              => 'Promotor Driven',
        'pL1L2_GT0_DelLacZ_bsd'                        => 'Promotorless',
        'pL1L2_GT1_DelLacZ_bsd'                        => 'Promotorless',
        'pL1L2_GT2_DelLacZ_bsd'                        => 'Promotorless',
        'Ifitm2_intron_L1L2_GTK_LacZ_BetactP_neo'      => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT0_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT1_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_GT2_LF2A_LacZ_BetactP_neo' => 'Promotor Driven',
        'Ifitm2_intron_L1L2_Bact_P'                    => 'Promotor Driven',
        'pL1L2_GT0_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT1_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT2_T2A_H2BCherry_Puro_delRsrll_NO_DTA' => 'Promotor Driven',
        'pL1L2_GT0_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT1_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT2_LF2A_H2BCherry_Puro'                => 'Promotor Driven',
        'pL1L2_GT0_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT1_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_GT2_T2A_iCre_KI_Puro'                   => 'Promotor Driven',
        'pL1L2_frt_BetactP_neo_frt_lox'                => 'Promotor Driven',
        'pL1L2_frt15_BetactinBSD_frt14_neo_Rox'        => 'Promotor Driven',
        'L1L2_GT0_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_GT1_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_GT2_LF2A_LacZ_BetactP_neo'               => 'Promotor Driven',
        'L1L2_gt0_Del_LacZ'                            => 'Promotorless',
        'L1L2_gt1_Del_LacZ'                            => 'Promotorless',
        'L1L2_gt2_Del_LacZ'                            => 'Promotorless',
        'V5_Flag_biotin'                               => 'Promotorless',
        'pL1L2_GT0_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT1_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GT2_LF2A_nEGFPO_T2A_CreERT_puro'        => 'Promotorless',
        'pL1L2_GTK_nEGFPO_T2A_CreERT_puro'             => 'Promotorless',
    );

    sub _get_cassette_type {
        my ( $self, $cassette ) = @_;

        die('No cassette set for project') unless $cassette;

        if ( exists $CASSETTE_TYPES{$cassette} ) {
            return $CASSETTE_TYPES{$cassette};
        }
        else {
            die( 'Unknown cassette type: ' . $cassette );
        }
    }
}

sub format_well_data {
    my ( $self, $well_summary_data, $epd_dist ) = @_;

    $self->_format_allele_symbol_superscript($well_summary_data);
    $self->_format_well_names($well_summary_data);

    if ($epd_dist) {
        $self->_format_parental_cell_line($well_summary_data);
        $self->_format_qc_results($well_summary_data);
    }
}

sub _format_allele_symbol_superscript {
    my ( $self, $ws_data ) = @_;
    return unless my $allele_symbol_superscript = $ws_data->{allele_symbol_superscript};

    $allele_symbol_superscript =~ /<sup>(.*)<\/sup>/;
    $ws_data->{allele_symbol_superscript} = $1;
}

sub _format_parental_cell_line {
    my ( $self, $ws_data ) = @_;
    my $line = $ws_data->{parental_cell_line};
    die( $ws_data->{es_cell_name} . ' has no parental cell line set') unless $line;
    my $corrected_line = '';

    if    ( $line =~ /^JM8\.?A(\d+)\.?(\D)(\d+)\.?(\D)(\d+)/i )     { $corrected_line = "JM8A$1.$2$3.$4$5" }
    elsif ( $line =~ /^JM8\.?A(\d+)\.?(\D)(\d+)/i )                 { $corrected_line = "JM8A$1.$2$3" }
    elsif ( $line =~ /^JM8\.?A\.(\D)(\d+)/i )                       { $corrected_line = "JM8A.$1$2" }
    elsif ( $line =~ /^JM8\.?A(\d+)/i )                             { $corrected_line = "JM8A$1" }
    elsif ( $line =~ /^JM8\.?(\D)(\d+)\.?(\D)(\d+)\.?(\D)(\d+)/i )  { $corrected_line = "JM8.$1$2.$3$4.$4$5" }
    elsif ( $line =~ /^JM8\.?(\D)(\d+)\.?(\D)(\d+)/i )              { $corrected_line = "JM8.$1$2.$3$4" }
    elsif ( $line =~ /^JM8\.?(\D)(\d+)/i )                          { $corrected_line = "JM8.$1$2" }
    else {
        switch ($line) {
            case qr/^AB/i    { $corrected_line = $line }
            case qr/^C2/i    { $corrected_line = 'C2' }
            case qr/^SI/i    { $corrected_line = $line }
            case qr/^JM8$/i  { $corrected_line = 'JM8 parental' }
            case qr/JM8\s+/i { $corrected_line = 'JM8 parental' }
            else {
                die( $ws_data->{es_cell_name} . ' unknown cell line: ' . $ws_data->{parental_cell_line} );
            }
        };
    }
    $ws_data->{parental_cell_line} = $corrected_line;
}

sub _format_well_names {
    my ( $self, $ws_data ) = @_;

    if ( $ws_data->{targ_vec_plate} && $ws_data->{targ_vec_well} ) {
        $ws_data->{targ_vec_name}
            = $ws_data->{targ_vec_plate} . '_' . substr( $ws_data->{targ_vec_well}, -3 );
    }

    if ( $ws_data->{int_vec_plate} && $ws_data->{int_vec_well} ) {
        $ws_data->{intermediate_vector}
            = $ws_data->{int_vec_plate} . '_' . substr( $ws_data->{int_vec_well}, -3 );
    }
}

{

    const my %VALID_TARG_REP_QC_RESULTS => (
        production_qc_five_prime_screen => {
            pass                => qr/^pass$/i,
            'no reads detected' => qr/^nd$/i,
            'not attempted'     => qr/^na$/i,
            'not confirmed'     => qr/^fail$/i,
        },
        production_qc_three_prime_screen => {
            pass                => qr/^pass$/i,
            'no reads detected' => qr/^nd$/i,
            'not confirmed'     => qr/^fail$/i,
        },
        production_qc_loxp_screen => {
            pass                => qr/^pass$/i,
            'no reads detected' => qr/^(no reads detected$|nd)$/i,
            'not confirmed'     => qr/^(not confirmed$|fail)$/i,
            not_done            => qr/^not\sdone$/i,
        },
        production_qc_loss_of_allele => {
            pass     => qr/^pass$/i,
            fail     => qr/^(fail|FA)$/i,
            not_done => qr/^not\sdone$/i,
        },
        production_qc_vector_integrity => {
            pass        => qr/^pass$/i,
            fail        => qr/^fail/i,
            not_done    => qr/^not\sdone$/i,
            in_progress => qr/^in\sprogress/i,
        },
        copy_number => {
            pass        => qr/pass/i,
            fail        => qr/fail/i,
            not_done    => qr/^not\sdone$/i,
            in_progress => qr/^in\sprogress/i,
        },
        five_prime_sr_pcr => {
            pass        => qr/pass/i,
            fail        => qr/fail/i,
            not_done    => qr/^not\sdone$/i,
            in_progress => qr/^in\sprogress/i,
        },
        three_prime_sr_pcr => {
            pass        => qr/^pass/i,
            fail        => qr/^fail/i,
            not_done    => qr/^not\sdone$/i,
            in_progress => qr/^in\sprogress/i,
        },
        loa => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        loxp => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        lacz => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chr1 => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chr8a => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chr8b => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chr11a => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chr11b => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
        chry => {
            pass           => qr/^pass/i,
            fail           => qr/^fa/i,
            not_applicable => qr/^na$/i,
        },
    );

    sub _format_qc_results {
        my ( $self, $ws_data ) = @_;

        FIELD: for my $field ( keys %VALID_TARG_REP_QC_RESULTS ) {
            next if !exists $ws_data->{$field} or !$ws_data->{$field};

            scalar keys %{ $VALID_TARG_REP_QC_RESULTS{$field} }; #reset hash iterator
            while ( my ($value, $regex) = each %{ $VALID_TARG_REP_QC_RESULTS{$field} }  ) {
                if ( $ws_data->{$field} =~ $regex ) {
                    if ($value eq 'not_done' || $value eq 'in_progress' || $value eq 'not_applicable') {
                        $ws_data->{$field} = undef;
                    }
                    else {
                        $ws_data->{$field} = $value;
                    }
                    next FIELD;
                }
            }

            $self->log->error("Unable to format $field qc result: "
                              . $ws_data->{$field} . ', setting value set to undef' );
            $ws_data->{$field} = undef;
        }
        $self->format_floating_numbers($ws_data);
    }
}

sub format_floating_numbers {
    my ( $self, $ws_data ) = @_;

    for ( qw( distribution_qc_karyotype_high distribution_qc_karyotype_low ) ) {
        if ( exists $ws_data->{$_} and $ws_data->{$_}) {
            $ws_data->{$_} = $ws_data->{$_} * 1;
        }
    }
}

#./bin/update_targ_rep.pl
#GRAB RELEVENT DATA UPFRONT AND STORE IN MEMORY
#
{
    const my $REPD_LOA_QC => <<'EOT';
    SELECT
        epd_well.well_id as EPD_WELL_ID,
        loa_well_data.data_value  AS QC_RESULT
    FROM
        well epd_well
    INNER JOIN plate epd_plate
        on epd_plate.plate_id = epd_well.plate_id
    INNER JOIN well repd_child_well
        ON repd_child_well.parent_well_id = epd_well.well_id
    INNER JOIN plate repd_plate
        ON repd_plate.plate_id = repd_child_well.plate_id
    INNER JOIN well_data loa_well_data
        ON repd_child_well.well_id = loa_well_data.well_id AND loa_well_data.data_type = 'loa_qc_result'
    WHERE
        epd_plate.type = 'EPD'
        AND
        repd_plate.type = 'REPD'
EOT

    const my $REPD_TAQMAN_LOXP_QC => <<'EOT';
    SELECT
        epd_well.well_id as EPD_WELL_ID,
        taqman_loxp_well_data.data_value  AS QC_RESULT
    FROM
        well epd_well
    INNER JOIN plate epd_plate
        on epd_plate.plate_id = epd_well.plate_id
    INNER JOIN well repd_child_well
        ON repd_child_well.parent_well_id = epd_well.well_id
    INNER JOIN plate repd_plate
        ON repd_plate.plate_id = repd_child_well.plate_id
    INNER JOIN well_data taqman_loxp_well_data
        ON repd_child_well.well_id = taqman_loxp_well_data.well_id AND taqman_loxp_well_data.data_type = 'taqman_loxp_qc_result'
    WHERE
        epd_plate.type = 'EPD'
        AND
        repd_plate.type = 'REPD'
EOT

    sub _build_epd_loa_qc_results {
        my $self = shift;

        return $self->build_qc_result_hash( $REPD_LOA_QC );
    }

    sub _build_epd_taqman_loxp_qc_results {
        my $self = shift;

        return $self->build_qc_result_hash( $REPD_TAQMAN_LOXP_QC );
    }

    sub build_qc_result_hash {
        my ( $self, $sql ) = @_;
        my %qc_results;

        my $qc_sth = $self->htgt_schema->storage->dbh()->prepare($sql);
        $qc_sth->execute();

        my %qc;
        while ( my $r = $qc_sth->fetchrow_hashref() ) {
            push @{ $qc{ $r->{epd_well_id} } }, $r->{qc_result}
                if $r->{qc_result};
        }

        while ( my ( $epd_well, $qc_results ) = each %qc ) {
            my @sorted_qc_results
                = sort { $RANKED_QC_RESULTS{lc($a)} <=> $RANKED_QC_RESULTS{lc($b)} } @{$qc_results};
            $qc_results{$epd_well} = $sorted_qc_results[0];
        }

        return \%qc_results;
    }
}

{
    const my $PIQ_QC_RESULTS => <<'EOT';
    SELECT
        piq_well.well_id as PIQ_WELL_ID,
        grandparent_well.well_id as GRANDPARENT_WELL_ID,
        piq_well_data.data_type as DATA_TYPE,
        piq_well_data.data_value as DATA_VALUE,
        grandparent_plate.type as GRANDPARENT_PLATE_TYPE
    FROM
        well piq_well
    INNER JOIN plate piq_plate
        on piq_plate.plate_id = piq_well.plate_id and piq_plate.type = 'PIQ'
    INNER JOIN well parent_well
        on parent_well.well_id = piq_well.parent_well_id
    INNER JOIN well grandparent_well
        on grandparent_well.well_id = parent_well.parent_well_id
    INNER JOIN plate grandparent_plate
        on grandparent_well.plate_id = grandparent_plate.plate_id
    INNER JOIN well_data piq_well_data
        on piq_well.well_id = piq_well_data.well_id
    WHERE
        piq_well_data.data_type IN (
            'chr11a_pass',
            'chr11b_pass',
            'chr1_pass',
            'chr8a_pass',
            'chr8b_pass',
            'chry_pass',
            'lacz_pass',
            'loa_pass',
            'loxp_pass'
        )
    ORDER BY
        piq_well.well_id
EOT

    sub _build_epd_distribution_qc_results {
        my $self = shift;
        my %qc_results;

        my $piq_qc_sth = $self->htgt_schema->storage->dbh()->prepare($PIQ_QC_RESULTS);
        $piq_qc_sth->execute();

        my %non_epd_grandparents;
        while ( my $r = $piq_qc_sth->fetchrow_hashref() ) {
            if ( $r->{grandparent_plate_type} ne 'EPD' ) {
                $non_epd_grandparents{ $r->{piq_well_id} }{ $r->{data_type} } = $r->{ data_value };
                next;
            }

            my $epd_well_id = $r->{grandparent_well_id};
            if ( exists $qc_results{ $epd_well_id }{ $r->{data_type} } ) {
                $self->log->error( 'EPD well' . $epd_well_id . ' already has qc result '
                                   . $r->{data_type} . ' =  '
                                   . $qc_results{ $epd_well_id }{ $r->{data_type} }
                                   . ' this should not happen ' );
                next;
            }

            $qc_results{ $epd_well_id }{ $r->{data_type} } = $r->{data_value};
        }

        $self->get_non_epd_grandparent_qc_results( \%non_epd_grandparents, \%qc_results );

        return \%qc_results;
    }

    # get epd distribution qc data for piq wells which do not have a epd grandparent well
    sub get_non_epd_grandparent_qc_results {
        my ( $self, $piq_wells, $epd_distribution_qc_results ) = @_;

        for my $piq_well_id ( keys %{ $piq_wells } ) {
            my $piq_well = $self->htgt_schema->resultset('Well')->find( { well_id => $piq_well_id } );
            unless ( $piq_well ) {
                $self->log->error( "Unable to find PIQ well $piq_well_id" );
                next;
            }
            my ($epd_well, $epd_plate) = $piq_well->ancestor_well_plate_of_type('EPD');
            unless ( $epd_well ) {
                $self->log->error( "Unable to find EPD ancestor well for PIQ well $piq_well_id" );
                next;
            }
            $epd_distribution_qc_results->{ $epd_well->well_id } = $piq_wells->{ $piq_well_id };
        }
    }
}


{
    const my $ASSEMBLY_SQL => <<'EOT';
    SELECT DISTINCT
        id,
        name
    FROM
        mig.gnm_assembly
EOT

    sub _build_name_for_assembly {
        my $self = shift;
        my %assembly_names;

        my $assembly_sth = $self->htgt_schema->storage->dbh()->prepare($ASSEMBLY_SQL);
        $assembly_sth->execute();

        while ( my $r = $assembly_sth->fetchrow_hashref() ) {
            $assembly_names{ $r->{id} } = $r->{name}
                if $r->{name};
        }
        return \%assembly_names;
    }
}

{
    const my $PIPELINE_SQL => <<'EOT';
    SELECT DISTINCT
        id,
        name
    FROM
        targ_rep_pipelines
EOT

    sub _build_pipeline_ids {
        my $self = shift;
        my %pipelines;

        my $pipeline_sth = $self->targrep_schema->storage->dbh()->prepare($PIPELINE_SQL);
        $pipeline_sth->execute();

        while ( my $r = $pipeline_sth->fetchrow_hashref() ) {
            $pipelines{ $r->{name} } = $r->{id}
                if $r->{name};
        }
        return \%pipelines;
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

