# designInstanceStatus (methods to do with getting and setting instance status details to vector_design database)
#
# Author: Lucy Stebbings (las)
#

package designInstanceStatus;

use Exporter;

use strict;

use constant POST_CRE_PASS => 1;
use constant POST_CRE_FAIL => 2;
use constant POST_CRE_PASS1 => 3;
use constant POST_CRE_PASS2 => 4;
use constant POST_CRE_PASS3 => 5;
use constant POST_GATEWAY_FAIL => 6;
use constant POST_GATEWAY_PASS => 7;
use constant DESIGN_INSTANCE_STATUS_UNDER_CONSTRUCTION => 8;

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

	if ($args{-design_instance_id}) { $self->design_instance_id($args{-design_instance_id}); }

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub design_instance_id {
    my $pkg = shift;
    my $design_instance_id = shift if @_;
    if ($design_instance_id) {
	$pkg->{design_instance_id} = $design_instance_id;
	&getStatus($pkg);
    }
    return $pkg->{design_instance_id};
}
#--------------------------------------------------------------------------------------#
sub id_role {
    my $pkg = shift;
    $pkg->{id_role} = shift if @_;
    return $pkg->{id_role};
}
#--------------------------------------------------------------------------------------#
# getter only
sub date {
    my $pkg = shift;
    return $pkg->{date};
}
#--------------------------------------------------------------------------------------#
sub design_instance_status_id {
    my $pkg = shift;
    my $design_instance_status_id = shift if @_;
    if ($design_instance_status_id) {
	$pkg->{design_instance_status_id} = $design_instance_status_id;
	# get the vector type and set that
	&getStatusType($pkg);
	unless ($pkg->{design_instance_status}) {
	    print "design_instance_status_id $pkg->{design_instance_status_id} not valid\n";
	    undef $pkg->{design_instance_status_id};
	    undef $pkg->{design_instance_status};
	    return(0);
	}
    }
    return ($pkg->{design_instance_status_id}, $pkg->{design_instance_status});
}
#--------------------------------------------------------------------------------------#
sub design_instance_status {
    my $pkg = shift;
    my $design_instance_status = shift if @_;
    if ($design_instance_status) {
	$pkg->{design_instance_status} = $design_instance_status;
	# get the id vector type and set that
	&getIdStatusType($pkg);
	unless ($pkg->{design_instance_status_id}) {
	    print "design_instance_status $pkg->{design_instance_status} not valid\n";
	    undef $pkg->{design_instance_status_id};
	    undef $pkg->{design_instance_status};
	    return(0);
	}
    }
    return ($pkg->{design_instance_status}, $pkg->{design_instance_status_id});
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub getStatusType {

    my $pkg = shift;
                                                                                                              
    # getDesignInstanceStatus
    ($pkg->{design_instance_status}) = $pkg->{se3}->getRow('VTRAP::getDesignInstanceStatus', [$pkg->{design_instance_status_id}], $pkg->{dbh3});
    return($pkg->{design_instance_status}) if $pkg->{design_instance_status};
    return(0);
}
#--------------------------------------------------------------------------------------#

sub getIdStatusType {

    my $pkg = shift;
                                                                                                              
    # getIdDesignInstanceStatus
    ($pkg->{design_instance_status_id}) = $pkg->{se3}->getRow('VTRAP::getIdDesignInstanceStatus', [$pkg->{design_instance_status}], $pkg->{dbh3});

  return ($pkg->{design_instance_status_id}) if $pkg->{design_instance_status_id};
    return(0);
}

#--------------------------------------------------------------------------------------#

sub getStatus {

    my $pkg = shift;
                                                                                                              
    # getDesignInstanceStatus
    ($pkg->{design_instance_status_id}, $pkg->{design_instance_status}, $pkg->{id_role}, $pkg->{date}) = $pkg->{se3}->getRow('VTRAP::getCurrentDesignInstanceStatus', [$pkg->{design_instance_id}], $pkg->{dbh3});
    return($pkg->{design_instance_status}) if $pkg->{design_instance_status};
    return(0);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#


sub setDesignInstanceStatus {
    my $pkg = shift;

    print "vecDes instance status change to $pkg->{design_instance_id} $pkg->{design_instance_status_id} $pkg->{id_role}\n";

    &getCurrentDate($pkg);

    # setDesignInstanceStatusNonCurrent
    $pkg->{se3}->do('VTRAP::setDesignInstanceStatusNonCurrent', [$pkg->{design_instance_id}], $pkg->{dbh3});

    # addDesignInstanceStatus
    $pkg->{se3}->do('VTRAP::addDesignInstanceStatus', [$pkg->{design_instance_id}, $pkg->{design_instance_status_id}, $pkg->{date}, $pkg->{id_role}], $pkg->{dbh3});
}

#--------------------------------------------------------------------------------------#
sub getCurrentDate {

    my $pkg = shift;
                                                                                                              
    $pkg->{date} = $pkg->{se3}->getRow('VTRAP::getDate', [], $pkg->{dbh3});
    
}
#-----------------------------------------------------------------------------------#

1;
