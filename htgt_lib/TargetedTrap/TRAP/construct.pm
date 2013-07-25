# construct (methods to do with submitting vector cosntruct details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package construct;

use Exporter;

use TargetedTrap::TRAPutils;
use strict;
use SqlEngine2;

use Carp;

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
	if ($args{-id_vector_construct}) { $self->id_vector_construct($args{-id_vector_construct}); } # gets an existing construct
	elsif ($args{-construct_name}) { $self->construct_name($args{-construct_name}); } # sets the construct name

	unless ($self->{id_vector_construct}) {
	    if ($args{-id_vector})         { $self->id_vector($args{-id_vector}); }
	    if ($args{-id_vector_expected}){ $self->id_vector_expected($args{-id_vector_expected}); }
	    if ($args{-construct_date})    { $self->construct_date($args{-construct_date}); }
	    if ($args{-id_method})         { $self->id_method($args{-id_method}); }
	    if (defined $args{-chosen})    { $self->chosen($args{-chosen}); }
	    if (defined $args{-validated}) { $self->validated($args{-validated}); }
	    if ($args{-project})           { $self->project($args{-project}); }
	    if ($args{-consensus_seq})     { $self->consensus_seq($args{-consensus_seq}); }
	    if ($args{-dbgss_accession})   { $self->dbgss_accession($args{-dbgss_accession}); }
	    if ($args{-id_vector_include}) { $self->id_vector_include($args{-id_vector_include}); }
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_vector_construct {
    my $pkg = shift;
    my $id_construct = shift if @_;

    if ($id_construct) {
	$pkg->{id_construct} = $id_construct;

	# see if this vector construct exists in the db already
	# set 'exists' switch if it does
	if (&getVectorConstructDetails($pkg)) {
	    print "vector construct $pkg->{id_construct} $pkg->{name} exists\n";
	    $pkg->{exists} = 1;
	    &getVectorBatches($pkg);
	    &getIncludes($pkg);
	}
	else {
	    print "can not find vector construct $pkg->{id_construct}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }

    return $pkg->{id_construct};
}
#--------------------------------------------------------------------------------------#
sub construct_name {
    my $pkg = shift;
    $pkg->{name} = shift if @_;
    print "name set to " . $pkg->{name} . "\n";
    return $pkg->{name};
}
#--------------------------------------------------------------------------------------#
sub project {
    my $pkg = shift;
    $pkg->{project} = shift if @_;
    return $pkg->{project};
}
#--------------------------------------------------------------------------------------#
sub id_vector {
    my $pkg = shift;
    my $id_vector = shift if @_;
    if ($id_vector) {
	unless ($id_vector =~ /^\d+$/) {
	    print "id_vector $id_vector must be numerical\n";
	    return;
	}
	$pkg->{id_vector} = $id_vector;
    }
    return $pkg->{id_vector};
}
#--------------------------------------------------------------------------------------#
sub id_vector_expected {
    my $pkg = shift;
    my $id_vector = shift if @_;
    if ($id_vector) {
	unless ($id_vector =~ /^\d+$/) {
	    print "id_vector $id_vector must be numerical\n";
	    return;
	}
	$pkg->{id_vector_expected} = $id_vector;
    }
    return $pkg->{id_vector_expected};
}
#--------------------------------------------------------------------------------------#
sub vectorConstructExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub validated {
    my $pkg = shift;
    my $validated = shift if @_;
    if ($validated) {
	unless ($validated =~ /^(0|1)$/) {
	    print "validated must be 0 or 1\n";
	    return(0);
	}
	$pkg->{validated} = $validated;
    }
    return $pkg->{validated};
}
#--------------------------------------------------------------------------------------#
sub chosen {
    my $pkg = shift;
    my $chosen = shift if @_;
    if ($chosen) {
	unless ($chosen =~ /^(0|1)$/) {
	    print "chosen must be 0 or 1\n";
	    return(0);
	}
	$pkg->{chosen} = $chosen;
    }
    return $pkg->{chosen};
}
#--------------------------------------------------------------------------------------#
sub construct_date {
    my $pkg = shift;
    my $construct_date = shift if @_;

    if ($construct_date) {
	$pkg->{construct_date} = TRAPutils::check_date($pkg, $construct_date);
    }

    return $pkg->{construct_date};
}
#--------------------------------------------------------------------------------------#
sub consensus_seq {
    my $pkg = shift;
    my $seq = shift if @_;
    if ($seq) {
	$seq =~ s/\s+//g; # remove any spaces
	$pkg->{seq} = uc($seq); # make sure its upper case
	if ($pkg->{seq} =~ /[^A|T|G|C|U]/) {
	    print "sequence not valid (can contain A|T|G|C|U only)\n";
	    undef $pkg->{seq};
	    return(0);
	}
    }
    return $pkg->{seq};
}
#--------------------------------------------------------------------------------------#
sub dbgss_accession {
    my $pkg = shift;
    $pkg->{dbgss} = shift if @_;
    return $pkg->{dbgss};
}
#--------------------------------------------------------------------------------------#
sub id_method {
    my $pkg = shift;
    $pkg->{id_method} = shift if @_;
    unless ($pkg->{id_method} =~ /^\d+$/) {
	print "id method $pkg->{id_method} should be numerical\n";
	undef $pkg->{id_method};
	return(0);
    }
    return $pkg->{id_method};
}
#--------------------------------------------------------------------------------------#
sub id_vector_include {
    my $pkg = shift;
    my $id_include = shift if @_; # could be a single vector construct id or an array reference

    # set up a list of includes  
    if ($id_include) {
	undef $pkg->{id_includes};
	my @id_includes = ();
	if (ref($id_include) eq 'ARRAY') { @id_includes = @$id_include; }
	else {push @id_includes, $id_include; }

        # check each id include is genuine
	foreach my $id_include(@id_includes) {
	    my ($name, $project) = &getConstructName($pkg, $id_include);
	    unless ($name || $project) {
		print "id include $id_include not valid\n";
		undef $pkg->{id_includes};
		return(0);
	    }
	    push @{$pkg->{id_includes}}, $id_include;
	}
    }

    return $pkg->{id_includes}; # array of id constructs
}
#--------------------------------------------------------------------------------------#
# getter only
sub id_vector_batches {
    my $pkg = shift;
    return ($pkg->{id_vector_batches}) if ($pkg->{id_vector_batches});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{exists};
    undef $pkg->{chosen};
    undef $pkg->{id_vector};
    undef $pkg->{id_vector_expected};
    undef $pkg->{validated};
    undef $pkg->{name};
    undef $pkg->{construct_date};
    undef $pkg->{project};
    undef $pkg->{seq};
    undef $pkg->{dbgss};
    undef $pkg->{id_method};
    undef $pkg->{id_construct};
    undef $pkg->{id_includes};
    undef $pkg->{id_vector_batches};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getConstructName {

    my $pkg = shift;
    my $id_construct = shift;
                                                                                                              
    my ($name, $project) = $pkg->{se2}->getRow('TRAP::getVectorConstructName', [$id_construct], $pkg->{dbh2});
    return ($name, $project) if ($name || $project);
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getByName {

    my $pkg = shift;

    return unless ($pkg->{name}); 

    # see if this vector construct exists in the db already
    # set 'exists' switch if it does
    my ($count, $result) = &getVectorConstructIdFromName($pkg);

    if ($count && ($count == 1)) {
	$pkg->{id_construct} = $result->[0];
	print "vector construct $pkg->{id_construct} $pkg->{name} exists\n";
	$pkg->{exists} = 1;
	&getVectorConstructDetails($pkg);
	&getVectorBatches($pkg);
	&getIncludes($pkg);
	return($pkg->{id_construct});
    }
    elsif ($count && ($count > 1)) {
	print "more that one vector construct with name $pkg->{name}!\n";
	return($result); # this is a ref to an array of id_vector_constructs
    }
    else {
	print "vector construct $pkg->{name} new\n";
	return(0);
    }
}
#--------------------------------------------------------------------------------------#
sub getVectorConstructIdFromName {
    my $pkg = shift;

    my $count = 0;
    my $ids = [];
                                                                                                              
    my $results = $pkg->{se2}->getAll('TRAP::getVectorConstructIdFromName', [$pkg->{name}], $pkg->{dbh2});
    foreach my $row(@$results) {
	push @$ids, $row->[0];
	$count++;
    }

    if ($count) { return($count, $ids); }
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getVectorConstructDetails {

    my $pkg = shift;
                                                                                                             
    # have to set this to deal with the clob sequence data
    $pkg->{dbh2}->{LongReadLen} = 1000 * 1024;                                                                     
    my @row = $pkg->{se2}->getRow('TRAP::getVectorConstructDetails', [$pkg->{id_construct}], $pkg->{dbh2});

    if (scalar(@row)) {
	$pkg->{id_vector} = $row[0];
	$pkg->{validated} = $row[1];
	$pkg->{name} = $row[2];
	$pkg->{construct_date} = $row[3];
	$pkg->{project} = $row[4];
	$pkg->{seq} = $row[5];
	$pkg->{dbgss} = $row[6];
	$pkg->{id_method} = $row[7]; 
	$pkg->{chosen} = $row[8];
	$pkg->{id_vector_expected} = $row[9];

	return $pkg->{id_construct};
    }
    print "not here\n";
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getIncludes {

    my $pkg = shift;
                                                                                                             
    my ($includes) = $pkg->{se2}->getAll('TRAP::getVectorConstructIncludes', [$pkg->{id_construct}], $pkg->{dbh2});
    foreach (@$includes) {
	push @{$pkg->{id_includes}}, $_->[0];
    }

    return $pkg->{id_includes} if ($pkg->{id_includes});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getVectorBatches {

    my $pkg = shift;
                                                                                                             
    my ($id_batches) = $pkg->{se2}->getAll('TRAP::getVectorBatches', [$pkg->{id_construct}], $pkg->{dbh2});
    foreach (@$id_batches) {
	push @{$pkg->{id_vector_batches}}, $_->[0];
    }

    return $pkg->{id_vector_batches} if $pkg->{id_vector_batches};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getDate {

    my $pkg = shift;
                                                                                                              
    ($pkg->{date}) = $pkg->{se2}->getRow('genetrap::getDate', [], $pkg->{dbh2});
    return ($pkg->{date});
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database vector tables
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setVectorConstruct {

    my $pkg = shift;

    # dont go ahead unless there is a name, type and id_vector_type
    unless ($pkg->{name} || $pkg->{project}) {
	print "name or sequencing project must be set\n";
	return(0);
    }

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_construct');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector construct.\n DB unchanged.\n";
	return(0);
    }
    print "vector construct id to use is $id\n";

    unless ($pkg->{construct_date}) {
	$pkg->{construct_date} = &getDate($pkg);
    }


    # set the construct (and initialies the clob column)
    $pkg->{se2}->do('TRAP::setVectorConstruct', [$pkg->{id_construct}, $pkg->{id_vector}, $pkg->{validated}, $pkg->{name}, $pkg->{construct_date}, $pkg->{project}, $pkg->{dbgss}, $pkg->{id_method}, $pkg->{chosen}, $pkg->{id_vector_expected}], $pkg->{dbh2});

    if ($pkg->{seq}) {
	# select the conseusus_seq for update
	my $sql = "select consensus_seq from vector_construct where id_vector_construct = ? for update";
	my $sth = $pkg->{dbh2}->prepare($sql, {ora_auto_lob => 0} );
	$sth->execute($pkg->{id_construct});
	my ($char_locator) = $sth->fetchrow_array();
	$sth->finish();
	# write the sequence to the clob
	$pkg->{dbh2}->ora_lob_write($char_locator, 1, $pkg->{seq});
    }


    # add the reagent details to the vector_marker table
    foreach (@{$pkg->{id_includes}}) {
#        print "  adding include $_\n";
	$pkg->setInclude($_);
    }

    return($id);
}

#--------------------------------------------------------------------------------------#
sub updateVectorConstruct {

    my $pkg = shift;
    my %args = @_;

    # dont go ahead unless there is an id_vector, name, type and id_vector_type
    unless ($pkg->{id_construct} && ($pkg->{name} || $pkg->{project})) {
	print "id_vector_construct and name or project must be set\n";
	return(0);
    }

    $pkg->{se2}->do('TRAP::updateVectorConstruct', [$pkg->{id_vector}, $pkg->{validated}, $pkg->{name}, $pkg->{construct_date}, $pkg->{project}, $pkg->{seq}, $pkg->{dbgss}, $pkg->{id_method}, $pkg->{chosen}, $pkg->{id_vector_expected}, $pkg->{id_construct}], $pkg->{dbh2});

    # remove existing includes
    $pkg->removeIncludes();

    # add the reagent details to the vector_marker table
    foreach (@{$pkg->{id_includes}}) {
#        print "  adding include $_\n";
	$pkg->setInclude($_);
    }
}
#--------------------------------------------------------------------------------------#
sub removeIncludes {
    my $pkg = shift;

    $pkg->{se2}->do('TRAP::removeVectorIncludes', [$pkg->{id_construct}], $pkg->{dbh2});
}
#--------------------------------------------------------------------------------------#
sub setInclude {
    my $pkg = shift;
    my $id_include = shift;

    $pkg->{se2}->do('TRAP::setVectorInclude', [$pkg->{id_construct}, $id_include], $pkg->{dbh2});
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
    $pkg->{id_construct} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_construct} if $pkg->{id_construct};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
