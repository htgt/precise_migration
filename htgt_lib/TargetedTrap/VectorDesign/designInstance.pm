# designInstance (methods to do with a design instance given a design_instance_id)
#
# Author: Lucy Stebbings (las)
#

package designInstance;

use Exporter;

use strict;
use Carp;

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

	if ($args{-designInstanceId}) { $self->designInstanceId($args{-designInstanceId}); } # sets the id
	else {
	    if ($args{-plate}) { $self->plate($args{-plate}); } # sets the plate
	    if ($args{-well}) { $self->well($args{-well}); } # sets the well
	    if ($args{-designId}) { $self->designId($args{-designId}); } # sets the design id
	    if ($args{-BACs}) { $self->BACs($args{-BACs}); } # sets the list of bacs
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub designInstanceId {
    my $pkg = shift;
    my $designInstanceId = shift if @_;
    if ($designInstanceId) {
	$pkg->{design_instance_id} = $designInstanceId;
        # make sure the object is empty
	&getDesignInstance($pkg);
    }
    return $pkg->{design_instance_id};
}
#--------------------------------------------------------------------------------------#
sub designId {
    my $pkg = shift;
    $pkg->{design_id} = shift if @_;
    return $pkg->{design_id};
}
#--------------------------------------------------------------------------------------#
sub plate {
    my $pkg = shift;
    $pkg->{plate} = shift if @_;
    return $pkg->{plate};
}
#--------------------------------------------------------------------------------------#
sub well {
    my $pkg = shift;
    $pkg->{well} = shift if @_;
    return $pkg->{well};
}
#--------------------------------------------------------------------------------------#
sub source {
    my $pkg = shift;
    $pkg->{source} = shift if @_;
    return $pkg->{source};
}
#--------------------------------------------------------------------------------------#
sub BACs {
    my $pkg = shift;
    $pkg->{bacs} = shift if @_;
    return $pkg->{bacs};
}
#--------------------------------------------------------------------------------------#
sub st_gt {
    my $pkg = shift;
    $pkg->{st_gt} = shift if @_;
    return $pkg->{st_gt};
}
#--------------------------------------------------------------------------------------#
sub tm {
    my $pkg = shift;
    $pkg->{tm} = shift if @_;
    return $pkg->{tm};
}
#--------------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# db queries
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub getDesignInstance {
    my $pkg = shift;

    # get the design instance
    ($pkg->{design_id}, $pkg->{plate}, $pkg->{well}, $pkg->{source}) =  $pkg->{se3}->getRow('VTRAP::getDesignInstance', [$pkg->{design_instance_id}], $pkg->{dbh3});

    unless ($pkg->{design_id}) {
	print "Design Instance not found!\n";
	$pkg->{design_instance_id} = undef;
	return;
    }

    # get the design instance bac ids
    my $bacs =  $pkg->{se3}->getAll('VTRAP::getDesignInstanceBACids', [$pkg->{design_instance_id}], $pkg->{dbh3});

    foreach (@$bacs) { push @{$pkg->{bacs}}, $_->[0]; }

    # get the design instance st_gt status
    my $statuses =  $pkg->{se3}->getAll('VTRAP::getStGtTmStatus', [$pkg->{design_instance_id}], $pkg->{dbh3});

    my ($st, $tm);
    foreach my $status(@$statuses) {
	if (defined($st)) {print "Alert!! 2 entries for st gt status\n"; next; }
	$st = $status->[0];
	$tm = $status->[1];
    }
    if ($st) { $pkg->{st_gt} = 'st'; }
    else { $pkg->{st_gt} = 'gt'; }
    if ($tm) { $pkg->{tm} = 1; }
}
#-----------------------------------------------------------------------------------#
sub makeDesignInstance {
    my $pkg = shift;

    # get an id  from a sequence
    my $id = &_getBioId($pkg, 's_design_instance');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to design_instance.\n DB unchanged.\n";
	return(0);
    }
    print "design instance id to use is $id\n";

    $pkg->{design_instance_id} = $id;

    $pkg->{se3}->do('VTRAP::setDesignInstance', [$pkg->{design_instance_id}, $pkg->{design_id}, $pkg->{plate}, $pkg->{well}, $pkg->{source}], $pkg->{dbh3});

    foreach my $bac(@{$pkg->{bacs}}) {
	# make the bac entry (no bac plate)
        $pkg->{se3}->do('VTRAP::setDesignInstanceBAC', [$pkg->{design_instance_id}, $bac], $pkg->{dbh3});
    }
}
#-----------------------------------------------------------------------------------#
sub _getBioId {

    my $pkg = shift;
    my $sequence = shift;
#    print "this is the sequence to use $sequence\n";

    return(0) unless ($sequence);

    # get the next id number from a sequence
    my $sth = $pkg->{se3}->virtualSqlLib('VTRAP', 'getBioId', "select $sequence.nextval from dual");
    $pkg->{design_instance_id} = $pkg->{se3}->getRow($sth, [], $pkg->{dbh3});

    return $pkg->{design_instance_id} if $pkg->{design_instance_id};
    return(0);
}
#-----------------------------------------------------------------------------------#

1;
