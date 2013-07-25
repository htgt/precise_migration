package HTGT::Utils::FetchHTGTEngSeqParams;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ qw( fetch_htgt_eng_seq_params fetch_htgt_genbank_eng_seq_params) ],
    groups => {
        default => [ qw( fetch_htgt_eng_seq_params fetch_htgt_genbank_eng_seq_params) ]
    }
};

use HTGT::QC::Exception;
use Data::Dump qw( pp );
use Const::Fast;
use YAML::Any;
use Log::Log4perl qw( :easy );
use Try::Tiny;
use HTGT::DBFactory;

use Data::Dumper;
$Data::Dumper::Maxdepth = 3;

const my %DEFAULT_CASSETTE_FOR_STAGE => (
    intermediate => 'pR6K_R1R2_ZP'
);

const my %DEFAULT_BACKBONE_FOR_STAGE => (
    intermediate => 'R3R4_pBR_amp'
);

const my %ASSEMBLY_FOR_ID => (
    11  => 'NCBIM37',
    100 => 'GRCh37',
    101 => 'GRCm38',
);

sub fetch_htgt_eng_seq_params {
    my ( $plate, $stage, $recombinase ) = @_;

    my @params;

    for my $well ( $plate->wells ) {
        next unless defined $well->design_instance_id;
        push @params, get_eng_seq_params_for_well( $well, $stage, $recombinase );
    }

    return \@params;
}

sub fetch_htgt_genbank_eng_seq_params{
    my ($input_params) = @_;

    # Decide which method to use for design type
    my $param_getter;
    if ($input_params->{type} eq 'vector'){
		$param_getter = \&get_eng_seq_params_for_vector;
	}
	elsif ($input_params->{type} eq 'allele'){
		$param_getter = \&get_eng_seq_params_for_allele;
		# Clear backbone value as it will not be used
		$input_params->{backbone} = undef;
	}
	else{
		# This should never happen
		die ("Error: no get_seq method available for ".$input_params->{type});
	}
	
	# Find the design ID in database
	my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );
	my $design_id = $input_params->{design_id};
	my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
            || die "Failed to retrieve design $design_id\n";
            
    $input_params->{design} = $design;
    
    my $generated_params;
    
    # Get params from design
    my $design_params = get_genbank_design_params( $input_params );
    
    # Add backbone if provided
    if (my $backbone = $input_params->{backbone}){
        $design_params->{backbone} = { name => $backbone };	
    }    
    $generated_params->{eng_seq_params} = $design_params;

    my $targeted_trap = $input_params->{targeted_trap} ? 1 : 0;
    $generated_params->{targeted_trap} = $targeted_trap;
    
    my $cassette = { name => $input_params->{cassette} };
    
    # Add the design type specific params
    $param_getter->( $generated_params, $cassette);
    
    return $generated_params;
}

sub get_eng_seq_params_for_well {
    my ( $well, $stage, $recombinase ) = @_;

    my ($params, $cassette);

    if ( $stage eq 'allele' ) {
    	($params, $cassette) = get_well_params($well, 'final', $recombinase, 1);
        get_eng_seq_params_for_allele( $params, $cassette );
    }
    elsif ( $stage eq 'intermediate' or $stage eq 'final' ) {
    	($params, $cassette) = get_well_params($well, $stage, $recombinase);
        get_eng_seq_params_for_vector( $params, $cassette );
    }
    else {
        HTGT::QC::Exception->throw( "Unrecognized vector_stage: " . $stage );
    }    

    TRACE( sub { "Engineered sequence parameters for $well: " . pp $params } );

    $params->{well_name} = uc $well->plate->name . '_' . substr( $well->well_name, -3 );
    
    $params->{eng_seq_id} = $params->{eng_seq_params}{display_id};
    return $params;
}

sub get_well_params{
	
    my ( $well, $stage, $recombinase, $allele ) = @_;
    
    my $params;
    my $eng_seq_params;
    my $design = $well->design_instance->design;
    
    try{
        $eng_seq_params = get_design_params( $design );
        $eng_seq_params->{assembly} = get_design_assembly( $design )
    }
    catch{
        HTGT::QC::Exception->throw( 'Error getting design params for design ' . $design->design_id . " error:  $_" );
    };

    my $cassette = get_cassette( $well, $stage )
        or HTGT::QC::Exception->throw( "$well has no cassette" );

    $eng_seq_params->{recombinase} = $recombinase || get_recombinase_params( $well );    

    my $seq_id;  
    if ($allele){
        $seq_id = sprintf( '%s#%s', $eng_seq_params->{design_id}, $cassette->{name} );	
    }
    else{
        my $backbone = get_backbone( $well, $stage )
            or HTGT::QC::Exception->throw( "$well has no backbone" );

        $eng_seq_params->{backbone}    = $backbone;
        $seq_id = join '#', $eng_seq_params->{design_id}, $cassette->{name}, $backbone->{name},
            @{ $eng_seq_params->{recombinase} };
    }
    
    $seq_id =~ s/\s+/_/g;
    $eng_seq_params->{display_id} = $seq_id;
    
    $params->{eng_seq_params} = $eng_seq_params;
    
    return ($params, $cassette);    
}

sub get_eng_seq_params_for_vector {
    
    my ( $params, $cassette ) = @_;
    
    my $eng_seq_params = $params->{eng_seq_params};
    my $design_type = delete $eng_seq_params->{design_type};
    
    if ( $design_type =~ /^KO/) {
        $params->{eng_seq_method}      = 'conditional_vector_seq';
        $eng_seq_params->{u_insertion} = $cassette;
        $eng_seq_params->{d_insertion} = { name => 'LoxP' };
    }
    elsif ( $design_type =~ /^Ins/ ) {
        $params->{eng_seq_method}    = 'insertion_vector_seq';
        $eng_seq_params->{insertion} = $cassette;
    }
    elsif ( $design_type =~ /^Del/ ) {
        $params->{eng_seq_method}    = 'deletion_vector_seq';        
        $eng_seq_params->{insertion} = $cassette;
    }
    else {
        HTGT::QC::Exception->throw( "Don't know how to generate vector seq for design of type $design_type" );
    }

    $params->{eng_seq_params} = $eng_seq_params;
    return $params;
}

sub get_eng_seq_params_for_allele {
	
    my ( $params, $cassette ) = @_;

    my $eng_seq_params = $params->{eng_seq_params};
    my $design_type = delete $eng_seq_params->{design_type};

    if ($params->{targeted_trap}) {
        $eng_seq_params->{u_insertion} = $cassette;
        delete $eng_seq_params->{loxp_start};
        delete $eng_seq_params->{loxp_end};
        $params->{eng_seq_method} = 'targeted_trap_allele_seq';
    }
    elsif ( $design_type =~ /^KO/) {
        $params->{eng_seq_method}      = 'conditional_allele_seq';
        $eng_seq_params->{u_insertion} = $cassette;
        $eng_seq_params->{d_insertion} = { name => 'LoxP' };
    }
    elsif ( $design_type =~ /^Ins/ ) {
        $params->{eng_seq_method}    = 'insertion_allele_seq';
        $eng_seq_params->{insertion} = $cassette;
    }
    elsif ( $design_type =~ /^Del/ ) {
        $params->{eng_seq_method}    = 'deletion_allele_seq';        
        $eng_seq_params->{insertion} = $cassette;
    }
    else {
        HTGT::QC::Exception->throw( "Don't know how to generate allele seq for design of type $design_type" );
    }

    $params->{eng_seq_params} = $eng_seq_params;
    return $params;
}

sub get_recombinase_params {
    my ( $well ) = @_;

    my @recombinase;

    my %well_data = map { $_->data_type => $_->data_value } $well->plate->plate_data, $well->well_data;
    
    if ( $well_data{apply_flp} ) {
        push @recombinase, 'flp';
    }
    if ( $well_data{apply_cre} ) {
        push @recombinase, 'cre';
    }
    if ( $well_data{apply_dre} ) {
        push @recombinase, 'dre';
    }

    return \@recombinase;    
}

sub get_cassette {
    my ( $well, $stage ) = @_;

    my $name = $well->well_data_value( 'cassette' );
    if ( defined $name ) {
        return {
            name => $name,
        };
    }
    elsif ( defined $well->parent_well_id ) {
        return get_cassette( $well->parent_well, $stage );
    }
    elsif ( exists $DEFAULT_CASSETTE_FOR_STAGE{$stage} ) {
        return {
            name => $DEFAULT_CASSETTE_FOR_STAGE{$stage},
        };
    }
    else {
        return;
    }    
}

sub get_backbone {
    my ( $well, $stage ) = @_;

    my $name = $well->well_data_value( 'backbone' );
    if ( defined $name ) {
        return {
            name => $name,
        };
    }
    elsif ( defined $well->parent_well_id ) {
        return get_backbone( $well->parent_well, $stage );
    }
    elsif ( exists $DEFAULT_BACKBONE_FOR_STAGE{$stage} ) {
        return {
            name => $DEFAULT_BACKBONE_FOR_STAGE{$stage},
        };
    }
    else {
        return;
    }
}

sub get_design_params {
    my ( $design ) = @_;

    my $di = $design->info;
    
    my %params = (
        design_id       => $design->design_id,
        chromosome      => $di->chr_name,
        strand          => $di->chr_strand,
        design_type     => $di->type,
        five_arm_start  => $di->five_arm_start,
        five_arm_end    => $di->five_arm_end,
        three_arm_start => $di->three_arm_start,
        three_arm_end   => $di->three_arm_end,
    );

    #if its a deletion or insertion then we dont want the target_region information.
    if ( $di->target_region_start && $di->type !~ /^Del/ && $di->type !~ /^Ins/ ) {
        $params{target_region_start} = $di->target_region_start;
        $params{target_region_end}   = $di->target_region_end;
    }

    TRACE( sub { "Design parameters: " . pp \%params  } );
    
    return \%params;
}

sub get_genbank_design_params{
	my ( $args ) = @_;
	
	my $design_info = $args->{design}->info;
	
	my $params = get_design_params( $args->{design} );

    my $mutation_type = _get_mutation_type( $design_info->type, $args->{targeted_trap} );
    my $mgi_gene = $design_info->mgi_gene;
    my $project_ids = get_design_projects( $args );

    $params->{display_id} = _create_display_id( $mutation_type, $project_ids, $mgi_gene->mgi_accession_id );
    $params->{description} = _create_seq_description( $mutation_type, $project_ids, $mgi_gene->marker_symbol, $args->{backbone} );

    return $params if $design_info->type =~ /^Del/ || $design_info->type =~ /^Ins/;
    
    map { $params->{$_} = $design_info->$_ } qw( target_region_start target_region_end );
    map { $params->{$_} = $design_info->$_ } qw( loxp_start loxp_end ) if $args->{targeted_trap};

    return $params;	
}

sub _get_mutation_type {
    my ( $design_type, $targeted_trap ) = @_;
    my $mutation_type;

    $mutation_type
        = $design_type =~ /^Del/                   ? 'deletion'
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
    $seq_description .= $mutation_type . ', lacZ-tagged mutant';
    $seq_description .= $backbone ? 'vector' : 'allele';
    $seq_description .= $marker_symbol;
    $seq_description .= ' targeting project(s): ' . $project_ids;

    return $seq_description;
}

sub get_design_projects {
    my ($args) = @_;
    my $design = $args->{design};
    my @projects;

    if ( $args->{backbone} ){
        @projects = $design->projects->search(
            { cassette => $args->{cassette}, backbone => $args->{backbone} },
            { columns  => [qw/project_id/] } );
    }
    else {
        @projects = $design->projects->search(
            { cassette => $args->{cassette} },
            { columns => [qw/project_id/] } );
    }

    my @project_ids = map { $_->project_id } @projects;

    unless ( scalar(@project_ids) ) {
        my $msg = 'No project found for design: ' . $design->design_id;
        #die $msg;
        return 'None';
    }

    return join ':', @project_ids;
}

sub get_design_assembly{
	my ($design) = @_;
	
	my $display_features = $design->validated_display_features;
	
	my ($type) = keys %{ $display_features };
	my $assembly_id  = $display_features->{$type}->assembly_id;
	
	my $assembly_name = $ASSEMBLY_FOR_ID{$assembly_id}
	    or die 'No assembly name available for assembly_id $assembly_id';
	
	return $assembly_name;
}

1;

__END__
