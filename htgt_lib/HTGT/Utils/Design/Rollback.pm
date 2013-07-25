package HTGT::Utils::Design::Rollback;

use strict;
use warnings FATAL => 'all';

use Carp 'confess';
use Log::Log4perl ':easy';

use Sub::Exporter -setup => {
    exports => [ qw( rollback_design rollback_design_by_id ) ]
};

sub rollback_design_by_id {
    my ( $htgt, $design_id ) = @_;
    
    my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
        or confess "Failed to retrieve design $design_id";

    rollback_design( $design );
}

sub rollback_design {
    my $design = shift;
    
    confess "Cannot rollback design with design instances"
        if $design->design_instances_rs->count > 0;

    confess "Cannot rollback design that has been allocated to a project"
        if $design->projects_rs->count > 0;

    my $htgt = $design->result_source->schema;
    
    my $created_status = $htgt->resultset( 'HTGTDB::DesignStatusDict' )->find( { description => 'Created' } )
        or confess "failed to retrieve 'Created' design_status_dict entry";

    my $note_type = $htgt->resultset( 'HTGTDB::DesignNoteTypeDict' )->find( { description => 'Info' } )
        or confess "failed to retrieve 'Info' design_note_type_dict entry";
    
    my ( $feature_data_count, $display_feature_count ) = ( 0, 0 );
    for my $feature ( $design->features ) {
        $feature_data_count += $feature->feature_data_rs->delete;
        $display_feature_count += $feature->display_features_rs->delete;
    }
    notify( 'feature_data', $feature_data_count );
    notify( 'display_features', $display_feature_count );

    for ( qw( features design_notes design_bacs statuses design_user_comments design_design_group ) ) {
        my $rs = $_ . '_rs';
        my $count = $design->$rs->delete;
        notify( $_, $count );
    }
        
    $design->design_statuses_rs->create(
        {
            design_status_id => $created_status->design_status_id,
            is_current       => 1
        }
    );
    INFO( "Created design_status" );

    $design->design_notes_rs->create(
        {
            design_note_type_id => $note_type->design_note_type_id,
            note                => 'Created'
        }
    );
    INFO( "Created design_note" );
}

sub notify {
    my ( $table, $count ) = @_;
    return unless $count > 0;
    INFO( sprintf "Deleted %d row%s from %s", $count, ($count == 1 ? "" : "s"), $table );
}

1;

__END__

=pod

=head1 NAME

HTGT::Utils::Design::Rollback

=head1 SYNOPSIS

  use HTGT::DBFactory;
  use HTGT::Utils::Design::Rollback qw( rollback_design rollback_design_by_id );
  use Log::Log4perl ':levels';

  Log::Log4perl->easy_init( $INFO );

  my $htgt = HTGT::DBFactory->connect( "eucomm_vector" );

  my $design_id = 1234;

  # Retrieve the design and delete it (and associated data):

  my $design    = $htgt->resultset( 'Design' )->find( { design_id => $design_id } );
  rollback_design( $design );

  # ...or let the module retrieve the HTGTDB::Design object for you:

  rollback_design_by_id( $htgt, $design_id );

=head1 DESCRIPTION

Utility module providing methods to rollback a design to "Created"
status in the HTGT database. This is useful, for example, if a design
suffers a computational failure: the design can be rolled back into
"Created" state and the farm computation redone.  The exported
functions do not do any transaction processing - this is left to the
caller. This module uses Log::Log4perl to log progress; the caller
should initialize the Log::Log4perl framework before using these
utility functions.

=head1 EXPORTS

=over

=item  rollback_design( $design )

Rollback the given L<HTGTDB::Design>. Feature data populated during
the computation step, notes, comments, and statuses are deleted from
the database. A single status row (with status "Created") is
re-inserted along with an informational note.

=item  rollback_design_by_id( $design_id )

Rollback design and associated data.

=back

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
