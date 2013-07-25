# VTRAP 
# genetrap specific methods for accessing vector design oracle database
# and for transferring data to TRAP
#
# Author: Lucy Stebbings (las)
#

use strict;

package VTRAP;

use SqlEngine2;
use Carp;
use TargetedTrap::BTRAP;
use TargetedTrap::VectorDesign::designs;
use TargetedTrap::VectorDesign::designStatus;
use TargetedTrap::VectorDesign::designInstanceStatus;
use TargetedTrap::TRAP::oligo;

use constant LOGIN => 'eucomm_vector'; ##########live!###########
#use constant LOGIN => 'eucomm_vector_t';
#use constant LOGIN => 'eucomm_vector_tt';
use constant LOGIN_LIVE => 'eucomm_vector';

#-----------------------------------------------------------------------------------#
#
# Constructor
#
sub new {
	my $class = shift;
	my %args = @_;

	my $self = {};

	$self->{-login} = $args{-login};

	$self->{se3} = new SqlEngine2();
	$self->{dbh3} = SqlEngine2::getDbh($self->{-login});

	bless $self, $class;

	if ($args{-TRAPlogin}) { $self->{TRAPlogin} = $args{-TRAPlogin}; }
	else { $self->{TRAPlogin}  = BTRAP::TRAP_LOGIN; }
#	else { $self->{TRAPlogin}  = BTRAP::TRAP_LOGIN_LIVE; }

	return $self;
}

#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# getters and setters (things that are needed to transfer between Vector_design/TRAP)
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub id_role {
    my $pkg = shift;
    $pkg->{id_role} = shift if @_;
    return $pkg->{id_role};
}
#-----------------------------------------------------------------------------------#
sub id_origin_supplier { 
    my $pkg = shift;
    $pkg->{id_origin_supplier} = shift if @_;
    return $pkg->{id_origin_supplier};
}
#-----------------------------------------------------------------------------------#
sub id_value_supplier  { 
    my $pkg = shift;
    $pkg->{id_value_supplier} = shift if @_;
    return $pkg->{id_value_supplier};
}
#-----------------------------------------------------------------------------------#
sub id_origin_designer { 
    my $pkg = shift;
    $pkg->{id_origin_designer} = shift if @_;
    return $pkg->{id_origin_designer};
}
#-----------------------------------------------------------------------------------#
sub id_value_designer { 
    my $pkg = shift;
    $pkg->{id_value_designer} = shift if @_;
    return $pkg->{id_value_designer};
}
#-----------------------------------------------------------------------------------#
sub id_project { 
    my $pkg = shift;
    $pkg->{id_project} = shift if @_;
    return $pkg->{id_project};
}
#-----------------------------------------------------------------------------------#
sub type { 
    my $pkg = shift;
    $pkg->{type} = shift if @_;
    return $pkg->{type};
}
#-----------------------------------------------------------------------------------#
# set which designs object we are accessing
sub designs { 
    my $pkg = shift;
    $pkg->{designs} = shift if @_;
    return $pkg->{designs};
}
#-----------------------------------------------------------------------------------#
sub id_vector_type { 
    my $pkg = shift;
    $pkg->{id_vector_type} = shift if @_;
    return $pkg->{id_vector_type};
}
#-----------------------------------------------------------------------------------#
# reference to an array of reagent ids or a scalar
sub id_reagents  { 
    my $pkg = shift;
    $pkg->{id_reagents} = shift if @_;
    return $pkg->{id_reagents};
}
#-----------------------------------------------------------------------------------#
# getter
sub se { 
    my $pkg = shift;
    return $pkg->{se3};
}
#-----------------------------------------------------------------------------------#
# getter
sub dbh { 
    my $pkg = shift;
    return $pkg->{dbh3};
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#

sub transferVectors {

    my $pkg = shift;
    my %args = @_; 

    # get a list of designs sorted by well from the designs object
    my $designs = $pkg->{designs}->designs();

    # unless -repeat is set, check the vector name hasn't already been used
    # find a character to tag on the end and set -repeat to this
    unless ($args{-repeat}) {
	my $name = $designs->[0];
	# for the first design, see if it is already in the database
	my $vector = new vector(-login => $pkg->{TRAPlogin},
				-name  => $name);

	# unless -repeat is set, get an iteration character and set it to that
	if ($vector->id_vector()) {
	    foreach my $character('a'..'b') {
		# see if the name plus charater is in the database
		my $vector = new vector(-login => $pkg->{TRAPlogin},
					-name  => $name . $character);
		next if ($vector->id_vector());
		$args{-repeat} = $character;
		last;
	    }
	}
    }

    # got through the designs and add the vector, vector status and oligo details
    foreach my $design(@{$designs}) {
	next unless ($design);

	my $frame = $pkg->{designs}->designPhase($design);
	my $design_instance_id = $pkg->{designs}->designInstanceId($design);
	my $locus = $pkg->{designs}->designLocus($design);

        # create a new vector object for this design
	my $vector = new vector(-login => $pkg->{TRAPlogin});
        # load all the vector info
	$vector->supplier_ids(-id_origin_supplier => $pkg->{id_origin_supplier}, 
                              -id_value_supplier  => $pkg->{id_value_supplier});
	$vector->designer_ids(-id_origin_designer => $pkg->{id_origin_designer}, 
                              -id_value_designer  => $pkg->{id_value_designer});
	$vector->id_project($pkg->{id_project});
	$vector->id_reagent_types($pkg->{id_reagents});
	$vector->locus_ids($locus);
	$vector->type($pkg->{type});
	$vector->id_vector_type($pkg->{id_vector_type});
	$vector->frame($frame);
	if ($args{-repeat}) {
	    $vector->name($design . $args{-repeat});
	}
	else {
	    $vector->name($design);
	}
	$vector->design_instance_id($design_instance_id);

        # flush the object to the TRAP database
	$vector->setVector();

        # get the new id_vector
	my $id_vector = $vector->id_vector();
	$pkg->{designs}->designIdVector($design, $id_vector);

	print "id_vector is $id_vector\n";

        # got to keep the vector objects until the end ?...
	#$pkg->{designs}->{$design}->{vector_object} = $vector;

        # create a new vector status object for this design and load it
	my $status = new vectorStatus(-login => $pkg->{TRAPlogin});
	$status->id_vector($id_vector);
	$status->id_status(vectorStatus::VSTATUS_DESIGNED);
	$status->id_role($pkg->{id_role});

        # flush the status to the TRAP database
        $status->setVectorStatus();

        # get a list of features for the design (ref to an array)
	my $features = $pkg->{designs}->designFeatures($design);

        # go through all the oligos for this design
	foreach my $feature_id(@$features) {

	    my $type = $pkg->{designs}->featureType($design, $feature_id);
	    my $seq  = $pkg->{designs}->featureOligo($design, $feature_id);
	    my $MW = $pkg->{designs}->featureMW($design, $feature_id);
	    my $GC = $pkg->{designs}->featureGC($design, $feature_id);

            # create a new oligo object for this feature
	    my $oligo = new oligo(-login => $pkg->{TRAPlogin});
	    # load all the oligo info
	    $oligo->id_vector($id_vector);
	    $oligo->oligo_type($type);
	    $oligo->oligo_seq($seq);
	    $oligo->molecular_weight($MW);
	    $oligo->GC_content($GC);
	    $oligo->feature_id($feature_id);

	    # flush the object to the TRAP database
	    # (only creates a new oligo entry if the oligo_type/sequence/feature_id are different to an existing one
	    # otherwise links to the existing oligo entry)
	    $oligo->setOligo();

	    # get the id_oligo
	    my $id_oligo = $oligo->id_oligo();
	    $pkg->{designs}->featureIdOligo($design, $feature_id, $id_oligo);

            # got to keep the oligo objects until the end ?...
	    #$pkg->{designs}->{$design}->{features}->{$feature_id}->{oligo_object} = $oligo;
	}

        #in testing only...
#	last;
    }

    return(0);
}

#--------------------------------------------------------------------------------------#
# sets the ordered status in vector design database
sub setStatusOrdered {

    my $pkg = shift;

    # get a list of designs sorted by well from the designs object
    my $designs = $pkg->{designs}->designs();

    # set the status to ordered
    foreach my $design(@$designs) {

	my $design_id = $pkg->{designs}->designId($design);

	next unless ($design_id);

        # create a new design status object for this design
	my $status = new designStatus(-se        => $pkg->{se3}, 
                                       -dbh       => $pkg->{dbh3},
                                       -design_id => $design_id);

        # get the current status and move on if it is already set to ordered
	my ($current_status) = $status->design_status_id();
	next if ($current_status && $current_status == designStatus::DESIGN_STATUS_ORDERED);

	$status->design_status_id(designStatus::DESIGN_STATUS_ORDERED);
	$status->id_role($pkg->{id_role});

        # flush the status to the vector_design database
        $status->setDesignStatus();

    }
    return(1);
}

#--------------------------------------------------------------------------------------#
# sets the under construction status in vector design database
sub setInstanceStatusUnderConstruction {

    my $pkg = shift;

    # get a list of designs sorted by well from the designs object
    my $designs = $pkg->{designs}->designs();

    # set the instance status to 'under constuction'
    foreach my $design(@$designs) {

	my $design_instance_id = $pkg->{designs}->designInstanceId($design);

        # create a new design status object for this design
	my $status = new designInstanceStatus(-se        => $pkg->{se3}, 
					      -dbh       => $pkg->{dbh3},
					      -design_instance_id => $design_instance_id);

        # get the current status and move on if it is already set to ordered
	my ($current_status) = $status->design_instance_status_id();
	next if ($current_status && $current_status == designInstanceStatus::DESIGN_INSTANCE_STATUS_UNDER_CONSTRUCTION);

	$status->design_instance_status_id(designInstanceStatus::DESIGN_INSTANCE_STATUS_UNDER_CONSTRUCTION);
	$status->id_role($pkg->{id_role});

        # flush the status to the vector_design database
        $status->setDesignInstanceStatus();
    }
    return(1);
}

#--------------------------------------------------------------------------------------#
#
# begin a transaction
#
sub beginVTrapTransaction {
	my $self = shift;
	print "Begining Vector Design transaction\n";
	$self->{se3}->beginTransaction($self->{dbh3});
}

#------------------------------------------------------------------------------------------------#
#
# roll back a transaction
#
sub rollbackVTrapTransaction {
	my $self = shift;
	print "Rollback Vector Design transaction\n";
	$self->{se3}->rollbackTransaction($self->{dbh3});
}

#------------------------------------------------------------------------------------------------#
#
# commit a transaction
#
sub commitVTrapTransaction {
	my $self = shift;
	print "Commit Vector Design transaction\n";
	$self->{se3}->commitTransaction($self->{dbh3});
}

#------------------------------------------------------------------------------------------------#
sub clear {
    my $pkg = shift;

    $pkg->{id_role} = undef;
    $pkg->{id_origin_supplier} = undef;
    $pkg->{id_value_supplier} = undef;
    $pkg->{id_origin_designer} = undef;
    $pkg->{id_value_designer} = undef;
    $pkg->{id_project} = undef;
    $pkg->{type} = undef;
    $pkg->{designs} = undef;
    $pkg->{id_vector_type} = undef;
    $pkg->{id_reagents} = undef;

}
#------------------------------------------------------------------------------------------------#
sub getDesignsNames {

    my $pkg = shift;

    my ($designs) = $pkg->{se3}->getAll('VTRAP::getDesignsNames', [], $pkg->{dbh3});

    return($designs);
}

#------------------------------------------------------------------------------------------------#
sub getDesignsInstancesNames {

    my $pkg = shift;
    my $plate = shift;

    my ($designs) = $pkg->{se3}->getAll('VTRAP::getDesignsInstancesNames', [$plate], $pkg->{dbh3});

    # design_id, design_name, design_instance_id
    return($designs);
}

#------------------------------------------------------------------------------------------------#
1;














