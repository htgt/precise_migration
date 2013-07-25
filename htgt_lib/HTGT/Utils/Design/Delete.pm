package HTGT::Utils::Design::Delete;

use strict;
use warnings FATAL => 'all';

use Carp 'confess';
use Log::Log4perl ':easy';

use Sub::Exporter -setup => {
    exports => [ qw( delete_design delete_design_by_id ) ]
};

sub delete_design_by_id {
    my ( $htgt, $design_id ) = @_;
    
    my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } )
        or confess "Failed to retrieve design $design_id";

    delete_design( $design );
}

sub delete_design {
    my $design = shift;

    confess "Cannot delete design with design instances"
        if $design->design_instances_rs->count > 0;

    confess "Cannot delete design that has been allocated to a project"
        if $design->projects_rs->count > 0;       

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
        
    my $design_parameter_count = $design->search_related_rs( 'design_parameter' )->delete;
    notify( 'design_parameter', $design_parameter_count );
        
    if ( $design->delete ) {
        notify( 'design', 1 );
        INFO( "Deleted design " . $design->design_id );
    }
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

HTGT::Utils::Design::Delete

=head1 SYNOPSIS

  use HTGT::DBFactory;
  use HTGT::Utils::Design::Delete qw( delete_design delete_design_by_id );
  use Log::Log4perl ':levels';

  Log::Log4perl->easy_init( $INFO );

  my $htgt = HTGT::DBFactory->connect( "eucomm_vector" );

  my $design_id = 1234;

  # Retrieve the design and delete it (and associated data):

  my $design    = $htgt->resultset( 'Design' )->find( { design_id => $design_id } );
  delete_design( $design );

  # ...or let the module retrieve the HTGTDB::Design object for you:

  delete_design_by_id( $htgt, $design_id );

=head1 DESCRIPTION

Utility module providing methods to delete a design (and associated
data) from the HTGT database. The exported functions do not do any
transaction processing - this is left to the caller. This module uses
Log::Log4perl to log progress; the caller should initialize the
Log::Log4perl framework before using these utility functions.

=head1 EXPORTS

=over

=item  delete_design( $design )

Delete the given L<HTGTDB::Design> object and associated data.

=item  delete_design_by_id( $design_id )

Delete design and associated data.

=back

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
