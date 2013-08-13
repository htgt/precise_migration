package HTGT::Utils::UpdateDesign::ProjectGene;

=head1 NAME

HTGT::Utils::UpdateDesign::ProjectGene

=head1 DESCRIPTION

Update the gene linked to a designs projects.

=cut

use Moose;
use namespace::autoclean;
use Try::Tiny;

extends 'HTGT::Utils::UpdateDesign';

my $MGI_ACCESSION_ID_RX = qr/^MGI:\d+$/;

has new_mgi_accession_id => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    trigger  => \&_check_mgi_accession_id,
);

sub _check_mgi_accession_id {
    my ( $self, $id ) = @_;

    unless ( $id =~ $MGI_ACCESSION_ID_RX ) {
        die( "Invalid MGI accession id: $id" );
    }
    return;
}

has new_mgi_gene_id => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

sub _build_new_mgi_gene_id {
    my $self = shift;

    my $mgi_gene = $self->schema->resultset('MGIGene')->find(
        { mgi_accession_id => $self->new_mgi_accession_id } );
    die( 'We can not find mgi accession id: ' .  $self->new_mgi_accession_id ) unless $mgi_gene;

    return $mgi_gene->mgi_gene_id;
}

has projects => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_projects {
    my $self = shift;

    my @projects = $self->design->projects;
    die( 'No projects linked to design' ) unless @projects;

    return \@projects;
}

sub update {
    my ( $self ) = @_;

    if ( $self->projects->[0]->mgi_gene_id == $self->new_mgi_gene_id  ) {
        die( 'Project already linked to this mgi gene' );
    }

    foreach my $project ( @{ $self->projects } ) {
        $self->add_note(
            'Project ' . $project->project_id . ' mgi accession id has been changed from '
            . $project->mgi_gene->mgi_accession_id . ' to ' . $self->new_mgi_accession_id
        );

        $project->update( {'mgi_gene_id' => $self->new_mgi_gene_id } );
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
