# RecomReport
#
# Author: Lucy Stebbings (las)
#

package RecomReport;

use Exporter;

use strict;
use SqlEngine2;

#use lib '/usr/local/badger/bin/vector_production/src/vector_production/perl/modules/TargetedTrap';

#$ENV{DOTFONTPATH} = '/usr/lib/X11/fonts/Type1';

use TargetedTrap::GTRAP;		# my subclass of GTx
use TargetedTrap::BTRAP;		# api for the bio database
use TargetedTrap::VTRAP;		# api for the bio database
use Checkbarcode2;
use GraphViz;

#use constant FONT =>  'courb';
use constant FONT =>  'helvetica';
#use constant FONTSIZE =>  '12';
use constant FONTSIZE =>  '10';

#-------------------------------------------------------------------------------------------------------#
#
# Constructor
#
sub new {
    my $class = shift;
    my %args = @_;

    my $self = {};

    bless $self, $class;

    if ($args{-test}) { $self->{testdb} = 1; }

    # set up access to the generitrack api
    if ($args{-api}) {
	$self->{api} = $args{-api};
    }
    else {
	if ($args{-test}) { $self->{api} = new GTRAP(-login => GTRAP::LOGINTEST); }
	else { $self->{api} = new GTRAP(-login => GTRAP::LOGINLIVE); }
    }
    # set up access to the bio api
    if ($args{-TRAPapi}) {
	$self->{TRAPapi} = $args{-TRAPapi}; 
    }
    else {
	if ($args{-test}) { $self->{TRAPapi} = new BTRAP(-login => BTRAP::TRAP_LOGIN_TEST); }
	else { $self->{TRAPapi} = new BTRAP(-login => BTRAP::TRAP_LOGIN_LIVE); }
    }
    # set up access to the vector design database api
    if ($args{-VTRAPapi}) {
	$self->{VTRAPapi} = $args{-VTRAPapi};
    }
    else {
	if ($args{-test}) { $self->{VTRAPapi} = new VTRAP(-login     => VTRAP::LOGIN,
					     -TRAPlogin => BTRAP::TRAP_LOGIN_TEST); }
	else { $self->{VTRAPapi} = new VTRAP(-login     => VTRAP::LOGIN_LIVE,
					     -TRAPlogin => BTRAP::TRAP_LOGIN_LIVE); }
    }

    if ($args{-plate}) { $self->plate($args{-plate}); }


    return $self;
}

#--------------------------------------------------------------------------------------#
sub plate {
    my $pkg = shift;

    $pkg->{plate} = shift if @_;
    return($pkg->{plate});
}
#--------------------------------------------------------------------------------------#
# takes a plate_id from a Team87 Recombineering experiment eg 7

# return an array of arrays
# or 0 if the plate is not valid
# first entry is an array of the column headings
# subsequent entries are arrays of data, each relates to a well position on a plate

sub getDetails {

    my $pkg = shift;

    # get all the vector design and MIG data
    $pkg->{designs_object} = new designs(-se    => $pkg->{VTRAPapi}->se(),
					 -dbh   => $pkg->{VTRAPapi}->dbh(),
					 -plate => $pkg->{plate});

    # check the plate is complete and get a list of designs
    unless ($pkg->{designs_object}->checkPlate('skip well check')) { 
	print "plate not valid\n"; 
	return(0); 
    }

    # get the gene and exon information
    $pkg->{designs_object}->getGeneExon();


    # get a list of the designs
    my $designs = $pkg->{designs_object}->designs();

    # go through the list of designs and get the important well information out
    foreach my $design(@$designs) {
        # format the wells as required (A1 not A01)

	my $well = uc($pkg->{designs_object}->designWell($design));
#	print "$design well $well\n";

	$pkg->{wells}->{$well}->{name} = $design;
	$pkg->{wells}->{$well}->{gene} = $pkg->{designs_object}->designGene($design);
	$pkg->{wells}->{$well}->{phase} = $pkg->{designs_object}->designPhase($design);
	$pkg->{wells}->{$well}->{exon} = $pkg->{designs_object}->designExon($design);
    }
    # dont need the design object anymore
    $pkg->{designs_object} = undef;

    # get a hash of all the plate peIds related to this recombineering experiment
    my $all_plates = $pkg->{api}->getRecomRelatedPlates(-hrId => $pkg->{plate});

    # go through all the plates and get their wells
    # put the data into useful shaped hashes
    foreach my $plate(keys %$all_plates) {

	$pkg->{plates}->{$plate}->{type} = $all_plates->{$plate};

        # get all the well details
	my $all_wells = $pkg->{api}->getWells(-entityType => $all_plates->{$plate},
					      -peId       => $plate);
	foreach my $well(keys %$all_wells) {
	    # swap over to A01 well format from A1 (makes it sort properly later)
	    my $new_well = $well;
	    if ($well =~ /^(.)(.)$/) { $new_well = $1 . '0' . $2; }
	    $pkg->{plates}->{$plate}->{wells}->{$new_well} = $all_wells->{$well};
	}

        # for some of the plate types we want some extra information...

	if ($all_plates->{$plate} == GTx::ENT_TYPE_BAC) {

	    my $iteration = $pkg->{api}->getAttributeValue(-idPe          => $plate,
							   -attributeType => GTx::ATT_TYPE_GENETRAP_ITERATION,
							   -reason        => GTx::REASON_ATTRIBUTE);

	    # keep bac plate id and type and iteration
	    if ($iteration && ($iteration eq 'a')) {
		$pkg->{BAC_plate_a} = [$plate, $all_plates->{$plate}, '', $iteration];
	    }
	    elsif ($iteration && ($iteration eq 'b')) {
		$pkg->{BAC_plate_b} = [$plate, $all_plates->{$plate}, '', $iteration];
	    }
	    elsif ($iteration && ($iteration eq 'c')) {
		$pkg->{BAC_plate_c} = [$plate, $all_plates->{$plate}, '', $iteration];
	    }
	    elsif ($iteration && ($iteration eq 'd')) {
		$pkg->{BAC_plate_d} = [$plate, $all_plates->{$plate}, '', $iteration];
	    }
	    unless ($iteration) {
		$pkg->{BAC_plate_a} = [$plate, $all_plates->{$plate}, '', 'a'];
	    }
	}
	elsif ($all_plates->{$plate} == GTx::ENT_TYPE_GENETRAP_REC_R) {

	    # get the id_se on the A01 well of the BAC R plates so can work out the chain
#	    $pkg->{BAC_R_A01_idSe} = $pkg->{plates}->{$plate}->{wells}->{A01}->{idSe};

	    # keep bac R plate id, type and idSe on well A01
            push @{$pkg->{BAC_R_plate}}, [$plate, $all_plates->{$plate}, $pkg->{plates}->{$plate}->{wells}->{A01}->{idSe}];
	}
	elsif ($all_plates->{$plate} == GTx::ENT_TYPE_PCR) {
 
           # get the PCR type
	    my $pcr_type = $pkg->{api}->GTRAPpcr::getPCRPlateType(-idPe => $plate);
	    if ($pcr_type eq 'U') {
		$pkg->{PCR_U_plate} = [$plate, $all_plates->{$plate}, '', 'U'];
	    }
	    elsif ($pcr_type eq 'D') {
		$pkg->{PCR_D_plate} = [$plate, $all_plates->{$plate}, '', 'D'];
	    }
	    elsif ($pcr_type eq 'G') {
		$pkg->{PCR_G_plate} = [$plate, $all_plates->{$plate}, '', 'G'];
	    }
	}
    }

    $all_plates = undef;

    # put the PCR and BAC plates onto the plate list array in the correct order
    push @{$pkg->{plate_chain}}, $pkg->{BAC_plate_a} if ($pkg->{BAC_plate_a});
    push @{$pkg->{plate_chain}}, $pkg->{BAC_plate_b} if ($pkg->{BAC_plate_b});
    push @{$pkg->{plate_chain}}, $pkg->{BAC_plate_c} if ($pkg->{BAC_plate_c});
    push @{$pkg->{plate_chain}}, $pkg->{BAC_plate_d} if ($pkg->{BAC_plate_d});
    foreach (@{$pkg->{BAC_R_plate}}) { push @{$pkg->{plate_chain}}, $_; }
    push @{$pkg->{plate_chain}}, $pkg->{PCR_U_plate};
    push @{$pkg->{plate_chain}}, $pkg->{PCR_D_plate};
    push @{$pkg->{plate_chain}}, $pkg->{PCR_G_plate};

    # work out the chain of wells and what plate they are on, hence gives you the chain of plates
    foreach my $bacrplate(@{$pkg->{BAC_R_plate}}) {

	my $BAC_R_A01_idSe = $bacrplate->[2];

	my $rec_u_ec_ids = $pkg->{api}->getEcToEc(-ecId => $BAC_R_A01_idSe);

	foreach my $entry(@$rec_u_ec_ids) {
	    my $next_ec = $entry->[0];
	    my $next_plate_type = $entry->[1];
	    my $next_plate = $entry->[2];

	    push @{$pkg->{plate_chain}}, [$next_plate, $next_plate_type];

	    my $rec_d_ec_ids = $pkg->{api}->getEcToEc(-ecId => $next_ec);

	    foreach my $entry(@$rec_d_ec_ids) {
		my $next_ec = $entry->[0];
		my $next_plate_type = $entry->[1];
		my $next_plate = $entry->[2];
		push @{$pkg->{plate_chain}}, [$next_plate, $next_plate_type];

		my $rec_g_ec_ids = $pkg->{api}->getEcToEc(-ecId => $next_ec);

		foreach my $entry(@$rec_g_ec_ids) {
		    my $next_ec = $entry->[0];
		    my $next_plate_type = $entry->[1];
		    my $next_plate = $entry->[2];
		    push @{$pkg->{plate_chain}}, [$next_plate, $next_plate_type];

		    my $rec_gd_ec_ids = $pkg->{api}->getEcToEc(-ecId => $next_ec);

		    foreach my $entry(@$rec_gd_ec_ids) {
			my $next_ec = $entry->[0];
			my $next_plate_type = $entry->[1];
			my $next_plate = $entry->[2];
			push @{$pkg->{plate_chain}}, [$next_plate, $next_plate_type];
		    
			my $rec_pc_ec_ids = $pkg->{api}->getEcToEc(-ecId => $next_ec);

			foreach my $entry(@$rec_pc_ec_ids) {
			    my $next_ec = $entry->[0];
			    my $next_plate_type = $entry->[1];
			    my $next_plate = $entry->[2];
			    push @{$pkg->{plate_chain}}, [$next_plate, $next_plate_type];
			}
		    }
		}
	    }
	}
    }
    
    # get the int_id and text version of barcode for each of the plates 
    foreach my $entry(@{$pkg->{plate_chain}}) {
	my $pe_id = $entry->[0];
	my $type = $entry->[1];
	next unless ($pe_id);
	my $int_id = $pkg->{api}->getAttributeValue(-idPe          => $pe_id,
						    -attributeType => GTx::ATT_TYPE_INT_ID,
						    -reason        => GTx::REASON_ATTRIBUTE);
	next unless ($int_id);
	my $prefix;
	if ($type == GTx::ENT_TYPE_BAC) { $prefix = 'ZG'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_R) { $prefix = 'RR'; }
	elsif ($type == GTx::ENT_TYPE_PRIMER) { $prefix = 'ZP'; }
	elsif ($type == GTx::ENT_TYPE_PCR) { $prefix = 'ZC'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_U) { $prefix = 'RU'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_D) { $prefix = 'RD'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_G) { $prefix = 'RG'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_GD) { $prefix = 'RN'; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_PC) { $prefix = 'RC'; }
#	else { print "type $type\n"; }
	my $to_check = $prefix . $int_id;
	my $check = Checkbarcode2::makeCheck($to_check);
	if ($check) { $entry->[2] = $to_check . $check; }
	else { $entry->[2] = $to_check; }
    }

    # format the data into an array of arrays
    my @data = &format_details($pkg);

    if (@data) { return(@data); }

    return(0);
}

#--------------------------------------------------------------------------------------#
sub format_details {

    my $pkg = shift;

    # gene_id, exon_id, phase, vector (EUCTV00345), plate, well_loc, BAC growth (B00008 - bc code?), BAC-R growth (BR00008 - bc-code?),[ PCR U growth, D, G, recom U, D, G, GD, PC, Failed? (failed)]

    my @data;

    # lay out the headers appropriately

    push @{$data[0]}, ('Name', 'Gene ID', 'Phase', 'Exon ID', 'Well');

    foreach my $entry(@{$pkg->{plate_chain}}) {
	my $type = $entry->[1];
	my $bc = $entry->[2];

	next unless ($type && $bc);

#	print "$type $bc\n";
	if (($type == GTx::ENT_TYPE_BAC) && ($entry->[3] eq 'a')) { push @{$data[0]}, "BACa $bc"; }
	elsif (($type == GTx::ENT_TYPE_BAC) && ($entry->[3] eq 'b')) { push @{$data[0]}, "BACb $bc"; }
	elsif (($type == GTx::ENT_TYPE_BAC) && ($entry->[3] eq 'c')) { push @{$data[0]}, "BACc $bc"; }
	elsif (($type == GTx::ENT_TYPE_BAC) && ($entry->[3] eq 'd')) { push @{$data[0]}, "BACd $bc"; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_R) { push @{$data[0]}, "BAC-R $bc"; }
	elsif (($type == GTx::ENT_TYPE_PCR) && ($entry->[3] eq 'U')) { push @{$data[0]}, "PCR-U $bc"; }
	elsif (($type == GTx::ENT_TYPE_PCR) && ($entry->[3] eq 'D')) { push @{$data[0]}, "PCR-D $bc"; }
	elsif (($type == GTx::ENT_TYPE_PCR) && ($entry->[3] eq 'G')) { push @{$data[0]}, "PCR-G $bc"; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_U) { push @{$data[0]}, "REC-U $bc"; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_D) { push @{$data[0]}, "REC-D $bc"; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_G) { push @{$data[0]}, "REC-G $bc"; }
	elsif ($type == GTx::ENT_TYPE_GENETRAP_PC) { push @{$data[0]}, "REC-PC $bc"; }
    }


    # print the data
    my $row = 1;
    foreach my $well(sort {$a cmp $b} keys %{$pkg->{wells}}) {

	my $name = $pkg->{wells}->{$well}->{name};
	my $gene = $pkg->{wells}->{$well}->{gene};
	my $phase = $pkg->{wells}->{$well}->{phase};
	my $exon = $pkg->{wells}->{$well}->{exon};

	push @{$data[$row]}, ($name, $gene, $phase, $exon, $well);

        # go through the plate chain array and print the growth/failed statuses
        # if the status is failed, the entry is '0'
        # if the growth is 1, the entry is '1'
        # otherwise the entry is 2
	foreach my $entry(@{$pkg->{plate_chain}}) {
	    my $plate = $entry->[0];
	    my $type = $entry->[1];
	    my $bc = $entry->[2];
	    my $failed = undef;

	    next unless ($type && $bc && $plate);

            # don't want the GD plate data displayed
	    next if ($type == GTx::ENT_TYPE_GENETRAP_REC_GD);

	    my $status = $pkg->{plates}->{$plate}->{wells}->{$well}->{status};
	    my $growth = $pkg->{plates}->{$plate}->{wells}->{$well}->{growth};
	    my $streak_growth = $pkg->{plates}->{$plate}->{wells}->{$well}->{streak_growth};

	    if ($type == GTx::ENT_TYPE_BAC) { $failed = GTRAPbac::GTRAP_STATUS_FAILED_BAC_WELL; }
	    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_R) { $failed = GTRAPrecR::GTRAP_STATUS_FAILED_REC_R_WELL; }
	    elsif ($type == GTx::ENT_TYPE_PCR) { $failed = GTRAPpcr::GTRAP_STATUS_FAILED_PCR_WELL; }
	    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_U) { $failed = GTRAPrecU::GTRAP_STATUS_FAILED_REC_U_WELL;}
	    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_D) { $failed = GTRAPrecD::GTRAP_STATUS_FAILED_REC_D_WELL;}
	    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_G) { $failed = GTRAPrecG::GTRAP_STATUS_FAILED_REC_G_WELL;}
	    elsif ($type == GTx::ENT_TYPE_GENETRAP_PC) { $failed = GTRAPpc::GTRAP_STATUS_FAILED_PC_WELL;}

	    my $entry = undef;
	    if ($status && ($status == $failed)) { $entry = "0"; }
	    elsif ($growth && ($growth == 1)) { $entry = "1"; }
	    elsif ($growth && ($growth == 2)) { $entry = "2"; }
	    if (($type == GTx::ENT_TYPE_GENETRAP_PC) && defined($streak_growth)) { $entry .= "\\" . $streak_growth; }

	    if (defined($entry)) { push @{$data[$row]}, $entry; }
	    else { push @{$data[$row]}, " "; }
	}
	$row++;
    }

    return (@data);
}
#--------------------------------------------------------------------------------------#
# takes a plate_id from a Team87 Recombineering experiment eg 7
# returns a string representing a JPEG image (shows plate transfers)
# or 0 if the plate is not valid

sub getPlateGraph {

    my $pkg = shift;
    my $type = shift;

    &getPlateDetails($pkg);

    my $image = &make_image($pkg, $type);

    return($image) if ($image);

    return(0);
}
#--------------------------------------------------------------------------------------#

sub getPlateDetails {
    my $pkg = shift;

    my ($all_plates, $plates) = &getPlateList($pkg); # gets all plates in the database plus an array of those with the required plate id

    my ($ecs, $plate2ecs) = &getWellList($pkg); # gets all wells on all plates in the database

    ($ecs) = &getWellToWellList($pkg, $ecs); # gets all links between wells in the database

    # get which plates link to which other plates via well to well transfers of samples
    ($plates) = &getPlateLinks($pkg, $all_plates, $plates, $ecs, $plate2ecs);

    # dump the full data set and just keep what we need ($plates)
    undef $all_plates;
    undef $ecs;
    undef $plate2ecs;

    # print out the data for testing purposes only
#    &printPlateData($plates);

    # gets pairs of plates and puts the details in the hash that make_image uses
    &getPairs($pkg, $plates);
}
#-----------------------------------------------------------------------------------#

sub getPlateList {
    my $pkg = shift;

    my $entities;
    my $all_plates;
    my $plates;

    if ($pkg->{testdb}) { $entities = $pkg->{api}->getEntityList('test'); }
    else { $entities = $pkg->{api}->getEntityList(); }

    # populate the all_plates hash
    # also find plates in the list that have the required human readable plate id
    my @plates;
    foreach my $entry(@$entities) {
	my $value = $entry->[0];
	my $id_attribute_type = $entry->[1];
	my $id_entity = $entry->[2];
	my $id_entity_type = $entry->[3];
	my $iteration = $entry->[4];

	next unless ($id_entity);

	if ($id_attribute_type == GTx::ATT_TYPE_INT_ID) { $all_plates->{$id_entity}->{int} = $value; }
	elsif ($id_attribute_type == GTx::ATT_TYPE_GENETRAP_ID) { $all_plates->{$id_entity}->{hr} = $value; }
	$all_plates->{$id_entity}->{id_entity_type} = $id_entity_type;
	$all_plates->{$id_entity}->{iteration} = $iteration;

	if (($id_attribute_type == GTx::ATT_TYPE_GENETRAP_ID) && ($value eq $pkg->{plate})) { push @plates, $id_entity; }
    }
    undef $entities;

    # initiate the plates hash with plates of the required hr id that have valid/current internal ids
    foreach my $plate(@plates) { if ($all_plates->{$plate}->{int}) { $plates->{$plate} = undef; } }

    return($all_plates, $plates);
}
#--------------------------------------------------------------------------------#

sub getWellList {
    my $pkg = shift;

    my $entity_contents;

    # get the entity_contents and the plates they are on into a hash
    if ($pkg->{testdb}) { $entity_contents = $pkg->{api}->getEntityContentsList('test'); }
    else { $entity_contents = $pkg->{api}->getEntityContentsList(); }

    my $ecs = {};
    my $plate2ecs = {};
    foreach my $entry(@$entity_contents) { 
	my $id_entity = $entry->[0];
	my $id_entity_content = $entry->[1];

	next unless ($id_entity && $id_entity_content);

	$ecs->{$id_entity_content}->{plate} = $id_entity; 
	$plate2ecs->{$id_entity}->{$id_entity_content} = 1;  
    }
    undef $entity_contents;

    return($ecs, $plate2ecs);
}
#--------------------------------------------------------------------------------#

sub getWellToWellList {
    my $pkg = shift;
    my $ecs = shift;

    # get a list of well to well links
    my $relations = $pkg->{api}->getEcToEcList();
    foreach my $entry(@$relations) {

	my $to_well = $entry->[0];
	my $from_well = $entry->[1];
	my $relation = $entry->[2];

	if ($relation == 12) { $ecs->{$to_well}->{arrayed_from}->{$from_well} = 1; }
	elsif ($relation == 16) { $ecs->{$to_well}->{derived_from}->{$from_well} = 1; }
	elsif ($relation == 8) { $ecs->{$to_well}->{requires}->{$from_well} = 1; }
	$ecs->{$from_well}->{to_well}->{$to_well} = 1;
    }
    undef $relations;
    return($ecs);
}
#--------------------------------------------------------------------------------#

sub getPlateLinks {
    my $pkg = shift;
    my $all_plates = shift;
    my $plates = shift;
    my $ecs = shift;
    my $plate2ecs = shift;

    my $done;

    while ((scalar(keys %$done)) != (scalar(keys %$plates))) {
  	foreach my $plate(keys %$plates) {
	    next unless ($plate);
	    next if ($done->{$plate});

	    # mark this plate as done
	    $done->{$plate} = 1;

	    $plates->{$plate}->{int} = $all_plates->{$plate}->{int};
	    $plates->{$plate}->{hr} = $all_plates->{$plate}->{hr};
	    $plates->{$plate}->{id_entity_type} = $all_plates->{$plate}->{id_entity_type};
	    $plates->{$plate}->{iteration} = $all_plates->{$plate}->{iteration};

	    # format the bubble labels and puts the details in the hash that make_image uses
	    &formatPlateDetails($pkg, $plate, $plates->{$plate}->{int}, $plates->{$plate}->{iteration}, $plates->{$plate}->{hr}, $plates->{$plate}->{id_entity_type});

	    # get any other plates that are linked to this one
	    $plates = &getFromToPlates($plate, $ecs, $plate2ecs, $plates, $all_plates);
	}
    }
    return($plates);
}
#--------------------------------------------------------------------------------#

# works out the shape and the text to go in the shape
sub formatPlateDetails {

    my $pkg = shift;
    my $idPe = shift;
    my $idInt = shift;
    my $iteration = shift;
    my $hr = shift;
    my $type = shift;

    return unless ($type && $idPe && $idInt && $hr);

    my ($prefix, $entity_type_label, $barcode);

    if ($type == GTx::ENT_TYPE_BAC)                { $prefix = 'ZG'; $entity_type_label = 'BAC'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_R)  { $prefix = 'RR'; $entity_type_label = 'BAC-R'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_PRIMER)          { $prefix = 'ZP'; $entity_type_label = 'OLIGO'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_U)  { $prefix = 'RU'; $entity_type_label = 'REC-U'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_D)  { $prefix = 'RD'; $entity_type_label = 'REC-D'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_G)  { $prefix = 'RG'; $entity_type_label = 'REC-G'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_REC_GD) { $prefix = 'RN'; $entity_type_label = 'REC-GD'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PC)     { $prefix = 'RC'; $entity_type_label = 'PC'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_CSO)    { $prefix = 'RX'; $entity_type_label = 'CSO'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PCS)    { $prefix = 'RS'; $entity_type_label = 'PCS'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PCD)    { $prefix = 'RV'; $entity_type_label = 'PCD'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PG)     { $prefix = 'RB'; $entity_type_label = 'GW'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_WSO)    { $prefix = 'RZ'; $entity_type_label = 'WSO'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PGS)    { $prefix = 'RT'; $entity_type_label = 'GWS'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PGD)    { $prefix = 'RW'; $entity_type_label = 'GWD'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_GENETRAP_PGA)    { $prefix = 'RA'; $entity_type_label = 'GWA'; $pkg->{idPe}->{$idPe}->{shape} = 'box'; }
    elsif ($type == GTx::ENT_TYPE_PCR)             { $prefix = 'ZC'; $entity_type_label = 'PCR'; 

        # if its a PCR plate, get the PCR plate type
# may be able to work out the PCR plate type from the preceeding oligo plates 
	$iteration = $pkg->{api}->GTRAPpcr::getPCRPlateType(-idPe => $idPe);

    }
    else { return; } # ie the plate type hasn't been understood

    # set the barcode
    my $to_check = $prefix . $idInt;
    my $check = Checkbarcode2::makeCheck($to_check);
    if ($check) { $barcode = $to_check . $check; }
    else { $barcode = $to_check; }

    if ($iteration) { $pkg->{idPe}->{$idPe}->{bubble_text} = $hr . "\n" . $entity_type_label . " " . $iteration . "\n" . $barcode; }
    else { $pkg->{idPe}->{$idPe}->{bubble_text} = $hr . "\n" . $entity_type_label . " \n" . $barcode; }
}
#--------------------------------------------------------------------------------#

sub printPlateData {

    my $plates = shift;

    # print the data
    print "all plates\n";
    foreach my $plate(sort {$a <=> $b} keys %$plates) {
	print "   plate $plate\n";
	foreach my $info(keys %{$plates->{$plate}}) {
	    if ($plates->{$plate}->{$info}) { 
		print "      $info "; 
		if (ref($plates->{$plate}->{$info}) eq "HASH") {
		    foreach (sort {$a <=> $b} keys %{$plates->{$plate}->{$info}}) { print "$_ "; }
		    print "\n";
		}
		else { print $plates->{$plate}->{$info} . "\n"; }
	    }
	}
    }
}
#--------------------------------------------------------------------------------#

sub getFromToPlates {
    my $plate = shift;
    my $ecs = shift;
    my $plate2ecs = shift;
    my $plates = shift;
    my $all_plates = shift;

    # go through the plate's wells, get the from/to wells 
    foreach my $well(keys %{$plate2ecs->{$plate}}) {
	# get the id_entity for that well
	my $current_plate = $ecs->{$well}->{plate};

	# get the plates corresponding to the 'from' and 'to' wells and add to the hashes
	foreach my $arrayed_from(keys %{$ecs->{$well}->{arrayed_from}}) {
	    my $from = $ecs->{$arrayed_from}->{plate}; 
	    if ($from && $all_plates->{$from}->{int} && $all_plates->{$from}->{hr}) {
		$plates->{$plate}->{arrayed_from}->{$from} = 1; 
		unless (defined($plates->{$from})) { $plates->{$from} = undef; }
	    }
	}
	foreach my $derived_from(keys %{$ecs->{$well}->{derived_from}}) {
	    my $from = $ecs->{$derived_from}->{plate}; 
	    if ($from && $all_plates->{$from}->{int} && $all_plates->{$from}->{hr}) {
		$plates->{$plate}->{derived_from}->{$from} = 1; 
		unless (defined($plates->{$from})) { $plates->{$from} = undef; }
	    }
	}
	foreach my $requires(keys %{$ecs->{$well}->{requires}}) {
	    my $from = $ecs->{$requires}->{plate}; 
	    if ($from && $all_plates->{$from}->{int} && $all_plates->{$from}->{hr}) {
		$plates->{$plate}->{requires}->{$from} = 1; 
		unless (defined($plates->{$from})) { $plates->{$from} = undef; }
	    }
	}
	foreach my $to_well(keys %{$ecs->{$well}->{to_well}}) {
	    my $to = $ecs->{$to_well}->{plate}; 
	    if ($to && $all_plates->{$to}->{int} && $all_plates->{$to}->{hr}) {
		$plates->{$plate}->{to}->{$to} = 1; 
		unless (defined($plates->{$to})) { $plates->{$to} = undef; }
	    }
	}
    }
    return($plates);
}
#---------------------------------------------------------------------------------------#

sub getPairs {
    my $pkg = shift;
    my $plates = shift;

    # set up a hash of the pairs and the style of line (edge) to draw between the bubbles (nodes)
    my $done_pairs = {};
    foreach my $plate(keys %$plates) {
	my $check = 0;
	foreach my $from_plate(keys %{$plates->{$plate}->{arrayed_from}}) {
	    my $pair = $from_plate . '_' . $plate;
	    next if ($done_pairs->{$pair});
	    $pkg->{pairs}->{$pair} = [$from_plate, $plate, 'solid'];
	    $done_pairs->{$pair}= 1;
	    $check = 1;
	}
	foreach my $from_plate(keys %{$plates->{$plate}->{derived_from}}) {
	    my $pair = $from_plate . '_' . $plate;
	    next if ($done_pairs->{$pair});
	    $pkg->{pairs}->{$pair} = [$from_plate, $plate, 'dotted'];
	    $done_pairs->{$pair}= 1;
	    $check = 1;
	}
	foreach my $from_plate(keys %{$plates->{$plate}->{requires}}) {
	    my $pair = $from_plate . '_' . $plate;
	    next if ($done_pairs->{$pair});
	    $pkg->{pairs}->{$pair} = [$from_plate, $plate, 'dashed'];
	    $done_pairs->{$pair}= 1;
	    $check = 1;
	}
	unless ($check) { 
	    my $pair = '_' . $plate;
	    $pkg->{pairs}->{$pair} = ['', $plate, ''];
	}
    }
}
#---------------------------------------------------------------------------------------#

sub make_image {

    my $pkg = shift;
    my $type = shift;

    # load into a graphviz object with the arrow represented correctly for the 'reason'
    my $graphviz = GraphViz->new();

#    my $graphviz = GraphViz->new(width => 4.5, 
#				 height => 6.5, 
#				 pagewidth => 7, 
#				 pageheight => 9.5, 
#				 ratio => 'compress');


    foreach my $pair(keys %{$pkg->{pairs}}) {
	my $from = $pkg->{pairs}->{$pair}->[0];
	my $to = $pkg->{pairs}->{$pair}->[1];
	my $from_text = $pkg->{idPe}->{$from}->{bubble_text};
	my $to_text = $pkg->{idPe}->{$to}->{bubble_text};
	my $style = $pkg->{pairs}->{$pair}->[2];
	my $from_shape = $pkg->{idPe}->{$from}->{shape};
	my $to_shape = $pkg->{idPe}->{$to}->{shape};

	if ($from_text) { 
	    if ($from_shape) { $graphviz->add_node($from_text, fontname => FONT, fontsize => FONTSIZE, shape => $from_shape, color => 'green'); }
	    else { $graphviz->add_node($from_text, fontname => FONT, fontsize => FONTSIZE); }
	}
	if ($to_text) { 
	    if ($to_shape) { $graphviz->add_node($to_text, fontname => FONT, fontsize => FONTSIZE, shape => $to_shape, color => 'green'); }
	    else { $graphviz->add_node($to_text, fontname => FONT, fontsize => FONTSIZE); }
	}

	if ($from_text && $to_text && $style) { $graphviz->add_edge($from_text => $to_text, style => $style); }
    }

    # generate the image
    my $image;
    if ($type && ($type eq 'ps')) {
	$image = $graphviz->as_ps();
    }
    else {
	$image = $graphviz->as_jpeg();
    }

    return($image) if ($image);

    return(0);
}
#---------------------------------------------------------------------------------------#

1;
