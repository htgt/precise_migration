#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';
use autodie;

use Path::Class;
use HTGT::DBFactory;
use Const::Fast;
use YAML::Syck;
use List::MoreUtils qw( uniq );
use Getopt::Long;
use Pod::Usage;

my $htgt    = HTGT::DBFactory->connect( 'eucomm_vector' );
my $kermits = HTGT::DBFactory->connect( 'kermits' );

my @input_project_ids;
my @input_genes;
GetOptions(
    'help'      => sub { pod2usage( -verbose => 1 ) },
    'man'       => sub { pod2usage( -verbose => 2 ) },
    'project=i' => \@input_project_ids,
    'gene=s'    => \@input_genes,
) and @ARGV == 1
    or pod2usage(2);

my $out_dir = $ARGV[0];

my @resultsets;
my @project_genes;
my @gene_projects;
if (scalar(@input_project_ids)) {
    @project_genes = map { $_->marker_symbol }
        $htgt->resultset( 'MGIGene' )->search (
            {
                'projects.project_id' => \@input_project_ids
            },
            {
                join => 'projects'
            }
        );
}

if (scalar(@input_genes)) {
    @gene_projects = map { $_->project_id }
        $htgt->resultset( 'Project' )->search(
            {
                'mgi_gene.marker_symbol' => \@input_genes
            },
            {
                join => 'mgi_gene'
            }
        );
}
my @project_ids = uniq (@input_project_ids, @gene_projects);
my @genes = uniq (@input_genes, @project_genes );    

my @clone_names =  map { $_->epd_well_name }
    $htgt->resultset( 'NewWellSummary' )->search(
        {
            project_id => \@project_ids,
            epd_well_name => { '!=', undef }
        },
        {
            columns  => [ 'epd_well_name' ],
            distinct => 1
        }
    );
    
my @design_ids = uniq map { $_->design_id }
    $htgt->resultset( 'Design' )->search(
        {
            'projects.project_id' => \@project_ids
        },
        {
            join     => 'projects',
            distinct => 1
        }
    );

my @feature_ids = map { $_->feature_id }
    $htgt->resultset('Feature')->search(
        {
            'design.design_id' => \@design_ids
        },
        {
            join     => 'design',
            distinct => 1
        }
    );
    
my @well_ids = uniq map { $_->well_id }
    $htgt->resultset('Well')->search(
        {
            'design.design_id' => \@design_ids
        },
        {
            join => { design_instance => 'design' }
        }
    );
    
my @plate_ids = uniq map { $_ ->plate_id }
    $htgt->resultset('Plate')->search(
        {
            'wells.well_id' => \@well_ids
        },
        {
            join => 'wells'
        }
    );

my $fixtures_dir        = dir( $out_dir );
my $htgt_fixture_dir    = $fixtures_dir->subdir( 'eucomm_vector' );
my $kermits_fixture_dir = $fixtures_dir->subdir( 'kermits' );

#
#EUCOMM_VECTOR
#
create_fixture(
    $htgt_fixture_dir,
    'MGIGene',
    $htgt->resultset( 'MGIGene' )->search_rs( {marker_symbol => \@genes} )
);

create_fixture(
    $htgt_fixture_dir,
    'Project',
    $htgt->resultset( 'Project' )->search_rs( { project_id => \@project_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'NewWellSummary',
    $htgt->resultset( 'NewWellSummary' )->search_rs( { project_id => \@project_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'DesignInstance',
    $htgt->resultset( 'DesignInstance' )->search_rs(
        {
            'projects.project_id' => \@project_ids
        },
        {
            join     => 'projects',
            distinct => 1
        }
    )
);

create_fixture(
    $htgt_fixture_dir,
    'Design',
    $htgt->resultset('Design')->search_rs( { design_id => \@design_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'DesignTaqmanAssay',
    $htgt->resultset('DesignTaqmanAssay')->search_rs( { design_id => \@design_ids } )
);


create_fixture(
    $htgt_fixture_dir,
    'Feature',
    $htgt->resultset('Feature')->search_rs( { feature_id => \@feature_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'FeatureData',
    $htgt->resultset('FeatureData')->search_rs(
        {
            'feature.feature_id' => \@feature_ids
        },
        {
            join     => 'feature',
        }
    )
);

create_fixture(
    $htgt_fixture_dir,
    'DisplayFeature',
    $htgt->resultset('DisplayFeature')->search_rs( { feature_id => \@feature_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'FeatureType',
    $htgt->resultset( 'FeatureType' )->search_rs( {} )
);

create_fixture(
    $htgt_fixture_dir,
    'FeatureDataType',
    $htgt->resultset( 'FeatureDataType' )->search_rs( {} )
);

create_fixture(
    $htgt_fixture_dir,
    'Chromosome',
    $htgt->resultset( 'Chromosome' )->search_rs( {} )
);

create_fixture(
    $htgt_fixture_dir,
    'ProjectStatus',
    $htgt->resultset( 'ProjectStatus' )->search_rs( {} )
);

create_fixture(
    $htgt_fixture_dir,
    'Well',
    $htgt->resultset('Well')->search_rs( { well_id => \@well_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'WellData',
    $htgt->resultset('WellData')->search_rs( { well_id => \@well_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'Plate',
    $htgt->resultset('Plate')->search_rs( { plate_id => \@plate_ids } )
);

create_fixture(
    $htgt_fixture_dir,
    'PlateData',
    $htgt->resultset('PlateData')->search_rs(
        {
            'plate.plate_id' => \@plate_ids
        },
        {
            join => 'plate'
        }
    )
);

#
#KERMITS
#

create_fixture(
    $kermits_fixture_dir,
    'EmiStatusDict',
    $kermits->resultset( 'EmiStatusDict' )->search_rs( {} )       
);

create_fixture(
    $kermits_fixture_dir,
    'EmiClone',
    $kermits->resultset( 'EmiClone' )->search_rs( { clone_name => \@clone_names } )
);

create_fixture(
    $kermits_fixture_dir,
    'EmiEvent',
    $kermits->resultset( 'EmiEvent' )->search_rs(
        {
            'clone.clone_name' => \@clone_names,
        },
        {
            join => 'clone'
        }
    )
);

create_fixture(
    $kermits_fixture_dir,
    'EmiAttempt',
    $kermits->resultset( 'EmiAttempt' )->search_rs(
        {
            'clone.clone_name' => \@clone_names
        },
        {
            join => { event => 'clone' }
        }
    )
);

print "YAML files for following tables created: \n";
print join "\n", @resultsets; 

sub create_fixture {
    my ( $fixtures_dir, $fixture_name, $rs ) = @_;

    my $out_file = $fixtures_dir->file( $fixture_name . '.yaml' );

    my @columns = $rs->result_source->columns;    

    my @data;

    while ( my $record = $rs->next ) {
        push @data, { map { $_ => $record->$_ } @columns };
    }
    push @resultsets, $fixture_name;
    YAML::Syck::DumpFile( $out_file, \@data );
}

__END__

=head1 NAME

dump_fixture_data.pl -  Create YAML files to fill test fixture data.

=head1 SYNOPSIS

dump_fixture_data.pl [options] output-dir

      --help                   Display a brief help message
      --man                    Display the manual page
      --projects (Int)         One or more project ids.
      --gene (Str)             One or more gene marker symbol

Must specify a output fixtures directory as a argument.
Must input either project id(s) or marker symbol(s)

=head1 DESCRIPTION

Create YAML files for resultset rows linked to given projects and or genes.
Only a set number of resultsets will be created (shown in output).

=head1 BUGS

None reported... yet.

=head1 ToDo

Specify either eucomm_vector, kermits or both.
Further data generation options (e.g. well , plate)?
Add further tables when needed.

=cut
