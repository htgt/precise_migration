package HTGT::Utils::Plate::Delete;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-plate/trunk/lib/HTGT/Utils/Plate/Delete.pm $
# $LastChangedRevision: 7425 $
# $LastChangedDate: 2012-06-27 16:20:44 +0100 (Wed, 27 Jun 2012) $
# $LastChangedBy: mqt $

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'delete_plate' ] };
use Log::Log4perl ':easy';
use Readonly;

Readonly my @WELL_RELATIONS => qw(
                                     well_data
                                     primer_reads
                                     design_instance_jump
                                     pc_primer_reads
                                     repository_qc_result
                                     user_qc_result          
                                     grc_alt_clone_chosen    
                                     grc_alt_clone_alternate 
                                     grc_gateway             
                                     grc_redesign            
                                     gr_redesign             
                                     gr_gateway              
                                     gr_alt_clone
                             );

Readonly my @PLATE_RELATIONS => qw(
                                      plate_comments
                                      plate_data
                                      plate_blobs
                                      parent_plate_plates
                              );

sub delete_plate {
    my ( $plate, $deleted_by ) = @_;

    die "Cannot delete plate with child plates\n"
        if $plate->child_plates > 1;    

    DEBUG( "Deleting plate " . $plate->name );

    my %design_instance_ids;
    
    DEBUG( "Deleting related new_well_summary rows" );
    my $count = $plate->result_source->schema->resultset( 'NewWellSummary' )->search(
        {
            -or => [
                design_plate_name => $plate->name,
                pcs_plate_name    => $plate->name,
                pgdgr_plate_name  => $plate->name,
                dna_plate_name    => $plate->name,
                ep_plate_name     => $plate->name,
                epd_plate_name    => $plate->name,
                fp_plate_name     => $plate->name
            ]
        }            
    )->delete;
    INFO( "Deleted $count rows from new_well_summary" );
    
    for my $well ( $plate->wells ) {

        DEBUG( "Deleting $well and associated data" );
        
        for my $rel ( @WELL_RELATIONS ) {
            DEBUG( "Deleting $rel" );
            my $count = $well->search_related( $rel, {} )->delete;            
            INFO( "Deleted $count $rel rows" ) if $count > 0;
        }

        $design_instance_ids{ $well->design_instance_id }++
            if $well->design_instance_id;

        $well->delete;
        INFO( "Deleted $well" );
    }

    for my $rel ( @PLATE_RELATIONS ) {
        DEBUG( "Deleting $rel" );
        my $count = $plate->search_related( $rel, {} )->delete;        
        INFO( "Deleted $count $rel rows" ) if $count > 0;
    }

    if ( $plate->type eq 'DESIGN' ) {
        my $schema = $plate->result_source->schema;
        my $design_instance_ids = [ keys %design_instance_ids ];
        _delete_design_instance_bac( $schema, $design_instance_ids );
        _update_project( $schema, $design_instance_ids );
        _update_design_status( $schema, $design_instance_ids );        
        _delete_design_instance( $schema, $design_instance_ids );
        _update_final_plate_and_well_loc( $schema, $plate->name );
    }

    $plate->update( { edited_user => $deleted_by, edited_date => \'current_timestamp' } );
    $plate->delete;
    INFO( "Deleted plate $plate" );
    
    return $plate->name;
}

sub _update_final_plate_and_well_loc {
    my ( $schema, $plate_name ) = @_;

    $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;

            $dbh->do('update design set final_plate = null, well_loc = null where final_plate = ?', undef, $plate_name);
        }
    );

    return;
}

sub _delete_design_instance_bac {
    my ( $schema, $design_instance_ids ) = @_;

    DEBUG( "Deleting design_instance_bacs" );
    
    my $count = $schema->resultset( 'DesignInstanceBAC' )->search(
        {
            design_instance_id => $design_instance_ids
        }
    )->delete;
    INFO( "Deleted $count design_instance_bac rows" );
}

sub _update_project {
    my ( $schema, $design_instance_ids ) = @_;

    DEBUG( "Updating projects" );
    
    my $project_rs = $schema->resultset( 'Project' )->search(
        {
            design_instance_id => $design_instance_ids
        }
    );

    while ( my $project = $project_rs->next ) {
        $project->update(
            {
                project_status_id  => 10,
                design_instance_id => undef,
                design_plate_name  => undef,
                design_well_name   => undef
            }
        );
        INFO( "Updated project " . $project->project_id );
    }
}

sub _update_design_status {
    my ( $schema, $design_instance_ids ) = @_;

    DEBUG( "Updating design status" );    

    my @design_ids = map $_->design_id, $schema->resultset( 'DesignInstance' )->search(
        {
            design_instance_id => $design_instance_ids
        },
        {
            columns  => [ 'design_id' ],
            distinct => 1
        }
    );

    DEBUG( "Design ids: " . join q{, }, @design_ids );    

    # For each design, roll back the design status to 'Ready to order' *provided* there are
    # no projects for that design more advanced than 'Desgin Completed'
    
    for my $design_id ( @design_ids ) {
        my $count = $schema->resultset( 'Project' )->search(
            {
                'design_id'       => $design_id,
                'status.order_by' => { '>', 50 } # '50 == Design Completed'
            },
            {
                join => 'status'
            }
        )->count;
        DEBUG( "Found $count projects for design $design_id more advanced than Design Completed" );
        next unless $count == 0;
        
        my $current_status = $schema->resultset( 'DesignStatus' )->search(
            {
                design_id  => $design_id,
                is_current => 1
            }
        )->first;

        DEBUG( "Current design_status: " . ( $current_status ? $current_status->design_status_dict->description : '<undef>' ) );

        unless ( $current_status and $current_status->design_status_id == 10 ) {
            my $mesg = sprintf( "Unexpected design_status '%s' for design %d",
                                $current_status->design_status_dict->description, $design_id );
            ERROR( $mesg );
            die $mesg;
        }
        
        DEBUG( "Updating current design_status to 'Ready to order'" );        

        $current_status->delete;        
        $schema->resultset( 'DesignStatus' )->update_or_create(
            {
                design_id        => $design_id,
                design_status_id => 8, # 'Ready to order'
                is_current       => 1
            }
        );
    }
}           

sub _delete_design_instance {
    my ( $schema, $design_instance_ids ) = @_;

    my $count = $schema->resultset( 'DesignInstance' )->search( { design_instance_id => $design_instance_ids } )->delete;
    INFO( "Deleted $count design_instance rows" );
}

1;

__END__
    
    my @design_ids = 
