package HTGT::Utils::Report::AlternateCloneRecoveryStatus;

use strict;
use warnings FATAL => 'all';

use base 'Exporter';
use Readonly;

BEGIN {
    our @EXPORT      = qw( get_alternate_clone_recovery_status );
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = ();
}

Readonly our @COLUMNS =>
    qw( marker_symbol ensembl_gene_id vega_gene_id sponsor plates dna_pass ep epd_distribute );

sub get_alternate_clone_recovery_status {
    my $schema = shift;

    my $wells = $schema->resultset( 'Well' )->search(
        {
            'plate_data.data_type'  => 'alternate_clone_recovery',
            'plate_data.data_value' => 'yes',
        },
        { join => { plate => 'plate_data' } }
    );

    my %stash;

    while ( my $well = $wells->next ) {
        my $di = $well->design_instance_id
            or next;

        my $project = $schema->resultset( 'Project' )->search(
            { design_instance_id => $di },
            { prefetch => 'mgi_gene' }
        )->first or die "failed to retrieve project for design instance " . $di->design_instance_id;

        my $mgi_gene_id = $project->mgi_gene_id;
        $stash{ $mgi_gene_id } ||= init_stash( $project );
        add_descendant_data( $stash{ $mgi_gene_id }, $well );
    }
    
    # Convert hash of plate names into comma-separated list
    $_->{plates} = join( q{,}, sort keys %{ $_->{plates} } ) for values %stash;
    
    return [ values %stash ];   
}

sub add_descendant_data {
    my ( $stash, $well ) = @_;
    
    for my $d ( descendants_for( $well ) ) {
        my $recovery_plate = $d->plate->plate_data_value( 'alternate_clone_recovery' ) || '';
        if ( $recovery_plate eq 'yes' ) {
            $stash->{plates}{ $d->plate->name }++;
        }
        my $dna_status = $d->well_data_value( 'DNA_STATUS' ) || '';
        if ( $dna_status eq 'pass' ) {
            $stash->{dna_pass}++;
        }
        if ( $d->plate->type eq 'EP' ) {
            $stash->{ep}++;
        }
        elsif ( $d->plate->type eq 'EPD' ) {
            my $distribute = $d->well_data_value( 'distribute' ) || '';
            $stash->{epd_distribute}++
                if $distribute eq 'yes';
        }
    }
}

sub init_stash {
    my $project = shift;
    return {
        plates          => {},
        mgi_gene_id     => $project->mgi_gene_id,
        marker_symbol   => $project->mgi_gene->marker_symbol,
        ensembl_gene_id => $project->mgi_gene->ensembl_gene_id,
        vega_gene_id    => $project->mgi_gene->vega_gene_id,
        sponsor         => $project->sponsor,
        dna_pass        => 0,
        ep              => 0,
        epd_distribute  => 0,
    };
}

sub descendants_for {
    my $well = shift;

    my @descendants = ( $well );
    for my $c ( $well->child_wells ) {
        push @descendants, descendants_for( $c );
    }

    return @descendants;
}

1;

__END__
