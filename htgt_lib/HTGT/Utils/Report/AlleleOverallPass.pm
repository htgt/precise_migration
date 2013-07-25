package HTGT::Utils::Report::AlleleOverallPass;

use Moose;
use Const::Fast;
use HTGT::Utils::AlleleQCInterpreter;
use Iterator::Util;
use namespace::autoclean;

with 'HTGT::Utils::Report::GenericIterator';

const my @IDCC_TARG_REP_ATTRS => qw(
    pipeline
    ikmc_project_id
    mgi_accession_id
    mutation_type
    targeting_vector
    escell_clone
    allele_symbol_superscript    
    production_qc_five_prime_screen
    production_qc_loxp_screen
    production_qc_three_prime_screen
    production_qc_loss_of_allele
    production_qc_vector_integrity
    distribution_qc_karyotype_high
    distribution_qc_karyotype_low
    distribution_qc_copy_number
    distribution_qc_five_prime_lr_pcr
    distribution_qc_five_prime_sr_pcr
    distribution_qc_three_prime_sr_pcr
    distribution_qc_loa
    distribution_qc_loxp
    user_qc_southern_blot
    user_qc_map_test
    user_qc_karyotype
    user_qc_tv_backbone_assay
    user_qc_five_prime_lr_pcr
    user_qc_loss_of_wt_allele
    user_qc_neo_count_qpcr
    user_qc_lacz_sr_pcr
    user_qc_five_prime_cassette_integrity
    user_qc_neo_sr_pcr
    user_qc_mutant_specific_sr_pcr
    user_qc_loxp_confirmation
    user_qc_three_prime_lr_pcr
    user_qc_comment    
);

const my @KERMITS_ATTRS => qw(
    pipeline
    marker_symbol
    consortium 
    microinjection_status
    production_centre
    microinjection_date
    qc_southern_blot
    qc_tv_backbone_assay
    qc_five_prime_lr_pcr
    qc_loa_qpcr
    qc_homozygous_loa_sr_pcr
    qc_neo_count_qpcr
    qc_lacz_sr_pcr
    qc_five_prime_cassette_integrity
    qc_neo_sr_pcr
    qc_mutant_specific_sr_pcr
    qc_loxp_confirmation
    qc_three_prime_lr_pcr
    colony_prefix
);

const my @QC_ATTRS => qw(
    indicator
    confirm_locus_targeted
    confirm_structure_targeted_allele
    confirm_downstream_loxP_site
    confirm_no_additional_vector_insertions
    es_dist_qc
    es_user_qc
    mouse_qc
);

const my @COLUMNS => qw(
    indicator
    colony_prefix
    pipeline
    consortium 
    production_centre
    microinjection_date
    marker_symbol
    mutation_type
    escell_clone
    confirm_locus_targeted
    confirm_structure_targeted_allele
    confirm_downstream_loxP_site
    confirm_no_additional_vector_insertions
    es_dist_qc
    es_user_qc
    mouse_qc
);

has idcc_mart => (
    is       => 'ro',
    isa      => 'HTGT::BioMart::QueryFactory',
    required => 1,
);

has results => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1
);

around BUILDARGS => sub {
      my $orig = shift;
      my $class = shift;

      if ( @_ == 1 && ref $_[0] ne 'HASH' ) {
          return $class->$orig( idcc_mart => $_[0] );
      }
      else {
          return $class->$orig( @_ );
      }
};

sub _build_results {
    my $self = shift;

    my $query = $self->idcc_mart->query(
        {
            dataset    => 'idcc_targ_rep',
            attributes => \@IDCC_TARG_REP_ATTRS
        },
        {
            dataset    => 'imits',
            filter     => {
                microinjection_status => [
                    'Genotype Confirmed'
                ]
            },
            attributes => \@KERMITS_ATTRS
        }
    );

    my %results;

    for my $r ( @{ $query->results } ) {
        next unless $r->{escell_clone};
        
        my $qc = HTGT::Utils::AlleleQCInterpreter->new( record => $r );

        for ( @QC_ATTRS ) {
            $r->{$_} = $qc->$_;            
        }

        $results{ $r->{escell_clone} }{ $r->{microinjection_date} } = $r;
    }

    return \%results;     
}

# Methods we need to implement for the HTGT::Utils::Report::GenericIterator
# role

sub _build_name {
    "Allele Overall Pass";    
}

sub _build_columns {
    \@COLUMNS;    
}

sub _build_iterator {
    my $self = shift;

    my @rows = sort { $a->{escell_clone} cmp $b->{escell_clone}
                          || $a->{microinjection_date} cmp $b->{microinjection_date} }
        map values %$_, values %{ $self->results };

    Iterator::Util::iarray( \@rows );
}

__PACKAGE__->meta->make_immutable;

1;

__END__
