package HTGT::Utils::AlleleQCInterpreter;

use strict;
use warnings FATAL => 'all';

use Moose;
use Const::Fast;
use namespace::autoclean;

=head1 Description 

This module represents a single row of merged targrep and imits qc-values:
when constructed (by HTGT::Utils::Report::AlleleOverallPass) it is passed these attributes as a hash,
and it keeps them in the 'record' instance variable.

You can access those attributes directly using get_value(attribute name)

The module itself builds a hashref of passing tests and a hashref of
failing tests by fetching out the results from the 'results' hash.

=cut


const my $ES_CELL_PRODUCTION   => 'es_cell_production';
const my $ES_CELL_DISTRIBUTION => 'es_cell_distribution';
const my $ES_CELL_USERS        => 'es_cell_users';
const my $MOUSE_PRODUCTION     => 'mouse_production';

const my %ATTRIBUTE_NAMES => (
    $ES_CELL_PRODUCTION => [
        qw(
            production_qc_five_prime_screen 
            production_qc_loxp_screen 
            production_qc_three_prime_screen 
            production_qc_loss_of_allele 
            production_qc_vector_integrity
      )
    ],
    $ES_CELL_DISTRIBUTION => [
        qw(
            distribution_qc_karyotype_high 
            distribution_qc_karyotype_low 
            distribution_qc_copy_number 
            distribution_qc_five_prime_lr_pcr 
            distribution_qc_five_prime_sr_pcr 
            distribution_qc_three_prime_sr_pcr
            distribution_qc_loa
            distribution_qc_loxp
      )
    ],
    $ES_CELL_USERS => [
        qw(
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
      )
    ],
    $MOUSE_PRODUCTION => [
        qw(
            qc_southern_blot 
            qc_tv_backbone_assay 
            qc_five_prime_lr_pcr 
            qc_loa_qpcr 
            qc_homozygous_loa_sr_pcr 
            qc_neo_count_qpcr 
            qc_lacz_sr_pcr 
            qc_five_prime_cass_integrity 
            qc_neo_sr_pcr 
            qc_mutant_specific_sr_pcr 
            qc_loxp_confirmation 
            qc_three_prime_lr_pcr   
      )
    ]
);

has record => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    traits   => [ 'Hash' ],
    handles  => {
        get_value => 'get'
    }
);

has failures => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1
);

has passes => (
    is         => 'ro',
    isa        => 'HashRef',
    init_arg   => undef,
    lazy_build => 1
);

around get_value => sub {
    my $orig = shift;
    my $self = shift;

    my $v = $self->$orig( @_ );
    return defined $v ? $v : '';
};

sub is_fail {
    my $self = shift;

    for ( @_ ) {
        return 1 if $self->get_value( $_ ) eq 'fail';
    }
    return;    
}

sub is_pass {
    my $self = shift;

    for ( @_ ) {
        return 1 if $self->get_value( $_ ) eq 'pass';
    }
    return;    
}

sub _build_failures {
    my $self = shift;

    my %failures;

    for my $section ( keys %ATTRIBUTE_NAMES){
        for my $name ( @{ $ATTRIBUTE_NAMES{$section} } ) {
            $failures{$section}{$name} = 1
                if $self->is_fail( $name );
        }
    }
    
    return \%failures;
}

sub _build_passes {
    my $self = shift;

    my %passes;

    for my $section ( keys %ATTRIBUTE_NAMES ) {
        for my $name ( @{ $ATTRIBUTE_NAMES{$section} } ) {
            $passes{$section}{$name} = 1
                if $self->is_pass( $name );            
        }
    }

    return \%passes;
}

sub confirm_locus_targeted {
    my $self = shift;

    $self->southern_blot || $self->loss_of_wt_allele_qpcr || $self->five_or_three_lrpcr || $self->homozygous_loa_sr_pcr;
}

sub confirm_structure_targeted_allele {
    my $self = shift;

    $self->southern_blot || $self->neo_count_qpcr || $self->various_sr_pcr;
}

sub confirm_downstream_loxP_site {
    my $self = shift;

    $self->is_pass(
        qw( 
            distribution_qc_loxp
            distribution_qc_three_prime_sr_pcr
            user_qc_loxp_confirmation
            qc_loxp_confirmation
      ) );
}

sub confirm_no_additional_vector_insertions {
    my $self = shift;

    # The original spec had this as southern || (neo + vector-backbone pcr)
    # It has been relaxed to neo-count only as of 29 - 6 - 2011
    $self->southern_blot || $self->neo_count_qpcr ;
}

sub southern_blot {
    my $self = shift;

    $self->is_pass( qw( user_qc_southern_blot qc_southern_blot ) );
}

sub loss_of_wt_allele_qpcr {
    my $self = shift;

    $self->is_pass( qw( distribution_qc_loa user_qc_loss_of_wt_allele qc_loa_qpcr ) );
}

sub five_or_three_lrpcr {
    my $self = shift;

    $self->is_pass(
        qw( distribution_qc_five_prime_lr_pcr
            user_qc_five_prime_lr_pcr
            user_qc_three_prime_lr_pcr
            qc_five_prime_lr_pcr
            qc_three_prime_lr_pcr
      ) );    
}

sub homozygous_loa_sr_pcr {
    my $self = shift;

    $self->is_pass( qw( qc_homozygous_loa_sr_pcr ) );
}


sub neo_count_qpcr {
    my $self = shift;

    $self->is_pass(
        qw( user_qc_neo_count_qpcr
            qc_neo_count_qpcr
      ) );
}

sub various_sr_pcr {
    my $self = shift;

    $self->neo_srpcr
        || $self->lacz_srpcr
            || $self->mutant_specific_srpcr
                || $self->vector_backbone
                    || $self->is_pass( qw( distribution_qc_five_prime_sr_pcr distribution_qc_three_prime_sr_pcr ) );
}

sub neo_srpcr {
    my $self = shift;

    $self->is_pass( qw( user_qc_neo_sr_pcr qc_neo_sr_pcr ) );
}

sub lacz_srpcr {
    my $self = shift;

    $self->is_pass( qw( user_qc_lacz_sr_pcr qc_lacz_sr_pcr ) );
}

sub mutant_specific_srpcr {
    my $self = shift;

    $self->is_pass( qw( user_qc_mutant_specific_sr_pcr qc_mutant_specific_sr_pcr ) );
}

sub vector_backbone {
    my $self = shift;

    $self->is_pass( qw( user_qc_tv_backbone_assay qc_tv_backbone_assay ) );
}

sub indicator {
    my $self = shift;

    my $mutation_type = $self->get_value('mutation_type');
    
    if($mutation_type eq 'Conditional Ready'){
        if ( $self->confirm_locus_targeted
                 && $self->confirm_structure_targeted_allele
                     && $self->confirm_downstream_loxP_site
                         && $self->confirm_no_additional_vector_insertions
        ) {
            return 'allpass';
        }
        else {
            return 'inprocess';
        }
    }else{
        if ( $self->confirm_locus_targeted
                 && $self->confirm_structure_targeted_allele
                         && $self->confirm_no_additional_vector_insertions
        ) {
            return 'allpass';
        }
        else {
            return 'inprocess';
        }
    }
}

sub es_user_qc {
    shift->_qc_passes( $ES_CELL_USERS );
}

sub es_dist_qc {
    shift->_qc_passes( $ES_CELL_DISTRIBUTION );
}

sub es_prod_qc {
    shift->_qc_passes( $ES_CELL_PRODUCTION );
}

sub mouse_qc {
    shift->_qc_passes( $MOUSE_PRODUCTION );
}

sub _qc_passes {
    my ( $self, $section ) = @_;

    join ' ', sort keys %{ $self->passes->{ $section } };
}

__PACKAGE__->meta->make_immutable;

1;

__END__
