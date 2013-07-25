package HTGT::Utils::TargRep::Update::RegeneronGenbank;

use Moose;
use namespace::autoclean;
use Const::Fast;
use HTGT::Utils::TargRep::Update::Genbank qw( get_regeneron_seq );
use Data::Dumper::Concise;
use Try::Tiny;
use List::MoreUtils qw( uniq any );
use Const::Fast;

const my %REGENERON_CASSETTES => (
    'TM-ZEN-UB1' => 'TM_Zen_Ub1',
    'ZEN-UB1.GB' => 'Zen_Ub1',
    'ZEN-Ub1'    => 'Zen_Ub1',
);

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

sub update_regeneron_genbank_files {
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

    my $regeneron = $self->targrep_schema->resultset('TargRepPipeline')->find( { name => 'KOMP-Regeneron' } );
    my @regeneron_escells;
    if ( $self->has_projects ) {
        @regeneron_escells = $regeneron->targ_rep_es_cells->search(
            { ikmc_project_id => $self->projects },
            { columns => [ 'allele_id' ] }
        );
    }
    else {
        @regeneron_escells = $regeneron->targ_rep_es_cells->search( {}, { columns => [ 'allele_id' ] } );
    }
    my @uniq_regeneron_allele_ids = uniq map{ $_->allele_id } @regeneron_escells;

    my @alleles = $self->targrep_schema->resultset('TargRepAllele')->search(
        {
            'me.id'              => \@uniq_regeneron_allele_ids,
            'targ_rep_mutation_type.name' => 'Deletion',
        },
        {
            join => [ 'targ_rep_genbank_files', 'targ_rep_mutation_type' ]
        }
    );

    return \@alleles;
}

sub process_allele {
    my ( $self, $allele ) = @_;
    Log::Log4perl::NDC->remove();
    Log::Log4perl::NDC->push( $allele->id );

    die('Unexpected cassette: ' . $allele->cassette)
        unless any { $allele->cassette eq $_ } keys %REGENERON_CASSETTES;

    my @genbank_files
        = $self->targrep_schema->resultset('TargRepGenbankFile')->search( { allele_id => $allele->id } );

    my %regeneron_seq_config = (
        allele   => $allele,
        gene_id  => $allele->gene->mgi_accession_id,
        cassette => $REGENERON_CASSETTES{$allele->cassette},
    );
    $regeneron_seq_config{eng_seq_config} = $self->eng_seq_config if $self->has_eng_seq_config;

    my $escell_clone = get_regeneron_seq( %regeneron_seq_config );
    if ( !scalar(@genbank_files) ) {
        $self->log->info('Found no matching genbank files');
        $self->upload_genbank_files( $escell_clone, $allele->id );
    }
    elsif ( scalar(@genbank_files) == 1 ) {
        my $genbank = $genbank_files[0];
        $self->log->debug( 'Found genbank files: ' . $genbank->id );

        if ( $self->check_genbank ) {
            $self->check_and_update_genbank_files( $genbank, $escell_clone );
        }
    }
    else {
        die( 'Found ' . scalar(@genbank_files) . ' matching genbank files for allele: ' . $allele->id );
    }
}

sub upload_genbank_files {
    my ( $self, $escell_clone, $allele_id ) = @_;
    $self->log->info( "Creating Genbank file" );
    return unless $self->commit;

    my %genbank_data;

    my $genbank = $self->idcc_api->create_genbank_file(
        {
            allele_id    => $allele_id,
            escell_clone => $escell_clone,
        }
    );
    $self->log->info( "... created file: " . $genbank->{id} );

}

sub check_and_update_genbank_files {
    my ( $self, $genbank, $new_escell_clone ) = @_;

    my %update_data;
    my $current_escell_clone = $genbank->escell_clone;
    if ( !defined $genbank->escell_clone ) {
        $self->log->info( "genbank record field escell_clone not set");
        $update_data{escell_clone} = $new_escell_clone;
    }
    elsif ( $current_escell_clone ne $new_escell_clone ) {

        $self->log->warn( "Incorrect escell_clone field for genbank record");
        $update_data{escell_clone} = $new_escell_clone;
    }
    else {
        $self->log->debug( "Escell genbank file is the same");
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
