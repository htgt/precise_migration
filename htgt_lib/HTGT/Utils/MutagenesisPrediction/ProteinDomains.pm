package HTGT::Utils::MutagenesisPrediction::ProteinDomains;

use Moose::Role;
use List::Util qw( min max );
use namespace::autoclean;

requires 'transcript';
has protein_families => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [ qw( Pfam ) ] }
);

has protein_domains => (
    isa        => 'ArrayRef[Bio::EnsEMBL::ProteinFeature]',
    traits     => [ 'Array' ],
    handles    => {
        protein_domains => 'elements'
    },
    init_arg   => undef,
    lazy_build => 1
);

sub _build_protein_domains {
    my $self = shift;

    my $translation = $self->transcript->translation;

    [ grep $self->_is_wanted_domain( $_ ), @{ $translation->get_all_DomainFeatures } ];
}

sub domains_for_peptide {
    my ( $self, $peptide ) = @_;
    return [] unless $peptide;

    my $transcript_peptide = $self->transcript->translation->seq;

    my $start = index( $transcript_peptide, $peptide );
    confess "can't find $peptide in $transcript_peptide" unless $start >= 0;

    my $end = $start + length( $peptide ) - 1;

    my @domains_with_overlap;

    for my $domain ( $self->protein_domains ) {
        my $overlap_start = max( $start, $domain->start );
        my $overlap_end   = min( $end, $domain->end );
        my $overlap = $overlap_end - $overlap_start + 1;
        if ( $overlap > 0 ) {
            push @domains_with_overlap, {
                domain      => $domain,
                amino_acids => [ $overlap, $domain->end - $domain->start + 1 ]
            }
        }
    }

    return \@domains_with_overlap;
}

sub domains_for_peptide_brief {
    my ( $self, $peptide ) = @_;
    [ map {
        description => $_->{domain}->idesc,
        interpro_ac => $_->{domain}->interpro_ac,
        amino_acids => $_->{amino_acids}
    },  @{ $self->domains_for_peptide( $peptide ) } ];
}

sub _is_wanted_domain {
    my ( $self, $domain ) = @_;

    my $logic_name = $domain->analysis->logic_name;
    for my $pf ( @{ $self->protein_families } ) {
        return 1 if uc $logic_name eq uc $pf;
    }

    return;
}

1;

__END__



