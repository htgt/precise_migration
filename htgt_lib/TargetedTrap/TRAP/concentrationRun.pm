# concentrationRun (methods to do with submitting vector batch concentration experiment run details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package concentrationRun;

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
	if ($args{-id_concentration_run}) { $self->id_concentration_run($args{-id_concentration_run}); } # gets an existing run

	else {
	    if ($args{-run_date}) { $self->run_date($args{-run_date}); }
	    if ($args{-id_role})  { $self->id_role($args{-id_role}); }
	    if ($args{-machine})  { $self->machine($args{-machine}); }
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_concentration_run {
    my $pkg = shift;
    my $id_run = shift if @_;

    if ($id_run) {
	$pkg->{id_run} = $id_run;

	# see if this vector batch exists in the db already
	# set 'exists' switch if it does
	if (&getRun($pkg)) {
	    print"concentration run $pkg->{id_run} exists\n";
	    $pkg->{exists} = 1;
	}
	else {
	    print"can not find concentration run $pkg->{id_run}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }

    return $pkg->{id_run};
}
#--------------------------------------------------------------------------------------#
sub run_date {
    my $pkg = shift;
    my $run_date = shift if @_;

    if ($run_date) {
	$pkg->{run_date} = TRAPutils::check_date($pkg, $run_date);
    }

    return $pkg->{run_date};
}
#--------------------------------------------------------------------------------------#
sub id_role {
    my $pkg = shift;
    $pkg->{id_role} = shift if @_;

    return $pkg->{id_role};
}
#--------------------------------------------------------------------------------------#
sub runExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub machine {
    my $pkg = shift;
    $pkg->{machine} = shift if @_;
    return $pkg->{machine};
}
#--------------------------------------------------------------------------------------#
# getter only
sub id_batch_concentrations {
    my $pkg = shift;
    unless ($pkg->{id_batch_concentrations}) {
	&getIdBatchConcentrations($pkg);
    }
    return $pkg->{id_batch_concentrations};
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{id_role};
    undef $pkg->{exists};
    undef $pkg->{run_date};
    undef $pkg->{machine};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getRun {

    my $pkg = shift;
                                                                                                             
    ($pkg->{id_role}, $pkg->{run_date}, $pkg->{machine}) = $pkg->{se2}->getRow('TRAP::getConcentrationRun', [$pkg->{id_run}], $pkg->{dbh2});
    &getIdBatchConcentrations($pkg);

    return $pkg->{id_run} if ($pkg->{run_date});
    return(0);
}

#--------------------------------------------------------------------------------------#
# gets CURRENT id batch concentrations for a run
sub getIdBatchConcentrations {

    my $pkg = shift;

    my $concentration_ids = $pkg->{se2}->getAll('TRAP::getIdBatchConcentrations', [$pkg->{id_run}], $pkg->{dbh2});

    foreach my $id(@$concentration_ids) {
	push @{$pkg->{id_batch_concentrations}}, $id->[0];
    }
    return($pkg->{id_batch_concentrations});
}
#--------------------------------------------------------------------------------------#
sub getDate {

    my $pkg = shift;
                                                                                                              
    my ($date) = $pkg->{se2}->getRow('genetrap::getDate', [], $pkg->{dbh2});
    return ($date);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database concentration run table
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setRun {

    my $pkg = shift;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_concentration_run');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to concentration_run.\n DB unchanged.\n";
	return(0);
    }

    $pkg->{id_run} = $id;

    print "run id to use is $id\n";

    unless ($pkg->{run_date}) {
	$pkg->{run_date} = &getDate($pkg);
    }
                                                                                                             
    $pkg->{se2}->do('TRAP::setConcentrationRun', [$pkg->{id_run}, $pkg->{id_role}, $pkg->{run_date}, $pkg->{machine}], $pkg->{dbh2});

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
    $pkg->{id_run} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_run} if $pkg->{id_run};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
