package HTGT::Utils::Recovery::ResultSets;

use Moose::Role;
use namespace::autoclean;

use HTGT::Utils::Recovery::Constants qw( @PROJECT_STATUS_IGNORE_GENE @PROJECT_STATUS_IGNORE_PROJECT @BL6_CLONE_LIBS );

=head1 DESCRIPTION

Moose Role that defines the B<DBIx::Class::Resultset> objects required
by the B<HTGT::Utils::Recovery::GeneData> module.

=method komp_eucomm_project_rs

Returns a B<DBIx::Class::ResultSet> to search for all KOMP_CSD or EUCOMM
projects for this gene.

=cut

sub komp_eucomm_project_rs {
    my $self = shift;

    $self->schema->resultset( 'Project' )->search_rs(
        {
            'me.mgi_gene_id' => $self->mgi_gene_id,
            -nest            => [ 'me.is_komp_csd' => 1, 'me.is_eucomm' => 1 ],
        }
    );
}

=method project_ignore_gene_status_rs 

Returns a B<DBIx::Class::Resultset> to search for KOMP_CSD or EUCOMM
projects for this gene with a status that indicates no recovery should
be attempted for the B<gene>.

=cut

sub project_ignore_gene_status_rs {
    my $self = shift;

    $self->komp_eucomm_project_rs->search_rs(
        {
            'status.code'    => { -in => \@PROJECT_STATUS_IGNORE_GENE }
        },
        {
            join => 'status'
        }
    );
}

=method active_project_rs

Returns a B<DBIx::Class::Resultset> to search for the active KOMP_CSD
or EUCOMM projects for this gene.

=cut

sub active_project_rs {
    my $self = shift;

    $self->schema->resultset( 'Project' )->search_rs(
        {
            'me.mgi_gene_id' => $self->mgi_gene_id,
            -nest            => [ 'me.is_komp_csd' => 1, 'me.is_eucomm' => 1 ],
            'status.code'    => { -not_in => \@PROJECT_STATUS_IGNORE_PROJECT }            
        },
        {
            join => 'status'
        }
    );
}

=method active_bl6_project_rs

Returns a B<DBIx::Class::Resultset> to search for active KOMP_CSD or
EUCOMM projects for this gene with a Bl6/J BAC strain.

=cut

sub active_bl6_project_rs {
    my $self = shift;

    $self->active_project_rs->search_rs(
        {
            'bac.clone_lib_id' => \@BL6_CLONE_LIBS
        },
        {
            join => { design_instance => { design_instance_bacs => 'bac' } }
        }        
    );
}

=method wsdi_active_project_rs

Returns a B<DBIx::Class::Resultset> to search for
I<well_summary_by_di> rows for the active projects for this gene.

=cut

sub wsdi_active_project_rs {
    my $self = shift;

    $self->schema->resultset( 'WellSummaryByDI' )->search_rs(
        {
            project_id => $self->active_project_ids
        }
    );
}

=method wsdi_active_bl6_project_rs

Returns a B<DBIx::Class::Resultset> to search for
I<well_summary_by_di> rows for the active projects for this gene with
a Bl6/J BAC strain..

=cut

sub wsdi_active_bl6_project_rs {
    my $self = shift;

    $self->schema->resultset( 'WellSummaryByDI' )->search_rs(
        {
            project_id => $self->active_bl6_project_ids
        }
    );
}

1;

__END__
