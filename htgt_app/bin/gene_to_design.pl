#!/usr/bin/env perl
use warnings FATAL => 'all';
use strict;

use Log::Log4perl ':easy';
use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory;
use CSV::Reader;
use CSV::Writer;
use Const::Fast;
use List::MoreUtils qw( uniq );

my $loglevel = $WARN;
my $schema   = HTGT::DBFactory->connect('eucomm_vector');

const my @OUT_COLUMNS => qw( design_id marker_symbol );

my ( $critical, $deleted );
GetOptions(
    'help'     => sub { pod2usage( -verbose => 1 ) },
    'man'      => sub { pod2usage( -verbose => 2 ) },
    'debug'    => sub { $loglevel = $DEBUG },
    'critical' => \$critical,
    'deleted'  => \$deleted,
) and @ARGV == 1
    or pod2usage(2);
Log::Log4perl->easy_init( { level => $loglevel, layout => '%p %x %m%n' } );

if ( !$critical && !$deleted ) {
    ERROR('Must specify either critical or deleted option');
    exit;
}

my $genes = get_genes($ARGV[0]);

my $csvout = CSV::Writer->new( columns => \@OUT_COLUMNS  );
$csvout->write( @OUT_COLUMNS );

foreach my $gene ( @{$genes} ) {
    Log::Log4perl::NDC->pop;
    Log::Log4perl::NDC->push( $gene->marker_symbol );
    my %data;
    $data{'marker_symbol'} = $gene->marker_symbol;

    my @projects = $gene->projects;
    unless ( scalar(@projects) >= 1 ) {
        ERROR('Gene has no projects associated with it');
        next;
    }

    my @designs = map{ $_->design_id } grep{ $_->design_id } @projects;

    #just one design for this gene, pick it!
    if ( scalar(uniq @designs) == 1 ) {
        $csvout->write( { marker_symbol => $gene->marker_symbol, design_id => $designs[0] } );
    }
    elsif ( scalar(uniq @designs) > 1 )  {
        DEBUG("has projects with multiple designs");
        gene_with_multiple_designs( $csvout, $gene, \@projects );
    }
    else {
        ERROR("Gene has projects but no designs associated with these projects");
    }
}

sub gene_with_multiple_designs {
    my ( $csvout, $gene, $projects ) = @_;

    #for now just interested in eucomm / komp-csd project OR switch projects, that are latest for that gene
    #also they must have a design (ES Cells - Conditional Gene Trap projects dont)
    #critical region designs are only for homozygous projects
    my $project_latest;
    if ( $critical ) {
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
        DEBUG(" .. and has one project with is latest for gene stamp, use this");
        my $project = $project_latest->next;

            $csvout->write( { marker_symbol => $gene->marker_symbol, design_id => $project->design_id } );
    }
    elsif ( $project_latest->count == 0 ) {
        INFO('.. no projects match criteria - komp_csd/eucomm or switch, is_latest_for_gene and have design_id, return all designs with es cells');
        projects_with_escell_clones( $projects, $gene, $csvout );
    }
    else {
        my @latest_projects = $project_latest->all;
        my @designs = uniq map{ $_->design_id } grep{ $_->design_id } @latest_projects;

        if ( scalar(@designs) == 1 ) {
            $csvout->write( { marker_symbol => $gene->marker_symbol, design_id => $designs[0] } );
        }
        else {
            DEBUG(".. has more than one project which matches criteria, return all designs with es cells");
            projects_with_escell_clones( \@latest_projects, $gene, $csvout );
        }
    }
}

sub projects_with_escell_clones {
    my ( $projects, $gene, $csvout ) = @_;
    my $design_count = 0;

    for my $project ( @{ $projects } ) {
        my $es_cells = $project->new_ws_entries->search( { epd_well_id => { '!=' => undef } } );
        if ( $es_cells->count ) {
            DEBUG( '... ' . $project->project_id . ' project has es cells, include design' );
            $csvout->write( { marker_symbol => $gene->marker_symbol, design_id => $project->design_id } );
            $design_count++;
        }
    }

    unless ( $design_count ) {
        INFO('... found no project with es_cells, returning designs from all projects');
        for my $project ( @{ $projects } ) {
            next unless $project->design_id;
            $csvout->write( { marker_symbol => $gene->marker_symbol, design_id => $project->design_id } );
        }
    }
}

sub get_genes {
    my $file = shift;
    my @genes;

    my $csv = CSV::Reader->new( input => $file, use_header => 1 );
    while ( my $g = $csv->read ) {
        my $gene;
        if ($g->{mgi_accession_id}) {
            $gene = $schema->resultset('MGIGene')->find({ mgi_accession_id => $g->{mgi_accession_id} });

            WARN('No gene found for: ' . $g->{mgi_accession_id}) unless $gene;
        }
        elsif ($g->{marker_symbol}) {
            my @genes = $schema->resultset('MGIGene')->search({ marker_symbol => $g->{marker_symbol} });

            if ( scalar(@genes) == 1 ) {
                $gene = $genes[0];
            }
            elsif ( scalar(@genes) > 1 ) {
                $gene = get_valid_gene( $g->{marker_symbol}, \@genes );
                next unless $gene;
            }
            else {
                WARN( 'No gene found for: ' . $g->{marker_symbol} );
                next;
            }
        }
        else {
            WARN('No mgi accession id or marker symbol');
            next;
        }

        push @genes, $gene if $gene;
    }

    return \@genes;
}

# deal with multiple genes found with same marker symbol
sub get_valid_gene {
    my ( $marker_symbol, $genes ) = @_;

    my @mgi_gene_ids = uniq map { $_->mgi_gene_id } @{ $genes };

    if ( scalar(@mgi_gene_ids) == 1 ) {
        # multiple entries for gene with same mgi_gene_id, we can pick any of these
        return $genes->[0];
    }

    get_valid_gene_with_multiple_ids( $marker_symbol, $genes );
}

# deal with genes with same marker symbol but different mig_gene_ids
sub get_valid_gene_with_multiple_ids {
    my ( $marker_symbol, $genes ) = @_;
    my @valid_genes;
    for my $gene ( @{ $genes } ) {
        my @projects = $gene->projects;
        if ( scalar(@projects) >= 1 ) {
            push @valid_genes, $gene;
        }
    }
    if ( scalar(@valid_genes) > 1 ) {
        WARN( 'Multiple genes found for: ' . $marker_symbol
              . ' and more than one of these genes is linked to projects' );
        return;
    }
    elsif ( !@valid_genes ) {
        WARN( 'Multiple genes found for: ' . $marker_symbol
              . ' and no projects found for any of these genes ');
        return;
    }

    # only one of the genes has projects associated with it, use this
    return $valid_genes[0];
}

__END__

=head1 NAME

gene_to_design.pl

=head1 SYNOPSIS

gene_to_design.pl [options] input

      --help            Display a brief help message
      --man             Display the manual page
      --debug           Print debug messages
      --critical        Designs for critical regions - all homozygous projects (switch)
      --deleted         Designs for deleted region

Takes genes in as a csv file with either marker symbol or
mgi accession as one of the columns

=head1 DESCRIPTION

Output designs related to given gene for a set of very specific criteria at the moment.

=head1 AUTHOR

Sajith Perera

=head1 BUGS

None reported... yet.

=headl TODO

=cut
