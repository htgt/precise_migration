#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/trunk/lib/HTGT/Utils/AllocateDesignsToPlate.pm $
# $LastChangedRevision: 6837 $
# $LastChangedDate: 2012-02-23 12:32:32 +0000 (Thu, 23 Feb 2012) $
# $LastChangedBy: rm7 $
#
package HTGT::Utils::AllocateDesignsToPlate;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => {
    exports => [ 'allocate_designs_to_plate' ]
};

use HTGT::Utils::DesignPhase;
use HTGT::Utils::Plate::Create;
use Const::Fast;

const my $DESIGNS_PER_ROW   => 12;
const my $ROWS_PER_PLATE    => 8;
const my $DESIGNS_PER_PLATE => $ROWS_PER_PLATE * $DESIGNS_PER_ROW;

sub allocate_designs_to_plate {
    my ( $plate_name, $designs ) = @_;

    # group_designs_by_phase() returns a list of lists of designs,
    # each sublist containing desgins of the same phase.

    my @phase_groups = group_designs_by_phase( $designs );

    my @allocate_to_plate;

    # We sort by number of elements in the list so that we always
    # start with the largest set. This ensures that, if there are 96
    # designs of the same phase, they will all end up on the same
    # plate.
     
    for my $phase_group ( sort_by_num_elements( @phase_groups ) ) {
        # While we have a full row of designs of this phase, allocate
        # to the plate. When we don't have enough designs to fill a
        # row, move on to the next phase.
        while ( @allocate_to_plate < $DESIGNS_PER_PLATE and @{$phase_group} >= $DESIGNS_PER_ROW ) {
            push @allocate_to_plate, splice @{$phase_group}, 0, $DESIGNS_PER_ROW;
        }
        last if @allocate_to_plate >= $DESIGNS_PER_PLATE;
    }

    # If we haven't filled the plate, we know we can't fill complete
    # rows with designs of the same phase, but we sort what's left
    # by number of elements and put as many designs of the same phase
    # as possible into each row.
    my @unallocated = map { @{$_} } sort_by_num_elements( @phase_groups );

    while ( @unallocated and @allocate_to_plate < $DESIGNS_PER_PLATE ) {
        push @allocate_to_plate, shift @unallocated;
    }

    my $it = HTGT::Utils::Plate::Create::well_name_iterator( $DESIGNS_PER_PLATE );    
    for my $allocated ( @allocate_to_plate ) {
        $allocated->update( { final_plate => $plate_name, well_loc => $it->value } );        
    }    
    
    for my $unallocated ( @unallocated ) {
        $unallocated->update( { final_plate => undef, well_loc => undef } );        
    }
}

sub sort_by_num_elements {
    reverse sort { scalar @{$a} <=> scalar @{$b} } @_;
}

sub group_designs_by_phase {
    my $designs = shift;

    my %by_phase;

    for my $design ( @{ $designs } ) {
        unless ( defined $design->phase ) {
            HTGT::Utils::DesignPhase::compute_and_set_phase( $design );
        }
        push @{ $by_phase{ $design->phase } }, $design;
    }

    return values %by_phase;
}

1;

__END__
