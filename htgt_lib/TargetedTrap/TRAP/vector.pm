# vector (methods to do with submitting vector details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package vector;

use Exporter;

use strict;
use SqlEngine2;

use Carp;

use constant VTYPE_RANDOM => 1;
use constant VTYPE_PRE_TT => 2;
use constant VTYPE_TT_CASSETTE => 3;
use constant VTYPE_TT_BASE => 4;
use constant VTYPE_TT => 5;
use constant VTYPE_U_CONSTRUCT => 6;
use constant VTYPE_D_CONSTRUCT => 7;
use constant VTYPE_G_CONSTRUCT => 8;
use constant VTYPE_REC_CONSTRUCT => 9;

#-------------------------------------------------------------------------------------------------------#
#
# Constructor
#
sub new {
	my $class = shift;
	my %args = @_;

	my $self = {};

	unless (($args{-se} && $args{-dbh}) || $args{-login}) {
	    print "must supply -se|-dbh or -login\n";
	    return(0);
	}

	if ($args{-se} && $args{-dbh}) { 
	    $self->{se2} = $args{-se}; 
	    $self->{dbh2} = $args{-dbh};
	}
	else {
	    $self->{-login} = $args{-login};
	    $self->{se2} = new SqlEngine2();
	    $self->{dbh2} = SqlEngine2::getDbh($self->{-login});
	}

	bless $self, $class;

        # set any parameters that are passed in
	if ($args{-id_vector}) { $self->id_vector($args{-id_vector}); } # gets an existing vector

	else {
	    if ($args{-name})                 { $self->name($args{-name}); }
            # if the name is an existing one, all the data for that object will be retrieved.
            # make them explicitly set any changes to this object (no updates on creation!)
	    unless ($self->{exists}) {
		if ($args{-type})                 { $self->type($args{-type}); }
		if ($args{-vector_type})          { $self->vector_type($args{-vector_type}); }
		if ($args{-id_vector_type})       { $self->id_vector_type($args{-id_vector_type}); }
		if (defined $args{-frame})        { $self->frame($args{-frame}); }
		if ($args{-description})          { $self->description($args{-description}); }
		if ($args{-info_location})        { $self->info_location($args{-info_location}); }
		if ($args{-project})              { $self->project($args{-project}); }
		if ($args{-id_project})           { $self->id_project($args{-id_project}); }
		if ($args{-id_vector_constructs}) { $self->id_vector_constructs($args{-id_vector_constructs}); }
		if ($args{-id_reagent_types})     { $self->id_reagent_types($args{-id_reagent_types}); }
		if ($args{-locus_ids})            { $self->locus_ids($args{-locus_ids}); }
		if ($args{-reagent_types})        { $self->reagent_types($args{-reagent_types}); }
		if ($args{-design_instance_id})            { $self->design_instance_id($args{-design_instance_id}); }
		if ($args{-id_value_supplier} && 
		    $args{-id_origin_supplier})   { $self->supplier_ids(-id_value_supplier  => $args{-id_value_supplier},
									-id_origin_supplier => $args{-id_origin_supplier}); }
		if ($args{-id_value_designer} && 
		    $args{-id_origin_designer})   { $self->designer_ids(-id_value_designer  => $args{-id_value_designer},
									-id_origin_designer => $args{-id_origin_designer}); }
	    }
	}
	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_vector {
    my $pkg = shift;
    my $id_vector = shift if @_;

    if ($id_vector) {
	$pkg->{id_vector} = $id_vector;

	# see if this vector exists in the db already
	# set 'exists' switch if it does
	if (&getVectorDetails($pkg)) {
	    print"vector $pkg->{id_vector} $pkg->{name} exists\n";
	    $pkg->{exists} = 1;
	    &getIdVectorConstructs($pkg);
	    &getIdOligos($pkg);
	    &getIdLocus($pkg);
	    &getReagentTypes($pkg);
	}
	else {
	    print"can not find vector $pkg->{id_vector}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }
    return $pkg->{id_vector};
}
#--------------------------------------------------------------------------------------#
sub name {
    my $pkg = shift;
    my $name = shift if @_;

    if ($name) {
	$pkg->{name} = $name;
	# see if this name is in use in the db already and get the id
	# set 'exists' switch if it does

	if ($pkg->{exists}) {}
	elsif (&getIdVector($pkg)) {
	    print"vector $pkg->{id_vector} $pkg->{name} exists\n";
	    $pkg->{exists} = 1;
	    &getVectorDetails($pkg);
	    &getIdVectorConstructs($pkg);
	    &getIdOligos($pkg);
	    &getIdLocus($pkg);
	    &getReagentTypes($pkg);
	}
	else {
	    print"vector $pkg->{name} is new\n";
	    undef $pkg->{exists};
	}
    }

    return $pkg->{name};
}
#--------------------------------------------------------------------------------------#
sub vectorExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub type {
    my $pkg = shift;
    my $type = shift if @_;
    if ($type) {
	$pkg->{type} = $type;
	unless (($pkg->{type} eq 'plasmid') ||
		($pkg->{type} eq 'viral') ||
		($pkg->{type} eq 'other')) {
	    print "type should be plasmid|viral|other\n";
	    undef $pkg->{type};
	    return(0);
	}
    }
    return $pkg->{type};
}
#--------------------------------------------------------------------------------------#
sub frame {

    my $pkg = shift;
    my $frame = shift if @_;

    if (defined $frame) {
	$pkg->{frame} = $frame;
	unless (($pkg->{frame} eq '0') ||
		($pkg->{frame} eq '1') ||
		($pkg->{frame} eq '2') ||
		($pkg->{frame} eq '-1') ||
		($pkg->{frame} eq 'K')) {
	    print "frame should be 0|1|2|-1|K not $pkg->{frame}\n";
	    undef $pkg->{frame};
	    return(0);
	}
    }

    return $pkg->{frame};
}
#--------------------------------------------------------------------------------------#
sub description {
    my $pkg = shift;
    $pkg->{description} = shift if @_;
    return $pkg->{description};
}
#--------------------------------------------------------------------------------------#
sub supplier_ids {
    my $pkg = shift;
    my %args = @_;

    if ($args{-id_value_supplier} || $args{-id_origin_supplier}) {
	unless ($args{-id_value_supplier} && $args{-id_origin_supplier}) { 
	    print "need both origin and value for supplier\n"; 
	    return(0);
	}
	$pkg->{id_value_supplier} = $args{-id_value_supplier};
	$pkg->{id_origin_supplier} = $args{-id_origin_supplier};
	# maybe check the origin and value are valid? need to get at team_person_role table though
#	unless (&_checkOriginValue($pkg, $pkg->{id_origin_supplier}, $pkg->{id_value_supplier})) {
#	    print "supplier origin $pkg->{id_origin_supplier}, value $pkg->{id_value_supplier} not valid\n";
#	    undef $pkg->{id_value_supplier};
#	    undef $pkg->{id_origin_supplier};
#	    return(0);
#	}
    }
    return ($pkg->{id_value_supplier}, $pkg->{id_origin_supplier});
}
#--------------------------------------------------------------------------------------#
sub designer_ids {
    my $pkg = shift;
    my %args = @_;

    if ($args{-id_value_designer} || $args{-id_origin_designer}) {
	unless ($args{-id_value_designer} && $args{-id_origin_designer}) { 
	    print "need both origin and value for designer\n"; 
	    return(0);
	}
	$pkg->{id_value_designer} = $args{-id_value_designer} if $args{-id_value_designer};
	$pkg->{id_origin_designer} = $args{-id_origin_designer} if $args{-id_origin_designer};
	# check the origin and value are valid? need to get at team_person_role table though
#	unless (&_checkOriginValue($pkg, $pkg->{id_origin_designer}, $pkg->{id_value_designer})) {
#	    print "desiginer origin $pkg->{id_origin_designer}, value $pkg->{id_value_designer} not valid\n";
#	    undef $pkg->{id_value_designer};
#	    undef $pkg->{id_origin_designer};
#	    return(0);
#	}
    }
    return ($pkg->{id_value_designer}, $pkg->{id_origin_designer});
}
#--------------------------------------------------------------------------------------#
sub info_location {
    my $pkg = shift;
    $pkg->{info_location} = shift if @_;
    return $pkg->{info_location};
}
#--------------------------------------------------------------------------------------#
sub design_instance_id {
    my $pkg = shift;
    $pkg->{design_instance_id} = shift if @_;
    return $pkg->{design_instance_id};
}
#--------------------------------------------------------------------------------------#
sub id_vector_type {
    my $pkg = shift;
    my $id_vector_type = shift if @_;
    if ($id_vector_type) {
	$pkg->{id_vector_type} = $id_vector_type;
	# get the vector type and set that
	&getVectorType($pkg);
	unless ($pkg->{vector_type}) {
	    print "id_vector_type $pkg->{id_vector_type} not valid\n";
	    undef $pkg->{id_vector_type};
	    undef $pkg->{vector_type};
	    return(0);
	}
    }
    return ($pkg->{id_vector_type}, $pkg->{vector_type});
}
#--------------------------------------------------------------------------------------#
sub vector_type {
    my $pkg = shift;
    my $vector_type = shift if @_;
    if ($vector_type) {
	$pkg->{vector_type} = $vector_type;
	# get the id vector type and set that
	&getIdVectorType($pkg);
	unless ($pkg->{id_vector_type}) {
	    print "vector_type $pkg->{vector_type} not valid\n";
	    undef $pkg->{id_vector_type};
	    undef $pkg->{vector_type};
	    return(0);
	}
    }
    return ($pkg->{vector_type}, $pkg->{id_vector_type});
}
#--------------------------------------------------------------------------------------#
sub id_project {
    my $pkg = shift;
    my $id_project = shift if @_;
    if ($id_project) {
	$pkg->{id_project} = $id_project;
	# get the project and set that
	&getProject($pkg);
	unless ($pkg->{project}) {
	    print "id_project $pkg->{id_project} not valid\n";
	    undef $pkg->{id_project};
	    undef $pkg->{project};
	    return(0);
	}
    }
    return ($pkg->{id_project}, $pkg->{project});
}
#--------------------------------------------------------------------------------------#
sub project {
    my $pkg = shift;
    my $project = shift if @_;
    if ($project) {
	$pkg->{project} = $project;
        # get the project id and set that
	&getIdProject($pkg);
	unless ($pkg->{id_project}) {
	    print "project $pkg->{project} not valid\n";
	    undef $pkg->{id_project};
	    undef $pkg->{project};
	    return(0);
	}
    }
    return ($pkg->{project}, $pkg->{id_project});
}
#--------------------------------------------------------------------------------------#
sub id_reagent_types {
    my $pkg = shift;
    my $id_reagents = shift if @_; # could be a single reagent id or an array reference

    # set up hash of id reagent types/reagent types    
    if ($id_reagents) {
	undef $pkg->{reagents};
	my @id_reagents = ();
	if (ref($id_reagents) eq 'ARRAY') { @id_reagents = @$id_reagents; }
	else {push @id_reagents, $id_reagents; }

        # check each id reagent is genuine and get the corresponding reagent descrition
	foreach my $id_reagent(@id_reagents) {
	    my $reagent = &getReagentType($pkg, $id_reagent);
	    unless ($reagent) {
		print "id reagent $id_reagent not valid\n";
		undef $pkg->{reagents};
		return(0);
	    }
	    $pkg->{reagents}->{$id_reagent} = $reagent;
	}
    }

    return $pkg->{reagents}; # a hash reference, id/description
}
#--------------------------------------------------------------------------------------#
sub reagent_types {
    my $pkg = shift;
    my $reagents = shift if @_; # could be a single reagent or an array reference

    # set up hash of id reagent types/reagent types    
    if ($reagents) {
	undef $pkg->{reagents};
	my @reagents = ();
	if (ref($reagents) eq 'ARRAY') { @reagents = @$reagents; }
	else {push @reagents, $reagents; }

        # check each id reagent is genuine and get the corresponding reagent descrition
	foreach my $reagent(@reagents) {
	    my $id_reagent = &getIdReagentType($pkg, $reagent);
	    unless ($id_reagent) {
		print "reagent $reagent not valid\n";
		undef $pkg->{reagents};
		return(0);
	    }
	    $pkg->{reagents}->{$id_reagent} = $reagent;
	}
    }

    return $pkg->{reagents}; # a hash reference, id/description
}
#--------------------------------------------------------------------------------------#
# only a getter
sub id_vector_constructs {
    my $pkg = shift;
    return $pkg->{id_vector_constructs}; # a reference to an array of id_constructs
}
#--------------------------------------------------------------------------------------#
# only a getter
sub chosen_id_vector_construct {
    my $pkg = shift;
    return $pkg->{chosen_id_vector_construct};
}
#--------------------------------------------------------------------------------------#
# only a getter
sub id_oligos {
    my $pkg = shift;
    return $pkg->{id_oligos}; # a reference to an array of id_oligos
}
#--------------------------------------------------------------------------------------#
# getter/setter for array of locus_ids
sub locus_ids {
    my $pkg = shift;

    my $locus_ids = shift if @_; # could be a single locus or an array reference

    # set up array of locus_ids   
    if ($locus_ids) {
	undef $pkg->{locus_ids};
	my @locus_ids = ();
	if (ref($locus_ids) eq 'ARRAY') { @locus_ids = @$locus_ids; }
	else {push @locus_ids, $locus_ids; }
	$pkg->{locus_ids} = \@locus_ids;
    }

    return $pkg->{locus_ids}; # a reference to an array of locus_id entries
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{exists};
    undef $pkg->{id_vector};
    undef $pkg->{id_vector_type}; 
    undef $pkg->{vector_type};
    undef $pkg->{name}; 
    undef $pkg->{type};
    undef $pkg->{frame}; 
    undef $pkg->{description}; 
    undef $pkg->{id_value_supplier};
    undef $pkg->{id_origin_supplier};
    undef $pkg->{id_value_designer};
    undef $pkg->{id_origin_designer};
    undef $pkg->{info_location};
    undef $pkg->{project};
    undef $pkg->{id_project};
    undef $pkg->{design_instance_id};
    undef $pkg->{id_vector_constructs};
    undef $pkg->{reagents};
    undef $pkg->{locus_ids};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub _checkOriginValue {

    my $pkg = shift;
    my $origin = shift;
    my $value = shift;

    # select tablename, pk_column from origin_dict where id_origin = $origin 
    my ($tablename, $pk_column, $description) = $pkg->{se2}->getRow('TRAP::getOrigin', [$origin], $pkg->{dbh2});


    # select * from $tablename where $pk_column = $value
    my $sth = $pkg->{se2}->virtualSqlLib('vector', '_checkOriginValue',
                                        "select * from $tablename where $pk_column = $value");
    my ($check) = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return(1) if $check;
    return(0);
}

#--------------------------------------------------------------------------------------#
sub getName {

    my $pkg = shift;
                                                                                                              
    ($pkg->{name}) = $pkg->{se2}->getRow('TRAP::getVectorName', [$pkg->{id_vector}], $pkg->{dbh2});

    return $pkg->{name} if $pkg->{name};
    return(0);
}
#--------------------------------------------------------------------------------------#

sub getIdVector {

    my $pkg = shift;
                                                                                                              
    print " getting idVector for name $pkg->{name}\n";

     ($pkg->{id_vector}) = $pkg->{se2}->getRow('TRAP::getIdVector', [$pkg->{name}], $pkg->{dbh2});

    return $pkg->{id_vector} if $pkg->{id_vector};
    return(0);
}

#--------------------------------------------------------------------------------------#

sub getIdVectorType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{id_vector_type}) = $pkg->{se2}->getRow('TRAP::getIdVectorType', [$pkg->{vector_type}], $pkg->{dbh2});

    return $pkg->{id_vector_type} if $pkg->{id_vector_type};
    return(0);
}

#--------------------------------------------------------------------------------------#
sub getVectorType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{vector_type}) = $pkg->{se2}->getRow('TRAP::getVectorType', [$pkg->{id_vector_type}], $pkg->{dbh2});

    print "done vector type $pkg->{id_vector_type} $pkg->{vector_type}\n";

    return $pkg->{vector_type} if $pkg->{vector_type};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getProject {

    my $pkg = shift;
                                                                                                             
    ($pkg->{project}) = $pkg->{se2}->getRow('TRAP::getProject', [$pkg->{id_project}], $pkg->{dbh2});

    return $pkg->{project} if $pkg->{project};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getIdProject {

    my $pkg = shift;
                                                                                                             
    ($pkg->{id_project}) = $pkg->{se2}->getRow('TRAP::getIdProject', [$pkg->{project}], $pkg->{dbh2});
    return $pkg->{id_project} if $pkg->{id_project};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getVectorDetails {

    my $pkg = shift;
                                                                                                             

    ($pkg->{name}, $pkg->{type}, $pkg->{id_vector_type}, $pkg->{frame}, $pkg->{description}, $pkg->{id_value_supplier}, $pkg->{id_origin_supplier}, $pkg->{id_value_designer}, $pkg->{id_origin_designer}, $pkg->{info_location}, $pkg->{id_project}, $pkg->{vector_type}, $pkg->{project}, $pkg->{design_instance_id}) = $pkg->{se2}->getRow('TRAP::getVectorDetails', [$pkg->{id_vector}], $pkg->{dbh2});

    return $pkg->{id_vector} if ($pkg->{name});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getReagentType {

    my $pkg = shift;
    my $id_reagent = shift;
                                                                                                             
    my ($reagent) = $pkg->{se2}->getRow('TRAP::getReagentType', [$id_reagent], $pkg->{dbh2});

    return $reagent if $reagent;
    return(0);
} 
#--------------------------------------------------------------------------------------#
sub getIdReagentType {

    my $pkg = shift;
    my $reagent = shift;
                                                                                                             
    my ($id_reagent) = $pkg->{se2}->getRow('TRAP::getIdReagentType', [$reagent], $pkg->{dbh2});
    return $id_reagent if $id_reagent;
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getReagentTypes {

    my $pkg = shift;
                                                                                                             
    my ($reagents) = $pkg->{se2}->getAll('TRAP::getReagentTypes', [$pkg->{id_vector}], $pkg->{dbh2});
    foreach (@$reagents) {
	my $id_reagent_type = $_->[0];
	my $description = $_->[1];
	$pkg->{reagents}->{$id_reagent_type} = $description;
    }

    return $pkg->{reagents} if $pkg->{reagents};
    return(0);
} 
#--------------------------------------------------------------------------------------#
sub getIdVectorConstructs {

    my $pkg = shift;
                                                                                                             
    my ($id_constructs) = $pkg->{se2}->getAll('TRAP::getIdVectorConstructs', [$pkg->{id_vector}], $pkg->{dbh2});
    foreach (@$id_constructs) {
	my $id = $_->[0];
	push @{$pkg->{id_vector_constructs}}, $id;
	if ($_->[1]) { $pkg->{chosen_id_vector_construct} = $id; }
    }

    return $pkg->{id_vector_constructs} if $pkg->{id_vector_constructs};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getIdOligos {

    my $pkg = shift;
                                                                                                             
    my ($id_oligos) = $pkg->{se2}->getAll('TRAP::getIdVectorOligos', [$pkg->{id_vector}], $pkg->{dbh2});
    foreach (@$id_oligos) {
	push @{$pkg->{id_oligos}}, $_->[0];
    }

    return $pkg->{id_oligos} if $pkg->{id_oligos};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getIdLocus {

    my $pkg = shift;
                                                                                                             
    my ($locus_ids) = $pkg->{se2}->getAll('TRAP::getIdVectorLocus', [$pkg->{id_vector}], $pkg->{dbh2});
    foreach (@$locus_ids) {
	push @{$pkg->{locus_ids}}, $_->[0];
    }

    return $pkg->{locus_ids} if $pkg->{locus_ids};
    return(0);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database vector tables
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setVector {

    my $pkg = shift;

    # dont go ahead unless there is a name, type and id_vector_type
    unless ($pkg->{name} && $pkg->{type} && $pkg->{id_vector_type}) {
	print "name|type|id_vector_type must be set\n";
	return(0);
    }

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector.\n DB unchanged.\n";
	return(0);
    }
    print "vector id to use is $id\n";

    $pkg->{se2}->do('TRAP::setVector', [$pkg->{id_vector}, $pkg->{name}, $pkg->{type}, $pkg->{id_vector_type}, $pkg->{frame}, $pkg->{description}, $pkg->{id_value_supplier}, $pkg->{id_origin_supplier}, $pkg->{id_value_designer}, $pkg->{id_origin_designer}, $pkg->{info_location}, $pkg->{id_project}, $pkg->{design_instance_id}], $pkg->{dbh2});

    # add the reagent details to the vector_marker table
    foreach (keys %{$pkg->{reagents}}) {
#        print "  adding reagent $pkg->{id_vector} $_\n";
	$pkg->setVectorMarker($_);
    }

    # add the locus details to the vector_locus table
    &setIdVectorLocus($pkg);

    return($id);
}

#--------------------------------------------------------------------------------------#

sub updateVector {

    my $pkg = shift;
    my %args = @_;

    # dont go ahead unless there is an id_vector, name, type and id_vector_type
    unless ($pkg->{id_vector} && $pkg->{name} && $pkg->{type} && $pkg->{id_vector_type}) {
	print "name|id_vector|type|id_vector_type must be set\n";
	return(0);
    }

    $pkg->{se2}->do('TRAP::updateVector', [$pkg->{name}, $pkg->{type}, $pkg->{id_vector_type}, $pkg->{frame}, $pkg->{description}, $pkg->{id_value_supplier}, $pkg->{id_origin_supplier}, $pkg->{id_value_designer}, $pkg->{id_origin_designer}, $pkg->{info_location}, $pkg->{id_project}, $pkg->{design_instance_id}, $pkg->{id_vector}], $pkg->{dbh2});

    # remove existing vectorMarkers
    $pkg->removeVectorMarkers();

    # add the reagent details to the vector_marker table
    foreach (keys %{$pkg->{reagents}}) {
#        print "  adding reagent $pkg->{id_vector} $_\n";
	$pkg->setVectorMarker($_);
    }

    # deleting current locus details from the vector_locus table
    $pkg->{se2}->do('TRAP::deleteIdVectorLocus', [$pkg->{id_vector}], $pkg->{dbh2});

    # add the locus details to the vector_locus table
    &setIdVectorLocus($pkg);
}

#--------------------------------------------------------------------------------------#
sub removeVectorMarkers {
    my $pkg = shift;

    $pkg->{se2}->do('TRAP::removeVectorMarkers', [$pkg->{id_vector}], $pkg->{dbh2});
}
#--------------------------------------------------------------------------------------#
sub setVectorMarker {
    my $pkg = shift;
    my $id_reagent_type = shift;

    $pkg->{se2}->do('TRAP::setVectorMarker', [$pkg->{id_vector}, $id_reagent_type], $pkg->{dbh2});
}
#--------------------------------------------------------------------------------------#
sub setIdVectorLocus {
    my $pkg = shift;

    foreach my $locus_id(@{$pkg->{locus_ids}}) {
	$pkg->{se2}->do('TRAP::setIdVectorLocus', [$locus_id, $pkg->{id_vector}], $pkg->{dbh2});
    }
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# method to access sequences
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub _getBioId {

    my $pkg = shift;
    my $sequence = shift;
#    print "this is the sequence to use $sequence\n";

    return(0) unless ($sequence);

    # get the next id number from a sequence
    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'getBioId',
                                        "select $sequence.nextval from dual");
    $pkg->{id_vector} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_vector} if $pkg->{id_vector};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
