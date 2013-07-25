package HTGT::Utils::AlterParentWell;

#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt/trunk/lib/HTGT/Utils/AlterParentWell.pm $
# $LastChangedDate: 2010-11-03 11:02:19 +0000 (Wed, 03 Nov 2010) $
# $LastChangedRevision: 3175 $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';
use DateTime;

sub alter_parent_well {
    my ( $well, $new_parent_well, $edit_user ) = @_;
    ### alter parent well: "$well"
    my $plate = $well->plate;
    my $count = 0;

    die "reparenting of this well not allowed\n" unless ( $plate->type =~ qr/^(EP|EPD|REPD|FP)$/ );

    # update the well parent well id & design instance id

    if (   $new_parent_well->well_id != $well->parent_well_id
        or $new_parent_well->design_instance_id != $well->design_instance_id )
    {
        $well->update(
            {   parent_well_id     => $new_parent_well->well_id,
                design_instance_id => $new_parent_well->design_instance_id,
                edit_user          => $edit_user,
                edit_date          => \'current_timestamp'
            }
        );

        $count += 1;

        # update child wells design instance id
        foreach my $child ( $well->child_wells ) {
            $count += alter_parent_well( $child, $well, $edit_user );
        }
    }
    else {
        warn "no update\n";
    }

    return $count;
}

1;
