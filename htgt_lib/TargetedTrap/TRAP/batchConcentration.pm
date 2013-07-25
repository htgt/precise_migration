# batchConcentration (methods to do with submitting vector batch concentration experiment details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package batchConcentration;

use Exporter;

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
	if ($args{-id_batch_concentration}) { $self->id_batch_concentration($args{-id_batch_concentration}); } # gets an existing conc

	else {
	    if ($args{-id_vector_batch})            { $self->id_vector_batch($args{-id_vector_batch}); }
	    if ($args{-id_concentration_run})  { $self->id_concentration_run($args{-id_concentration_run}); }
	    if ($args{-iscurrent})           { $self->iscurrent($args{-iscurrent}); }
	    if ($args{-concentration})        { $self->concentration($args{-concentration}); }
	    if ($args{-A260})            { $self->A260($args{-A260}); }
	    if ($args{-A280})            { $self->A280($args{-A280}); }
	    if ($args{-ratio})            { $self->ratio($args{-ratio}); }
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_batch_concentration {
    my $pkg = shift;
    my $id_conc = shift if @_;

    if ($id_conc) {
	$pkg->{id_conc} = $id_conc;

	# see if this batch concentration exists in the db already
	# set 'exists' switch if it does
	if (&getConcDetails($pkg)) {
	    print"id batch concentration $pkg->{id_conc} exists\n";
	    $pkg->{exists} = 1;
	}
	else {
	    print"can not find id batch concentration $pkg->{id_conc}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }

    return $pkg->{id_conc};
}
#--------------------------------------------------------------------------------------#
sub id_vector_batch {
    my $pkg = shift;
    my $id_batch = shift if @_;
    if ($id_batch) {
	unless ($id_batch =~ /^\d+$/) {
	    print "id_vector_batch $id_batch must be numerical\n";
	    return;
	}
	$pkg->{id_batch} = $id_batch;
    }
    return $pkg->{id_batch};
}
#--------------------------------------------------------------------------------------#
sub id_concentration_run {
    my $pkg = shift;
    my $id_run = shift if @_;
    if ($id_run) {
	unless ($id_run =~ /^\d+$/) {
	    print "id_concentration_run $id_run must be numerical\n";
	    return;
	}
	$pkg->{id_run} = $id_run;
    }
    return $pkg->{id_run};
}
#--------------------------------------------------------------------------------------#
sub iscurrent {
    my $pkg = shift;
    my $iscurrent = shift if @_;
    if (defined $iscurrent) {
	unless ($iscurrent =~ /^[0|1]$/) {
	    print "iscurrent $iscurrent must be 0 or 1\n";
	    return;
	}
	$pkg->{iscurrent} = $iscurrent;
    }

    return $pkg->{iscurrent};
}
#--------------------------------------------------------------------------------------#
sub idConcentrationRunExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
# this value is in ng/ul
sub concentration {
    my $pkg = shift;
    $pkg->{concentration} = shift if @_;
    return $pkg->{concentration};
}
#--------------------------------------------------------------------------------------#
sub A260 {
    my $pkg = shift;
    $pkg->{A260} = shift if @_;
    return $pkg->{A260};
}
#--------------------------------------------------------------------------------------#
sub A280 {
    my $pkg = shift;
    $pkg->{A280} = shift if @_;
    return $pkg->{A280};
}
#--------------------------------------------------------------------------------------#
sub ratio {
    my $pkg = shift;
    $pkg->{ratio} = shift if @_;
    return $pkg->{ratio};
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{id_batch};
    undef $pkg->{exists};
    undef $pkg->{id_run};
    undef $pkg->{iscurrent};
    undef $pkg->{concentration};
    undef $pkg->{A260};
    undef $pkg->{A280};
    undef $pkg->{ratio};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getConcDetails {

    my $pkg = shift;
                                                                                                             
    ($pkg->{id_batch}, $pkg->{id_run}, $pkg->{iscurrent}, $pkg->{concentration}, $pkg->{A260}, $pkg->{A280}, $pkg->{ratio}) = $pkg->{se2}->getRow('TRAP::getBatchConcentration', [$pkg->{id_conc}], $pkg->{dbh2});

    return $pkg->{id_conc} if ($pkg->{id_run});
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

sub setBatchConcentration {

    my $pkg = shift;

    # dont go ahead unless there is a batch and run id
    unless ($pkg->{id_batch} && $pkg->{id_run}) {
	print "id vector batch and id_run must be set\n";
	return(0);
    }

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_batch_concentration');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to batch concentration.\n DB unchanged.\n";
	return(0);
    }

    $pkg->{id_conc} = $id;

    print "batch concentration id to use is $id\n";

    # set all old batch conecntrations for this id_vector_batch to not current
    $pkg->{se2}->do('TRAP::updateBatchConcentrationsNotCurrent', [$pkg->{id_batch}], $pkg->{dbh2});

    $pkg->{iscurrent} = 1;
    $pkg->{se2}->do('TRAP::setBatchConcentration', [$pkg->{id_conc}, $pkg->{id_batch}, $pkg->{id_run}, $pkg->{iscurrent}, $pkg->{concentration}, $pkg->{A260}, $pkg->{A280}, $pkg->{ratio}], $pkg->{dbh2});

    return($id);
}

#--------------------------------------------------------------------------------------#
sub updateIsCurrent {
    my $pkg = shift;
    unless ($pkg->{id_conc} && defined($pkg->{iscurrent})) {
	print "can not update iscurrent - id_batch_concentration or iscurrent not set\n";
	return;
    }

    $pkg->{se2}->do('TRAP::updateBatchConcentrationIsCurrent', [$pkg->{iscurrent}, $pkg->{id_conc}], $pkg->{dbh2});
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
    $pkg->{id_conc} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_conc} if $pkg->{id_conc};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
