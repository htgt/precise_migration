package HTGT::Utils::ResetPlateParentageAndQC;

use strict;
use warnings FATAL => 'all';

use Sub::Exporter -setup => { exports => [ 'reset_plate_parentage_and_qc', 'validate_384_plate_for_well_parentage_reset' ] };
use Log::Log4perl ':easy';
use List::MoreUtils qw( uniq );

sub reset_plate_parentage_and_qc {
    my ( $plate_name, $parent_plate_name, $schema ) = @_;

    my $parent_plate = $schema->resultset('Plate')->find( { name => $parent_plate_name } );

    die "Non existant parent plate ($parent_plate_name)" unless $parent_plate;

    my @plates = $schema->resultset('Plate')->search(
        {
            'me.name' => { 'like' => '%' . $plate_name . '%' },
            'well_data.data_type' =>
              [qw/clone_name distribute pass_level qctest_result_id/],
        },
        { 'prefetch' => { 'wells' => 'well_data' } },
    );
    
    die "Could not find plate ($plate_name) with relevent qc results in well_data" unless @plates;

    my $well_data_count = 0;
    my $parent_wells_rs = $parent_plate->wells;

    for my $plate ( @plates ) {
        my $wells_rs = $plate->wells;
        while ( my $well = $wells_rs->next ) {
            my $well_data_rs = $well->well_data;
            while ( my $well_data = $well_data_rs->next ) {
                $well_data->delete;
                $well_data_count++;
            }
            INFO("Delete qc well data for: $well" );
            
            # find the parent well (i.e. well with the same name)
            my @parent_well = $parent_wells_rs->search( { well_name => $well->well_name } );
            
            die "Could not find parent well for (" . $well->well_name . ")"
                unless @parent_well;
            die "Too many parent wells for (" . $well->well_name . ")"
                if scalar(@parent_well) > 1;

            my $parent_well = shift @parent_well;

            # update parent_well_id and design_instance_id
            $well->update(
                {
                    parent_well_id     => $parent_well->well_id,
                    design_instance_id => $parent_well->design_instance_id,
                }
            );
            INFO("Updated parent well for: $well");
        }
    }

    INFO( "Deleted ($well_data_count) rows from HTGTDB::WellData");
    return 1;
}


#Check the 384 well plate is suitable for a well parentage reset
#and return the parent plate
sub validate_384_plate_for_well_parentage_reset {
    my ( $plate, $errors, $schema ) = @_;
    my ( @parent_plates, @cassettes, @backbones );
    
    my @child_plate = $plate->child_plates_from_child_wells;
    if (@child_plate) {
        push @{ $errors }, "Plate ($plate) already has qc and the following child plates:";
        push @{ $errors }, map { $_->name } @child_plate;
        return;
    }
    
    my $plate_name = $plate->name;
    $plate_name =~ s/\d+$//;
    
    my $plate_iterates_rs = $schema->resultset( 'Plate' )->search(
        {
            name => { 'like' => $plate_name . '%' }
        },
        {
            distinct => 1
        }
    );
    
    #allow reparent only if all plate iterates _1, _2 .. _4 / _8 have same parent plate and all wells
    #have same cassette and backbone
    while ( my $plate_iterate = $plate_iterates_rs->next ) {
        push @parent_plates, map { $_->name } $plate_iterate->parent_plates_from_parent_wells->all;
        push @cassettes, uniq map { $_->well_data_value('cassette') } $plate_iterate->wells->all;
        push @backbones, uniq map { $_->well_data_value('backbone') } $plate_iterate->wells->all;
    }

    if (  scalar( uniq @parent_plates) > 1) {
        push @{ $errors }, "Plate ($plate) has qc and multiple parent plates, cannot reparent";
        return 0;
    }
    
    if ( scalar( uniq @cassettes) > 1) {
        push @{ $errors }, "Plate ($plate) has qc and wells have different cassettes, cannot reparent";
        return 0;
    }

    if ( scalar( uniq @backbones) > 1 ) {
        push @{ $errors }, "Plate ($plate) has qc and wells have different backbones, cannot reparent";
        return 0;
    }
    return shift @parent_plates;
}

1;

__END__
