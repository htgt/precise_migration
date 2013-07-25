package HTGT::Utils::TargRep::Update::MirKOGenbank;

use Moose;
use namespace::autoclean;
use Const::Fast;
use HTGT::Utils::DesignFinder::Gene;
use HTGT::Utils::TargRep::Update::Genbank qw( get_norcomm_seq );
use Data::Dumper::Concise;
use Try::Tiny;
use List::MoreUtils qw( uniq any );
use Const::Fast;

const my %NORCOMM_CASSETTES => (
    'L1L2_NTARU-0' => 'L1L2_NTARU-0',
    'L1L2_NTARU-1' => 'L1L2_NTARU-1',
    'L1L2_NTARU-2' => 'L1L2_NTARU-2',
    'L1L2_NTARU-K' => 'L1L2_NTARU-K',
);
const my $NORCOMM_BACKBONE => 'L3L4_pZero_DTA_kan';

with qw( MooseX::Log::Log4perl );

has targrep_schema => (
    is       => 'ro',
    isa      => 'Tarmits::Schema',
    required => 1,
);

has htgt_schema => (
    is       => 'ro',
    isa      => 'HTGTDB',
    required => 1,
);

has idcc_api => (
    is       => 'ro',
    isa      => 'HTGT::Utils::Tarmits',
    required => 1,
);

has eng_seq_config => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    coerce    => 1,
    predicate => 'has_eng_seq_config'
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

has check_genbank => (
    is       => 'ro',
    isa      => 'Bool',
    default  => 0,
    required => 1,
);

sub update_norcomm_genbank_files {
    my $self = shift;

    my $alleles = $self->get_alleles;

    foreach my $allele ( @{ $alleles } ) {
        try{
            $self->process_allele( $allele );
        }
        catch {
            $self->log->error('Error processing allele ' . $allele->id . ' : ' . $_ );
        };
    }
}

sub get_alleles {
    my $self = shift;

    my @norcomm_allele_ids;
    my $norcomm = $self->targrep_schema->resultset('TargRepPipeline')->find( { name => 'NorCOMM' } );
    my ( @norcomm_escells, @norcomm_targ_vecs );

    if ( $self->has_projects ) {
        @norcomm_escells = $norcomm->es_cells->search(
            { ikmc_project_id => $self->projects },
            { columns => [ 'allele_id' ] }
        );
        @norcomm_targ_vecs = $norcomm->targeting_vectors->search(
            { ikmc_project_id => $self->projects },
            { columns => [ 'allele_id' ] }
        );
    }
    else {
        @norcomm_escells = $norcomm->es_cells->search( {}, { columns => [ 'allele_id' ] } );
        @norcomm_targ_vecs = $norcomm->targeting_vectors->search( {}, { columns => [ 'allele_id' ] } );
    }

    push @norcomm_allele_ids, map{ $_->allele_id } @norcomm_escells;
    push @norcomm_allele_ids, map{ $_->allele_id } @norcomm_targ_vecs;
    my @uniq_norcomm_allele_ids = uniq @norcomm_allele_ids;

    my @alleles = $self->targrep_schema->resultset('TargRepAllele')->search(
        {
            id => \@uniq_norcomm_allele_ids,
            'targ_rep_mutation_type.name' => 'Deletion',
        },
        {
            join => 'targ_rep_mutation_type',
        }
    );

    return \@alleles;
}

sub process_allele {
    my ( $self, $allele ) = @_;
    Log::Log4perl::NDC->remove();
    Log::Log4perl::NDC->push( $allele->id );

    die('Unexpected cassette: ' . $allele->cassette)
        unless any { $allele->cassette eq $_ } keys %NORCOMM_CASSETTES;
    die('Unexpected backbone: ' . $allele->backbone) unless $allele->backbone =~ /$NORCOMM_BACKBONE/;

    my @genbank_files
        = $self->targrep_schema->resultset('TargRepGenbankFile')->search( { allele_id => $allele->id, } );

    my %norcomm_seq_config = (
        allele   => $allele,
        gene_id  => $allele->mgi_accession_id,
        cassette => $NORCOMM_CASSETTES{$allele->cassette},
        backbone => $allele->backbone,
    );
    $norcomm_seq_config{eng_seq_config} = $self->eng_seq_config if $self->has_eng_seq_config;

    if ( !scalar(@genbank_files) ) {
        $self->log->info('Found no matching genbank files');
        my $genbank_data = get_norcomm_seq( %norcomm_seq_config );
        $self->upload_genbank_files( $genbank_data, $allele->id );
    }
    elsif ( scalar(@genbank_files) == 1 ) {
        my $genbank = $genbank_files[0];
        $self->log->debug( 'Found genbank files: ' . $genbank->id );

        if ( $self->check_genbank ) {
            my $genbank_data = get_norcomm_seq( %norcomm_seq_config );
            $self->check_and_update_genbank_files( $genbank, $genbank_data );
        }
    }
    else {
        die( 'Found ' . scalar(@genbank_files) . ' matching genbank files for allele: ' . $allele->id );
    }
}

sub upload_genbank_files {
    my ( $self, $genbank_data, $allele_id ) = @_;
    return unless $self->commit;

    $genbank_data->{allele_id} = $allele_id;
    try {
        my $genbank = $self->idcc_api->create_genbank_file( $genbank_data );
        $self->log->info( "Created new genbank file : " . $genbank->{id} );
    }
    catch {
        die( "Unable to create genbank file :" . $_ );
    };
}

sub check_and_update_genbank_files {
    my ( $self, $genbank, $new_genbank_data ) = @_;

    my %update_data;
    for my $field ( qw( escell_clone targeting_vector )) {
        if ( !defined $genbank->$field ) {
            $self->log->info( "genbank record field $field not set");
            $update_data{$field} = $new_genbank_data->{$field};
        }
        elsif ( $genbank->$field ne $new_genbank_data->{$field} ) {
            $self->log->warn( "Incorrect $field for genbank record");
            $update_data{$field} = $new_genbank_data->{$field};
        }
    }

    $self->update_genbank_files( \%update_data, $genbank ) if %update_data;
}

sub update_genbank_files {
    my ( $self, $update_data, $genbank ) = @_;
    return unless $self->commit;

    try {
        $self->idcc_api->update_genbank_file( $genbank->id, $update_data );
        $self->log->info( "Updating genbank files: " . Dumper($update_data) );
    }
    catch {
        die ( "Unable to update genbank files" . $_ );
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
