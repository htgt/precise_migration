# batch (methods to do with submitting vector batch details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package batch;

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
	if ($args{-id_vector_batch}) { $self->id_vector_batch($args{-id_vector_batch}); } # gets an existing batch

	else {
	    if ($args{-id_vector})            { $self->id_vector($args{-id_vector}); }
	    if ($args{-id_vector_construct})  { $self->id_vector_construct($args{-id_vector_construct}); }
	    if ($args{-batch_name})           { $self->batch_name($args{-batch_name}); }
	    if ($args{-batch_date})           { $self->batch_date($args{-batch_date}); }
	    if ($args{-concentration})        { $self->concentration($args{-concentration}); }
	    if ($args{-id_method})            { $self->id_method($args{-id_method}); }
	    if ($args{-id_value_prepped_by} && 
                $args{-id_origin_prepped_by})  { $self->prepped_by_ids(-id_value_prepped_by  => $args{-id_value_prepped_by},
                                                                       -id_origin_prepped_by => $args{-id_origin_prepped_by}); }
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_vector_batch {
    my $pkg = shift;
    my $id_batch = shift if @_;

    if ($id_batch) {
	$pkg->{id_batch} = $id_batch;

	# see if this vector batch exists in the db already
	# set 'exists' switch if it does
	if (&getBatchDetails($pkg)) {
	    print"vector batch $pkg->{id_batch} exists\n";
	    $pkg->{exists} = 1;
	}
	else {
	    print"can not find vector batch $pkg->{id_batch}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }

    return $pkg->{id_batch};
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
sub id_vector_construct {
    my $pkg = shift;
    my $id_construct = shift if @_;
    if ($id_construct) {
	unless ($id_construct =~ /^\d+$/) {
	    print "id_vector_construct $id_construct must be numerical\n";
	    return;
	}
	$pkg->{id_construct} = $id_construct;
    }
    return $pkg->{id_construct};
}
#--------------------------------------------------------------------------------------#
sub batch_date {
    my $pkg = shift;
    my $batch_date = shift if @_;

    if ($batch_date) {
	$pkg->{batch_date} = TRAPutils::check_date($pkg, $batch_date);
    }

    return $pkg->{batch_date};
}
#--------------------------------------------------------------------------------------#
sub batch_name {
    my $pkg = shift;
    $pkg->{name} = shift if @_;

    return $pkg->{name};
}
#--------------------------------------------------------------------------------------#
sub batchExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub prepped_by_ids {
    my $pkg = shift;
    my %args = @_;

    if ($args{-id_value_prepped_by} || $args{-id_origin_prepped_by}) {
	unless ($args{-id_value_prepped_by} && $args{-id_origin_prepped_by}) { 
	    print "need both origin and value for prepper\n"; 
	    return(0);
	}
	$pkg->{id_value_prepped_by} = $args{-id_value_prepped_by};
	$pkg->{id_origin_prepped_by} = $args{-id_origin_prepped_by};
    }
    return ($pkg->{id_value_prepped_by}, $pkg->{id_origin_prepped_by});
}
#--------------------------------------------------------------------------------------#
sub concentration {
    my $pkg = shift;
    $pkg->{concentration} = shift if @_;
    return $pkg->{concentration};
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
# getter only
sub id_vector_type {
    my $pkg = shift;
    return $pkg->{id_vector_type};
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{id_batch};
    undef $pkg->{exists};
    undef $pkg->{id_vector};
    undef $pkg->{id_vector_type};
    undef $pkg->{id_construct};
    undef $pkg->{batch_date};
    undef $pkg->{name};
    undef $pkg->{id_value_prepped_by};
    undef $pkg->{id_origin_prepped_by};
    undef $pkg->{concentration};
    undef $pkg->{id_method};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getBatchDetails {

    my $pkg = shift;
                                                                                                             
    ($pkg->{id_vector}, $pkg->{id_construct}, $pkg->{batch_date}, $pkg->{name}, $pkg->{id_value_prepped_by}, $pkg->{id_origin_prepped_by}, $pkg->{concentration}, $pkg->{id_method}) = $pkg->{se2}->getRow('TRAP::getVectorBatchDetails', [$pkg->{id_batch}], $pkg->{dbh2});


    ($pkg->{id_vector_type}) = $pkg->{se2}->getRow('TRAP::getBatchType', [$pkg->{id_batch}], $pkg->{dbh2});


    return $pkg->{id_batch} if ($pkg->{id_construct});
    return(0);
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getDate {

    my $pkg = shift;
                                                                                                              
    my ($date) = $pkg->{se2}->getRow('genetrap::getDate', [], $pkg->{dbh2});
    return ($date);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database vector tables
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setVectorBatch {

    my $pkg = shift;

    # dont go ahead unless there is a name, type and id_vector_type
    unless ($pkg->{id_construct}) {
	print "id vector construct must be set\n";
	return(0);
    }

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_batch');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector.\n DB unchanged.\n";
	return(0);
    }

    $pkg->{id_batch} = $id;

    print "vector batch id to use is $id\n";

    unless ($pkg->{batch_date}) {
	$pkg->{batch_date} = &getDate($pkg);
    }
                                                                                                              
    $pkg->{se2}->do('TRAP::setVectorBatch', [$pkg->{id_batch}, $pkg->{id_vector}, $pkg->{id_construct}, $pkg->{batch_date}, $pkg->{name}, $pkg->{id_value_prepped_by}, $pkg->{id_origin_prepped_by}, $pkg->{concentration}, $pkg->{id_method}], $pkg->{dbh2});

    return($id);
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
    $pkg->{id_batch} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_batch} if $pkg->{id_batch};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
