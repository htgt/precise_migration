package HTGT::Utils::TaqMan::DesignsByGene;

use Moose::Role;
use namespace::autoclean;
use List::MoreUtils qw( uniq );

sub get_designs_by_gene {
    my ( $self, $gene_name ) = @_;

    my $gene = $self->get_gene( $gene_name )
        or die "Unable to find gene $gene_name";

    my @projects = $gene->projects;
    unless ( scalar(@projects) >= 1 ) {
        die "$gene_name has no projects associated with it";
    }

    my @designs = map{ $_->design_id } grep{ $_->design_id } @projects;

    #just one design for this gene, pick it!
    if ( scalar(uniq @designs) == 1 ) {
        return \@designs;
    }
    elsif ( scalar(uniq @designs) > 1 )  {
        $self->log->debug("$gene_name has projects with multiple designs");
        return $self->gene_with_multiple_designs( $gene, \@projects );
    }
    else {
        die "$gene_name has projects but no designs associated with these projects";
    }
}

sub get_gene {
    my ( $self, $gene_name ) = @_;
    my $gene;

    if ( $gene_name =~ /^MGI:/ ) {
        $gene = $self->schema->resultset('MGIGene')->find({ mgi_accession_id => $gene_name });
    }
    else {
        my @genes = $self->schema->resultset('MGIGene')->search({ marker_symbol => $gene_name });

        if ( scalar(@genes) == 1 ) {
            $gene = $genes[0];
        }
        elsif ( scalar(@genes) > 1 ) {
            $gene = $self->get_valid_gene( $gene_name, \@genes );
        }
    }

    return $gene;
}

sub gene_with_multiple_designs {
    my ( $self, $gene, $projects ) = @_;

    #for now just interested in eucomm / komp-csd project OR switch projects, that are latest for that gene
    #also they must have a design (ES Cells - Conditional Gene Trap projects dont)
    #critical region designs are only for homozygous projects
    my $project_latest;
    if ( $self->target eq 'critical' ) {
        $project_latest = $gene->projects->search(
            {
                is_latest_for_gene => 1,
                design_id => { '!=', undef },
                is_switch => 1
            }
        );
    }
    else {
        $project_latest = $gene->projects->search(
            {
                is_latest_for_gene => 1,
                design_id => { '!=', undef },
                -or => [
                    is_komp_csd     => 1,
                    is_eucomm       => 1,
                    is_eucomm_tools => 1,
                ]
            }
        );
    }

    if ( $project_latest->count == 1 ) {
        $self->log->debug(" .. and has one project with is latest for gene stamp, use this");
        my $project = $project_latest->next;
        return [ $project->design_id ];
    }
    elsif ( $project_latest->count == 0 ) {
        $self->log->info('.. no projects match criteria - komp_csd/eucomm or switch, is_latest_for_gene and have design_id, return all designs with es cells');
        $self->projects_with_escell_clones( $projects, $gene );
    }
    else {
        my @latest_projects = $project_latest->all;
        my @designs = uniq map{ $_->design_id } grep{ $_->design_id } @latest_projects;

        if ( scalar(@designs) == 1 ) {
            return \@designs;
        }
        else {
            $self->log->debug(".. has more than one project which matches criteria, return all designs with es cells");
            $self->projects_with_escell_clones( \@latest_projects, $gene );
        }
    }
}

sub projects_with_escell_clones {
    my ( $self, $projects, $gene ) = @_;
    my @designs;

    for my $project ( @{ $projects } ) {
        my $es_cells = $project->new_ws_entries->search( { epd_well_id => { '!=' => undef } } );
        if ( $es_cells->count ) {
            $self->log->debug( '... ' . $project->project_id . ' project has es cells, include design' );
            push @designs, $project->design_id;
        }
    }

    unless ( @designs ) {
        $self->log->info('... found no project with es_cells, returning designs from all projects');
        for my $project ( @{ $projects } ) {
            next unless $project->design_id;
            push @designs, $project->design_id;
        }
    }

    return \@designs;
}

# deal with multiple genes found with same marker symbol
sub get_valid_gene {
    my ( $self, $gene_name, $genes ) = @_;

    my @mgi_gene_ids = uniq map { $_->mgi_gene_id } @{ $genes };

    if ( scalar(@mgi_gene_ids) == 1 ) {
        # multiple entries for gene with same mgi_gene_id, we can pick any of these
        return $genes->[0];
    }

    return $self->get_valid_gene_with_multiple_ids( $gene_name, $genes );
}

# deal with genes with same marker symbol but different mig_gene_ids
sub get_valid_gene_with_multiple_ids {
    my ( $self, $gene_name, $genes ) = @_;
    my @valid_genes;
    for my $gene ( @{ $genes } ) {
        my @projects = $gene->projects;
        if ( scalar(@projects) >= 1 ) {
            push @valid_genes, $gene;
        }
    }

    if ( scalar(@valid_genes) > 1 ) {
        $self->log->warn( 'Multiple genes found for: ' . $gene_name
              . ' and more than one of these genes is linked to projects' );
        return;
    }
    elsif ( !@valid_genes ) {
        $self->log->warn( 'Multiple genes found for: ' . $gene_name
              . ' and no projects found for any of these genes ');
        return;
    }

    # only one of the genes has projects associated with it, use this
    return $valid_genes[0];
}

1;

__END__
