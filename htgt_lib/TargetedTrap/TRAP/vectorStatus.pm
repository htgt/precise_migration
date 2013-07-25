# vectorStatus (methods to do with getting and setting vector status details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package vectorStatus;

use Exporter;

use TargetedTrap::TRAPutils;
use strict;
use SqlEngine2;

use constant VSTATUS_REQUESTED => 1;
use constant VSTATUS_DESIGNED => 2;
use constant VSTATUS_DESIGN_OK => 3;
use constant VSTATUS_OLIGOS_DESIGNED => 4;
use constant VSTATUS_OLIGO_DESIGN_OK => 5;
use constant VSTATUS_OLIGOS_ORDERED => 6;
use constant VSTATUS_OLIGOS_RECEIVED => 7;
use constant VSTATUS_BACS_ORDERED => 8;
use constant VSTATUS_BACS_RECEIVED => 9;
use constant VSTATUS_VECTOR_MADE => 10;
use constant VSTATUS_CELLS_MADE => 11;
use constant VSTATUS_GOLIGOS_OK => 12;
use constant VSTATUS_CELLS_QCOK => 13;
use constant VSTATUS_CELLS_READY => 14;

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
	    $self->{login} = $args{-login};
	    $self->{se2} = new SqlEngine2();
	    $self->{dbh2} = SqlEngine2::getDbh($self->{login});
	}

	bless $self, $class;

	if ($args{-id_vector}) { $self->id_vector($args{-id_vector}); }
	if ($args{-status})    { $self->status($args{-status}); }
	if ($args{-id_status}) { $self->id_status($args{-id_status}); }
	if ($args{-id_role})   { $self->id_role($args{-id_role}); }
	if ($args{-date})      { $self->date($args{-date}); }

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_vector {
    my $pkg = shift;
    $pkg->{id_vector} = shift if @_;
    return $pkg->{id_vector};
}
#--------------------------------------------------------------------------------------#
sub id_role {
    my $pkg = shift;
    $pkg->{id_role} = shift if @_;
    return $pkg->{id_role};
}
#--------------------------------------------------------------------------------------#
# only use as a getter externally. can be getter/setter internally
sub is_public {
    my $pkg = shift;
    $pkg->{public} = shift if @_;
    return ($pkg->{public});
}
#--------------------------------------------------------------------------------------#
# only use as a getter externally. can be getter/setter internally
sub is_current {
    my $pkg = shift;
    $pkg->{current} = shift if @_;
    return ($pkg->{current});
}
#--------------------------------------------------------------------------------------#
sub id_status {
    my $pkg = shift;
    my $id_status = shift if @_;
    my $skip_get_status = shift if @_;

    if ($id_status) {
	$pkg->{id_status} = $id_status;
	# get the vector type and set that
	unless ($skip_get_status) {
	    $pkg->{status} = undef;
	    &getStatusType($pkg);
	    unless ($pkg->{status}) {
		print "id_status $pkg->{id_status} not valid\n";
		undef $pkg->{id_status};
		undef $pkg->{status};
		return(0);
	    }
	}
    }
    return ($pkg->{id_status}, $pkg->{status});
}
#--------------------------------------------------------------------------------------#
sub status {
    my $pkg = shift;
    my $status = shift if @_;
    my $skip_get_id_status = shift if @_;

    if ($status) {
	$pkg->{status} = $status;
	# get the id vector type and set that
	unless ($skip_get_id_status) {
	    $pkg->{id_status} = undef;
	    &getIdStatusType($pkg);
	    unless ($pkg->{id_status}) {
		print "status $pkg->{status} not valid\n";
		undef $pkg->{id_status};
		undef $pkg->{status};
		return(0);
	    }
	}
    }
    return ($pkg->{status}, $pkg->{id_status});
}
#--------------------------------------------------------------------------------------#
sub date {
    my $pkg = shift;
    my $date = shift if @_;

    if ($date) {
	$pkg->{date} = TRAPutils::check_date($pkg, $date);
    }

    return $pkg->{date};
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{id_vector};
    undef $pkg->{id_status};
    undef $pkg->{status};
    undef $pkg->{id_role};
    undef $pkg->{public};
    undef $pkg->{current};
    undef $pkg->{date};
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub getDate {

    my $pkg = shift;
                                                                                                              
    ($pkg->{date}) = $pkg->{se2}->getRow('genetrap::getDate', [], $pkg->{dbh2});
    return ($pkg->{date});
}
#--------------------------------------------------------------------------------------#
sub getCurrentVectorStatus {

    my $pkg = shift;
                                                                                                              
    ($pkg->{id_status}, $pkg->{date}, $pkg->{id_role}, $pkg->{status}, $pkg->{public}) = $pkg->{se2}->getRow('TRAP::getCurrentVectorStatus', [$pkg->{id_vector}], $pkg->{dbh2});

    $pkg->{current} = 1;

    return($pkg->{id_status}) if $pkg->{id_status};
    return(0);
}
#--------------------------------------------------------------------------------------#
# returns an array of VectorStatus objects
sub getVectorStatusHistory {

    my $pkg = shift;
                                                                                                              
    my ($all_details) = $pkg->{se2}->getAll('TRAP::getVectorStatusHistory', [$pkg->{id_vector}], $pkg->{dbh2});

    foreach my $entry(@$all_details) {
	my $status = new vectorStatus(-se  => $pkg->{se2},
				      -dbh => $pkg->{dbh2});

	$status->id_vector($pkg->{id_vector});
	$status->id_status($entry->[0]);
	$status->date($entry->[1], 1);
	$status->is_current($entry->[2]);
	$status->id_role($entry->[3]);
	$status->status($entry->[4], 1); # 1 = skip get status id
	$status->is_public($entry->[5]);

	push @{$pkg->{history}}, $status;
    }

    return($pkg->{history}) if $pkg->{history};
    return(0);
}
#--------------------------------------------------------------------------------------#
sub getStatusType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{status}, $pkg->{public}) = $pkg->{se2}->getRow('TRAP::getVectorStatusType', [$pkg->{id_status}], $pkg->{dbh2});

    return($pkg->{status}, $pkg->{public}) if $pkg->{status};
    return(0);
}
#--------------------------------------------------------------------------------------#

sub getIdStatusType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{id_status}, $pkg->{public}) = $pkg->{se2}->getRow('TRAP::getIdVectorStatusType', [$pkg->{status}], $pkg->{dbh2});

    return ($pkg->{id_status}, $pkg->{public}) if $pkg->{id_status};
    return(0);
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#


sub setVectorStatus {
    my $pkg = shift;
    my %args = @_;

    unless ($pkg->{date}) { &getDate($pkg); }

    # set any current statuses to not current
    $pkg->{se2}->do('genetrap::setVectorStatusNotCurrent', [$pkg->{id_vector}], $pkg->{dbh2});

    # add the new status
    $pkg->{se2}->do('genetrap::setVectorStatus', [$pkg->{id_vector}, $pkg->{id_status}, $pkg->{date}, $pkg->{id_role}], $pkg->{dbh2});

}

#--------------------------------------------------------------------------------------#

1;
