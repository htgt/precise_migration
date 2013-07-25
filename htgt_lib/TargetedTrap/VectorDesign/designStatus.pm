# designStatus (methods to do with getting and setting vector status details to vector_design database)
#
# Author: Lucy Stebbings (las)
#

package designStatus;

use Exporter;

use strict;

use constant DESIGN_STATUS_ORDERED => 10;

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

	if ($args{-design_id}) { $self->design_id($args{-design_id}); }

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub design_id {
    my $pkg = shift;
    my $design_id = shift if @_;
    if ($design_id) {
	$pkg->{design_id} = $design_id;
	&getStatus($pkg);
    }
    return $pkg->{design_id};
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
sub design_status_id {
    my $pkg = shift;
    my $design_status_id = shift if @_;
    if ($design_status_id) {
	$pkg->{design_status_id} = $design_status_id;
	# get the vector type and set that
	&getStatusType($pkg);
	unless ($pkg->{design_status}) {
	    print "design_status_id $pkg->{design_status_id} not valid\n";
	    undef $pkg->{design_status_id};
	    undef $pkg->{design_status};
	    return(0);
	}
    }
    return ($pkg->{design_status_id}, $pkg->{design_status});
}
#--------------------------------------------------------------------------------------#
sub design_status {
    my $pkg = shift;
    my $design_status = shift if @_;
    if ($design_status) {
	$pkg->{design_status} = $design_status;
	# get the id vector type and set that
	&getIdStatusType($pkg);
	unless ($pkg->{design_status_id}) {
	    print "design_status $pkg->{design_status} not valid\n";
	    undef $pkg->{design_status_id};
	    undef $pkg->{design_status};
	    return(0);
	}
    }
    return ($pkg->{design_status}, $pkg->{design_status_id});
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub getStatusType {

    my $pkg = shift;
                                                                                                              
    # getDesignStatus
    ($pkg->{design_status}) = $pkg->{se3}->getRow('VTRAP::getDesignStatus', [$pkg->{design_status_id}], $pkg->{dbh3});
    return($pkg->{design_status}) if $pkg->{design_status};
    return(0);
}
#--------------------------------------------------------------------------------------#

sub getIdStatusType {

    my $pkg = shift;
                                                                                                              
    # getIdDesignStatus
    ($pkg->{design_status_id}) = $pkg->{se3}->getRow('VTRAP::getIdDesignStatus', [$pkg->{design_status}], $pkg->{dbh3});

  return ($pkg->{design_status_id}) if $pkg->{design_status_id};
    return(0);
}

#--------------------------------------------------------------------------------------#

sub getStatus {

    my $pkg = shift;
                                                                                                              
    # getDesignStatus
    ($pkg->{design_status_id}, $pkg->{design_status}, $pkg->{id_role}, $pkg->{date}) = $pkg->{se3}->getRow('VTRAP::getCurrentDesignStatus', [$pkg->{design_id}], $pkg->{dbh3});
    return($pkg->{design_status}) if $pkg->{design_status};
    return(0);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#


sub setDesignStatus {
    my $pkg = shift;

    print "vecDes status change to $pkg->{design_id} $pkg->{design_status_id} $pkg->{id_role}\n";

    &getCurrentDate($pkg);

    # setDesignStatusNonCurrent
    $pkg->{se3}->do('VTRAP::setDesignStatusNonCurrent', [$pkg->{design_id}], $pkg->{dbh3});

    # addDesignStatus
    $pkg->{se3}->do('VTRAP::addDesignStatus', [$pkg->{design_id}, $pkg->{design_status_id}, $pkg->{date}, $pkg->{id_role}], $pkg->{dbh3});
}

#--------------------------------------------------------------------------------------#
sub getCurrentDate {

    my $pkg = shift;
                                                                                                              
    $pkg->{date} = $pkg->{se3}->getRow('VTRAP::getDate', [], $pkg->{dbh3});
    
}
#-----------------------------------------------------------------------------------#

1;
