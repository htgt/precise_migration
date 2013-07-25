# designs (methods to do with getting sets of designs/instances given a plate id)
#
# Author: Lucy Stebbings (las)
#

package designs;

use Exporter;

use strict;
use TargetedTrap::TRAPutils;

#-----------------------------------------------------------------------------------#
#
# Constructor
#
sub new {
	my $class = shift;
	my %args = @_;

	unless ($args{-se} && $args{-dbh}) { print "no connection details supplied\n"; return(0); }

	my $self = {};

	$self->{se3} = $args{-se};
	$self->{dbh3} = $args{-dbh};


	bless $self, $class;

	if ($args{-plate}) { $self->plate($args{-plate}); } # sets the plate

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub plate {
    my $pkg = shift;
    my $plate = shift if @_;
    if ($plate) {
        # make sure the object is empty
	&clear_plate($pkg);
	$pkg->{plate} = $plate;
    }
    return $pkg->{plate};
}
#--------------------------------------------------------------------------------------#
# getter only - ref to an array of the design names sorted by well 
sub designs {
    my $pkg = shift;

    my $designs;

    foreach my $design(sort {$pkg->{designs}->{$a}->{well} cmp $pkg->{designs}->{$b}->{well}} keys %{$pkg->{designs}}) {
	push @$designs, $design;
    }

    return $designs;
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# getters for a particular design
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub designPhase {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{phase});
}
#-----------------------------------------------------------------------------------#
sub designId {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{design_id});
}
#-----------------------------------------------------------------------------------#
# the designInstance used to retrieve this plate of designs
sub designInstanceId {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{design_instance_id});
}
#-----------------------------------------------------------------------------------#
# other designInstances linked to by this design_id
sub designInstanceIds {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{design_instance_ids});
}
#-----------------------------------------------------------------------------------#
# getter/setter for the id_vector corresponding to the design instance
sub designIdVector {
    my $pkg = shift;
    my $design = shift;
    $pkg->{designs}->{$design}->{id_vector} = shift if @_;

    return($pkg->{designs}->{$design}->{id_vector});
}
#-----------------------------------------------------------------------------------#
# get all the oligo (U5,U3,D5,D3,G5,G3) feature ids for a design as an array ref
sub designFeatures {
    my $pkg = shift;
    my $design = shift;

    my $features;
    foreach my $feature(keys %{$pkg->{designs}->{$design}->{features}}) {
	push @$features, $feature;
    }

    return($features);
}
#-----------------------------------------------------------------------------------#
# getter for the gene corresponding to the design
sub designGene {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{gene});
}
#-----------------------------------------------------------------------------------#
# getter for the exon corresponding to the design
sub designExon {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{exon});
}
#-----------------------------------------------------------------------------------#
# getter for the bac corresponding to the design instance
# (if only one BAC plate)
sub designInstanceBAC {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{bac});
}
#-----------------------------------------------------------------------------------#
# getter for the bac plate corresponding to the design instance
# (if only one BAC plate)
sub designInstanceBACplate {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{bac_plate});
}
#-----------------------------------------------------------------------------------#
# getter for the bacs corresponding to the design instance and bac plate
# returns a bac name
# (if multiple BAC plates)
sub designInstanceBACplates {
    my $pkg = shift;
    my $design = shift;
    my $plate = shift;

    return($pkg->{designs}->{$design}->{bac_plates}->{$plate});
}
#-----------------------------------------------------------------------------------#
# getter for the bacs corresponding to the design instance and bac plate
# returns a bac name
# (if multiple BAC plates)
sub designInstanceBACs {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{bacs});
}
#-----------------------------------------------------------------------------------#
# getter for an array of BAC plates
sub BACplates {
    my $pkg = shift;

    return($pkg->{bac_plates});
}
#-----------------------------------------------------------------------------------#
# getter for the well corresponding to the design
sub designWell {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{well});
}
#-----------------------------------------------------------------------------------#
# getter for the locus corresponding to the design
sub designLocus {
    my $pkg = shift;
    my $design = shift;

    return($pkg->{designs}->{$design}->{locus});
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# getters for a particular design feature
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub featureId {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;

    return($pkg->{designs}->{$design}->{features}->{$feature}->{feature_id});
}
#-----------------------------------------------------------------------------------#
sub featureType {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;

    return($pkg->{designs}->{$design}->{features}->{$feature}->{type});
}
#-----------------------------------------------------------------------------------#
sub featureOligo {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;

    return($pkg->{designs}->{$design}->{features}->{$feature}->{oligo});
}
#-----------------------------------------------------------------------------------#
sub featureMW {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;

    unless ($pkg->{designs}->{$design}->{features}->{$feature}->{MW}) { 
     if ($pkg->{designs}->{$design}->{features}->{$feature}->{oligo}) { &calcOligos($pkg); } 
    }

    return($pkg->{designs}->{$design}->{features}->{$feature}->{MW});
}
#-----------------------------------------------------------------------------------#
sub featureGC {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;

    unless ($pkg->{designs}->{$design}->{features}->{$feature}->{GC}) { 
     if ($pkg->{designs}->{$design}->{features}->{$feature}->{oligo}) { &calcOligos($pkg); } 
    }

    return($pkg->{designs}->{$design}->{features}->{$feature}->{GC});
}
#-----------------------------------------------------------------------------------#
# getter/setter for the id_oligo corresponding to the feature
sub featureIdOligo {
    my $pkg = shift;
    my $design = shift;
    my $feature = shift;
    $pkg->{designs}->{$design}->{features}->{$feature}->{id_oligo} = shift if @_;

    return($pkg->{designs}->{$design}->{features}->{$feature}->{id_oligo});
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub checkPlate {

    my $pkg = shift;
    my $skip_well_check = shift;

    # clear data structure
    &clear_plate($pkg);

    # see if the final plate exists in the database and get the well locations and design names for those wells
    my ($designs) = $pkg->{se3}->getAll('VTRAP::getDesignNameWell', [$pkg->{plate}], $pkg->{dbh3});

    foreach my $row(@$designs) {
	$pkg->{wells}->{$row->[1]}->{design} = $row->[0];
	$pkg->{wells}->{$row->[1]}->{design_instance_id} = $row->[2];
	$pkg->{designs}->{$row->[0]}->{well} = $row->[1];
	$pkg->{designs}->{$row->[0]}->{design_instance_id} = $row->[2];
    }

    # check all the well locations are assigned
    for (my $i = 1; $i < 9 ;$i++) {
	my $row = $pkg->TRAPutils::convertAlphanumeric($i);

        for (my $j = 1; $j < 13 ;$j++) {
	    my $well = uc($row) . (sprintf"%02d", $j);

	    unless ($pkg->{wells}->{$well}) {
		unless ($skip_well_check) {
		    print "Error: well $well not assigned\n";
		    return(0);
		}
	    }
	}
    }
    
    return(1) if ($pkg->{wells});
    return(0);
}

#-----------------------------------------------------------------------------------#
# DO NOT USE!!!! NO LONGER WORKING!
sub assignFinalPlatesNames {

    return();

    my $pkg = shift;

    # clear existing names and wells for plate 8
    $pkg->{se3}->do('VTRAP::clearNameWell', [$pkg->{plate}], $pkg->{dbh3});

    # set the new wells and names
    my @wells = &_getWellSet();
    my @names = &_getVectorNames($pkg);
    my @next_plate = ();

    # getDesignsOrderByPhase
    my ($designs) = $pkg->{se3}->getAll('VTRAP::getDesignsOrderByPhase', [$pkg->{plate}], $pkg->{dbh3});

    foreach my $row(@$designs) {
	my $design_id = $row->[0];
	my $phase = $row->[1];
	if (scalar(@wells)) {
	    $pkg->{design_ids}->{$design_id}->{well} = shift @wells;
	    $pkg->{design_ids}->{$design_id}->{name} = shift @names;
	    $pkg->{design_ids}->{$design_id}->{phase} = $phase;
	}
	else {
	    push @next_plate, $design_id;
	}
    }

    if (scalar(keys %{$pkg->{design_ids}}) == 96) {
	&_setWellsNames($pkg);
	&_setFinalPlate($pkg, ($pkg->{plate} + 1), \@next_plate);
	return(1);
    }

    return(0);
}
#-----------------------------------------------------------------------------------#

sub _getWellSet {

    my @rows = ('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H');
    my @cols = ('01','02','03','04','05','06','07','08','09','10','11','12');


    my @wells = ();

    # construct a list of wells to use
    foreach my $col(@cols) {
	foreach my $row(@rows) {
	    my $well = $row . $col;
	    push @wells, $well;
	}
    }
    print "wells @wells\n";
    return (@wells);
}

#-----------------------------------------------------------------------------------#

sub _getVectorNames {

    my $pkg = shift;

    my $last_name;

    # get the most recent id in the database
    my ($name) = $pkg->{se3}->getRow('VTRAP::getMaxName', [], $pkg->{dbh3});

#    foreach my $row(@$designs) {
#	$last_name = $name;
#	print "last";
#    }

#    my ($last_id) = ($last_name =~ /\D+0*(\d+)/);
    my ($last_id) = ($name =~ /\D+0*(\d+)/);

    my @names = (($last_id + 1)..($last_id + 97));
#    my @names = (385..480);

    foreach (@names) { $_ = 'EUCTV' . (sprintf "%05d", $_); }

    print "names @names\n";
    return @names;
}

#-----------------------------------------------------------------------------------#
# DO NOT USE!!!! NO LONGER WORKING!!
sub _setWellsNames {

    return();

    my $pkg = shift;

    my $count = 1;

    foreach my $design_id(sort {$a <=> $b} keys %{$pkg->{design_ids}}) {
	my $well = $pkg->{design_ids}->{$design_id}->{well};
	my $name = $pkg->{design_ids}->{$design_id}->{name};
	my $phase = $pkg->{design_ids}->{$design_id}->{phase};
	print "setting well $well name $name for design $design_id  phase $phase\n";
	print "$count \n";
	$count++;
	next unless ($design_id && $well && $name);
	print "OK\n";

        # updateWell
        $pkg->{se3}->do('VTRAP::updateWell', [$well, $design_id], $pkg->{dbh3});
        # updateName
        $pkg->{se3}->do('VTRAP::updateName', [$name, $design_id], $pkg->{dbh3});
    }
}

#-----------------------------------------------------------------------------------#
# DO NOT USE!!!! NO LONGER WORKING!!
sub _setFinalPlate {

    return();

    my $pkg = shift;
    my $plate_id = shift;
    my $design_ids = shift;

    my $count = 1;
    foreach my $design_id(@$design_ids) {
	print "$count set final plate for $design_id to $plate_id\n";
	$count++;
	next unless ($design_id);
	print "OK\n";
        # updatePlate
        $pkg->{se3}->do('VTRAP::updatePlate', [$plate_id, $design_id], $pkg->{dbh3});
    }
}
#-----------------------------------------------------------------------------------#
sub getDesigns {

    my $pkg = shift;

    my %BAC_plates; # somewhere to keep all the BAC plates temporarily
    $pkg->{bac_plates} = undef; # sorted array of BAC plates

    # get the locus id, all the oligo details and the BAC for each design
    foreach my $design(keys %{$pkg->{designs}}) {
	my $design_instance_id = $pkg->{designs}->{$design}->{design_instance_id};
	my $design_id;
	print "design name $design instance $design_instance_id\n";
        # getDesignInfo
        my ($design_info) = $pkg->{se3}->getAll('VTRAP::getDesignInstanceInfo', [$design_instance_id], $pkg->{dbh3});

	foreach my $row(@$design_info) {

	    my $locus_id = $row->[0];
	    my $feature_id = $row->[1];
	    my $oligo_type = $row->[2];
	    my $data_type = $row->[3];
	    my $item = $row->[4];
	    my $phase = $row->[5];
	    $design_id = $row->[6];

	    $pkg->{designs}->{$design}->{locus} = $locus_id;
	    $pkg->{designs}->{$design}->{phase} = $phase;
	    $pkg->{designs}->{$design}->{design_id} = $design_id;
	    $pkg->{designs}->{$design}->{features}->{$feature_id}->{type} = $oligo_type;
	    if ($data_type eq "sequence") {
		$pkg->{designs}->{$design}->{features}->{$feature_id}->{seq} = $item;
	    }
	    elsif ($data_type eq "append sequence") {
		$pkg->{designs}->{$design}->{features}->{$feature_id}->{append} = $item;
	    }
	    elsif ($data_type eq "make reverse complement") {
		$pkg->{designs}->{$design}->{features}->{$feature_id}->{rev} = $item;
	    }
        }

	# get all design_instance_ids for this design
	my ($design_instances) = $pkg->{se3}->getAll('VTRAP::getDesignInstances', [$design_id], $pkg->{dbh3});
	foreach (@$design_instances) {
	    push @{$pkg->{designs}->{$design}->{design_instance_ids}}, $_->[0];
	}

	# get all the bacs
	$pkg->{designs}->{$design}->{bac} = undef; 
	$pkg->{designs}->{$design}->{bac_plate} = undef; 
	$pkg->{designs}->{$design}->{bacs} = undef; 
	$pkg->{designs}->{$design}->{bac_plates} = undef; 


	# get the bacs for a design instance ordered by plate
#	my ($bacs) = $pkg->{se3}->getAll('VTRAP::getDesignInstanceBACs', [$design_instance_id], $pkg->{dbh3});
	my ($bacs) = $pkg->{se3}->getAll('VTRAP::getDesignInstanceBACplates', [$design_instance_id], $pkg->{dbh3});
	unless ((scalar(@$bacs))) {
	    print "ALERT! NO BAC FOR DESIGN $design_id\n";
	    next;
	}

#####################################################################################


	# bodged to deal with a) no bac_plate entries and b) duplicate remote_clone_id entries
#	my $plate = 'a';
#	if ($bacs->[0]->[0] =~ /bMQ_?(\d+)(\D)(\d+)/) { $bacs->[0]->[0] = 'bMQ-' . $1 . uc($2) . $3; }
#	$pkg->{designs}->{$design}->{bac} = $bacs->[0]->[0]; 
#	$pkg->{designs}->{$design}->{bac_plate} = $plate; 
#	push @{$pkg->{designs}->{$design}->{bacs}}, $bacs->[0]->[0]; 
#	$pkg->{designs}->{$design}->{bac_plates}->{$plate} = $bacs->[0]->[0]; 
#	$BAC_plates{$plate} = $plate; 


#####################################################################################

	if ((scalar(@$bacs)) == 1) { 
	    if ($bacs->[0]->[0] =~ /bMQ_?(\d+)(\D)(\d+)/) { $bacs->[0]->[0] = 'bMQ-' . $1 . uc($2) . $3; }
	    $pkg->{designs}->{$design}->{bac} = $bacs->[0]->[0]; 

	    if ($bacs->[0]->[1] && ($bacs->[0]->[1] =~ /(\D+)/)) {
		my $plate_iteration = $1;
		$pkg->{designs}->{$design}->{bac_plate} = $plate_iteration; 
	    }
	    else {
		$pkg->{designs}->{$design}->{bac_plate} = 'a'; 
	    }
	    print "Single: $pkg->{designs}->{$design}->{bac} $pkg->{designs}->{$design}->{bac_plate}\n";
	}
	else {
	    print "Multiple BACs for design $design_id\n";
	}
	foreach my $row(@$bacs) { 

	    my $plate_iteration = undef;

	    # make sure the BAC name is in the right format
	    if ($row->[0] =~ /bMQ_?(\d+)(\D)(\d+)/) { $row->[0] = 'bMQ-' . $1 . uc($2) . $3; }

	    # keep an array of all the bacs per design
	    push @{$pkg->{designs}->{$design}->{bacs}}, $row->[0]; 

	    # register the BAC plates and which designs are on which plates
	    if ($row->[1] && ($row->[1] =~ /(\D+)/)) { $plate_iteration = $1; }
	    else { $plate_iteration = 'a'; }

	    $BAC_plates{$plate_iteration} = $plate_iteration; 
	    $pkg->{designs}->{$design}->{bac_plates}->{$plate_iteration} = $row->[0];

	    if ($row->[1]) { print "$row->[0]  $row->[1]  $plate_iteration\n"; }
	    else { print "$row->[0]  $plate_iteration\n"; }
	}
    }

    # put the BAC plates into a sorted array
    foreach (sort {$a cmp $b} keys %BAC_plates) { push @{$pkg->{bac_plates}}, $_; }

    &_makeOligos($pkg);
}

#-----------------------------------------------------------------------------------#

sub getDesignsReport { 

    my $pkg = shift;

    my $checkG5 = 0;
    my $checkG3 = 0;
    my $checkU5 = 0;
    my $checkU3 = 0;
    my $checkD5 = 0;
    my $checkD3 = 0;

    foreach my $design(sort {$pkg->{designs}->{$a}->{well} cmp $pkg->{designs}->{$b}->{well}} keys %{$pkg->{designs}}) {
	print "$design, $pkg->{designs}->{$design}->{locus}, $pkg->{designs}->{$design}->{bac} $pkg->{designs}->{$design}->{well}\n";
	$checkG5 = 0;
	$checkG3 = 0;
	$checkU5 = 0;
	$checkU3 = 0;
	$checkD5 = 0;
	$checkD3 = 0;

	foreach my $feature_id(sort {$pkg->{designs}->{$design}->{features}->{$a}->{type} cmp $pkg->{designs}->{$design}->{features}->{$b}->{type}} keys %{$pkg->{designs}->{$design}->{features}}) {
	    print " $pkg->{designs}->{$design}->{features}->{$feature_id}->{type}";
	    if ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'G5') {
	        $checkG5++;
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'G3') {
	        $checkG3++;
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'D5') {
	        $checkD5++;
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'D3') {
	        $checkD3++;
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'U5') {
	        $checkU5++;
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{type} eq 'U3') {
	        $checkU3++;
	    }
	}

	unless ($checkG5 && $checkG3 && $checkD5 && $checkD3 && $checkU5 && $checkU3) {
	    print "    ERROR: oligo missing!";
	}

	if (($checkG5 > 1) ||
            ($checkG3 > 1) ||
            ($checkD5 > 1) ||
            ($checkD3 > 1) ||
            ($checkU5 > 1) ||
            ($checkU3 > 1)) {
	    print "    
ERROR: multiple oligos!";
	}

	print "\n";
    }

}

#-----------------------------------------------------------------------------------#

sub clear_plate {

    my $pkg = shift;

    $pkg->{designs} = undef;
    $pkg->{design_ids} = undef;
    $pkg->{wells} = undef;
}

#-----------------------------------------------------------------------------------#

sub _makeOligos {

    my $pkg = shift;

    foreach my $design(keys %{$pkg->{designs}}) {
	foreach my $feature_id(keys %{$pkg->{designs}->{$design}->{features}}) {
	    my $sequence = $pkg->{designs}->{$design}->{features}->{$feature_id}->{seq};
	    my $append = $pkg->{designs}->{$design}->{features}->{$feature_id}->{append};
	    my $rev = $pkg->{designs}->{$design}->{features}->{$feature_id}->{rev};
	    my $well = $pkg->{designs}->{$design}->{well};
	    my $type = $pkg->{designs}->{$design}->{features}->{$feature_id}->{type};
	    print "$design $well $feature_id $type |$rev|\n";


	    $pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo_name} = $well . "_" . $design . "_" . $type;

#	    print "name $pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo_name}\n";
	    if ($pkg->{designs}->{$design}->{features}->{$feature_id}->{rev} == 0) {
		$pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo} = uc($sequence . $append);
	    }
	    elsif ($pkg->{designs}->{$design}->{features}->{$feature_id}->{rev} == 1) {
		my $revseq = TRAPutils::reverseSeq($sequence);
		$pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo} = uc($revseq . $append);
	    }
	}
    }
    &_calcOligos($pkg);
}

#-----------------------------------------------------------------------------------#

sub _calcOligos {

    my $pkg = shift;

    foreach my $design(keys %{$pkg->{designs}}) {
	foreach my $feature_id(keys %{$pkg->{designs}->{$design}->{features}}) {
	    my $GC = TRAPutils::getGCcontent($pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo});
	    my $MW = TRAPutils::getMW($pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo});
#	    print "$pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo} $GC $MW\n";
	    $pkg->{designs}->{$design}->{features}->{$feature_id}->{GC} = $GC;
	    $pkg->{designs}->{$design}->{features}->{$feature_id}->{MW} = $MW;
	}
    }
}

#-----------------------------------------------------------------------------------#

sub printOligoOrders {

    my $pkg = shift;

    # open the oligo files

    my $name = $pkg->{plate} . '_' . 'D5'; 
    open D5, "> $name" or die $!;
    $name = $pkg->{plate} . '_' . 'D3'; 
    open D3, "> $name" or die $!;
    $name = $pkg->{plate} . '_' . 'U5'; 
    open U5, "> $name" or die $!;
    $name = $pkg->{plate} . '_' . 'U3'; 
    open U3, "> $name" or die $!;
    $name = $pkg->{plate} . '_' . 'G5'; 
    open G5, "> $name" or die $!;
    $name = $pkg->{plate} . '_' . 'G3'; 
    open G3, "> $name" or die $!;

    # go through the designs in well order and print each of the oligos to the appropriate files
    foreach my $design(sort {$pkg->{designs}->{$a}->{well} cmp $pkg->{designs}->{$b}->{well}} keys %{$pkg->{designs}}) {
	print "well $pkg->{designs}->{$design}->{well}\n";
	# split the well into row and column
	my ($row, $col) = ($pkg->{designs}->{$design}->{well} =~ /^(\D)0?(\d+)$/);

        # go through the oligos for that design
	foreach my $feature_id(keys %{$pkg->{designs}->{$design}->{features}}) {

	    my $type = $pkg->{designs}->{$design}->{features}->{$feature_id}->{type};
	    my $name = $pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo_name};
	    my $seq = $pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo};

	print "type $type name $name seq $seq\n";

	    my $line = "$pkg->{plate}\t$row\t$col\t$name\t\t$seq\n";

	    # check the type and print to the appropriate file
	    if ($type eq 'D5') { print D5 $line; }
	    elsif ($type eq 'D3') { print D3 $line; }
	    elsif ($type eq 'U5') { print U5 $line; }
	    elsif ($type eq 'U3') { print U3 $line; }
	    elsif ($type eq 'G5') { print G5 $line; }
	    elsif ($type eq 'G3') { print G3 $line; }
	}
    }

    # close the oligo files
    close D5;
    close D3;
    close U5;
    close U3;
    close G5;
    close G3;
}

#-----------------------------------------------------------------------------------#

sub printBACOrders {

    my $pkg = shift;


    # go through the BAC plates
    foreach my $plate(@{$pkg->{bac_plates}}) {

	# set up the file names
	my $name1 = $pkg->{plate} . '_' . 'BAC'. $plate . '_1'; 
	my $name2 = $pkg->{plate} . '_' . 'BAC'. $plate . '_2'; 

	# open the BAC files
	open BAC1, "> $name1" or die $!;
	open BAC2, "> $name2" or die $!;

	my %done = ();

	# go through the designs in well order and print the BAC found on this plate to the appropriate files
	foreach my $design(sort {$pkg->{designs}->{$a}->{well} cmp $pkg->{designs}->{$b}->{well}} keys %{$pkg->{designs}}) {

	    # split the well into row and column
	    my ($row, $col) = ($pkg->{designs}->{$design}->{well} =~ /^(\D)(\d+)$/);

	    my $BAC = $pkg->{designs}->{$design}->{bac_plates}->{$plate};

	    if ($BAC) {
		# record that a BAC has been encountered
		unless ($done{$BAC}) { 
		    print BAC1 "$BAC\n"; 
		    # add to done list of bacs
		    $done{$BAC} = $BAC;
		}
	    }

	    if ($col == 1) { print BAC2 "\n"; }
	    print BAC2 "$BAC";
	    unless ($col == 12) { print BAC2 "\t"; }
	}

	# close the BAC files
	close BAC1;
	close BAC2;
    }

}
#-----------------------------------------------------------------------------------#
sub getWells {

    my $pkg = shift;

    my $wells = {};

    foreach my $design(sort {$pkg->{designs}->{$a}->{well} cmp $pkg->{designs}->{$b}->{well}} keys %{$pkg->{designs}}) {
	my $id_vector = $pkg->{designs}->{$design}->{id_vector};
	my $well = $pkg->{designs}->{$design}->{well};

	$wells->{$well}->{id_vector} = $id_vector;
	$wells->{$well}->{name} = $design;

	foreach my $feature_id(keys %{$pkg->{designs}->{$design}->{features}}) {
	    my $id_oligo = $pkg->{designs}->{$design}->{features}->{$feature_id}->{id_oligo};
	    my $type = $pkg->{designs}->{$design}->{features}->{$feature_id}->{type};

	    $wells->{$well}->{oligos}->{$type} = $id_oligo;
	}
    }
    # return hash of well, id_vector, id_oligo and oligo_type
    return $wells;
}

#-----------------------------------------------------------------------------------#
sub getGeneExon {

    my $pkg = shift;

    # see if the final plate exists in the database and get the well locations and design names for those wells
    my ($designs) = $pkg->{se3}->getAll('VTRAP::getDesignsGeneExon', [$pkg->{plate}], $pkg->{dbh3});

    foreach my $row(@$designs) {

	my $design_id = $row->[0];
	my $name = $row->[1];
	my $well = $row->[2];
	my $gene = $row->[3];
	my $exon = $row->[4];
	my $phase = $row->[5];

	$pkg->{designs}->{$name}->{well} = $well;
	$pkg->{designs}->{$name}->{phase} = $phase;
	$pkg->{designs}->{$name}->{gene} = $gene;
	$pkg->{designs}->{$name}->{exon} = $exon;
	$pkg->{designs}->{$name}->{design_id} = $design_id;
    }

}
#-----------------------------------------------------------------------------------#
1;
