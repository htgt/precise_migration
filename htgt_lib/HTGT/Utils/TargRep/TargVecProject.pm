package HTGT::Utils::TargRep::TargVecProject;

use Moose::Role;
use HTGT::Constants;
use namespace::autoclean;

requires qw( htgt_schema log );

has ambiguous_targ_vecs => (
    is         => 'ro',
    isa        => 'HashRef',
    traits     => [ 'Hash' ],
    handles    => {
        is_ambiguous_targ_vec => 'exists'
    },
    lazy_build => 1
);

sub _build_ambiguous_targ_vecs {
    my $self = shift;

    $self->htgt_schema->storage->dbh_do(
        sub {
            $_[1]->selectall_hashref( <<'EOT', 'pgdgr_well_id' );
select pgdgr_well_id
from new_well_summary
where pgdgr_well_id is not null
group by pgdgr_well_id
having count(distinct project_id) > 1
EOT
        }
    );    
}

sub project_for_targ_vec {
    my ( $self, $new_well_summary_row ) = @_;

    confess "Row has no targeting vector defined"
        unless $new_well_summary_row->pgdgr_well_id;

    return $new_well_summary_row->project
        unless $self->is_ambiguous_targ_vec( $new_well_summary_row->pgdgr_well_id );

    my $targ_vec_well = $new_well_summary_row->pgdgr_well;    
    
    my $wanted_sponsor = $self->_sponsor_for( $targ_vec_well )
        or confess "Failed to determine sponsor for $targ_vec_well";
    
    my $wanted_sponsor_col = $HTGT::Constants::SPONSOR_COLUMN_FOR{ $wanted_sponsor }
        or confess "Failed to determine sponsor column for $wanted_sponsor";    

    my @projects = $self->htgt_schema->resultset( 'Project' )->search(
        {
            "me.$wanted_sponsor_col"       => 1,
            'new_ws_entries.pgdgr_well_id' => $targ_vec_well->well_id
        },
        {
            join     => 'new_ws_entries',
            distinct => 1
        }
    );

    confess 'Found ' . @projects . ' candidate projects for ' . $targ_vec_well
        unless @projects == 1;

    $self->log->debug( sub { sprintf( 'Well summary project %s (%s), returning %d (%s)',
                                      $new_well_summary_row->project->project_id,
                                      $new_well_summary_row->project->sponsor,
                                      $projects[0]->project_id,
                                      $projects[0]->sponsor )
                         } );
    return $projects[0];
}

sub _sponsor_for {
    my ( $self, $well ) = @_;

    return $well->well_data_value( 'sponsor' )
        || $well->plate->plate_data_value( 'sponsor' )
            || ( $well->parent_well_id && $self->_sponsor_for( $well->parent_well ) )
                || ();
}

1;

__END__

