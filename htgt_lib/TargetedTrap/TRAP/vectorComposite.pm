# vectorComposite (methods to do with submitting vectorComposite details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package vectorComposite;

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
	if ($args{-id_vector_composite}) { $self->id_vector_composite($args{-id_vector_composite}); } # gets existing vector_composite entry

	else {
	    unless ($self->{exists}) {
		if ($args{-id_vector}) { $self->id_vector($args{-id_vector}); }
		if ($args{-id_ref_construct}) { $self->id_ref_construct($args{-id_ref_construct}); }
		if ($args{-id_ins_construct}) { $self->id_ins_construct($args{-id_ins_construct}); }
		if ($args{-ref_start}) { $self->ref_start($args{-ref_start}); }
		if ($args{-ref_end}) { $self->ref_end($args{-ref_end}); }
		if ($args{-ins_start}) { $self->ins_start($args{-ins_start}); }
		if ($args{-ins_end}) { $self->ins_end($args{-ins_end}); }
		if ($args{-ins_ori}) { $self->ins_ori($args{-ins_ori}); }
		if ($args{-vector_rxn_order}) { $self->vector_rxn_order($args{-vector_rxn_order}); }
		if ($args{-rxn_name}) { $self->rxn_name($args{-rxn_name}); }
	    }
	}
	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_vector_composite {
    my $pkg = shift;
    my $id_vector_composite = shift if @_;

    if ($id_vector_composite) {
	$pkg->{id_vector_composite} = $id_vector_composite;

	# see if this vector exists in the db already
	# set 'exists' switch if it does
	if (&getVectorCompDetails($pkg)) {
	    print"vector $pkg->{id_vector_composite} exists\n";
	    $pkg->{exists} = 1;
	}
	else {
	    print"can not find vector $pkg->{id_vector_composite}!\n";
	    &clear_all($pkg);
	    return(0);
	}
    }
    return $pkg->{id_vector_composite};
}
#--------------------------------------------------------------------------------------#
sub id_vector {
    my $pkg = shift;
    $pkg->{id_vector} = shift if @_;
    return $pkg->{id_vector};
}
#--------------------------------------------------------------------------------------#
sub vectorCompositeRxnExists {
    my $pkg = shift;
    return ($pkg->{exists}) if ($pkg->{exists});
    return(0);
}
#--------------------------------------------------------------------------------------#
sub id_ref_construct {
    my $pkg = shift;
    $pkg->{id_ref_construct} = shift if @_;
    return $pkg->{id_ref_construct};
}
#--------------------------------------------------------------------------------------#
sub id_ins_construct {
    my $pkg = shift;
    $pkg->{id_ins_construct} = shift if @_;
    return $pkg->{id_ins_construct};
}
#--------------------------------------------------------------------------------------#
sub ref_start {
    my $pkg = shift;
    $pkg->{ref_start} = shift if @_;
    return $pkg->{ref_start};
}
#--------------------------------------------------------------------------------------#
sub ref_end {
    my $pkg = shift;
    $pkg->{ref_end} = shift if @_;
    return $pkg->{ref_end};
}
#--------------------------------------------------------------------------------------#
sub ins_start {
    my $pkg = shift;
    $pkg->{ins_start} = shift if @_;
    return $pkg->{ins_start};
}
#--------------------------------------------------------------------------------------#
sub ins_end {
    my $pkg = shift;
    $pkg->{ins_end} = shift if @_;
    return $pkg->{ins_end};
}
#--------------------------------------------------------------------------------------#
sub ins_ori {
    my $pkg = shift;
    $pkg->{ins_ori} = shift if @_;
    return $pkg->{ins_ori};
}
#--------------------------------------------------------------------------------------#
sub vector_rxn_order {
    my $pkg = shift;
    $pkg->{vector_rxn_order} = shift if @_;
    return $pkg->{vector_rxn_order};
}
#--------------------------------------------------------------------------------------#
sub rxn_name {
    my $pkg = shift;
    $pkg->{rxn_name} = shift if @_;
    return $pkg->{rxn_name};
}
#--------------------------------------------------------------------------------------#
sub clear_all {

    my $pkg = shift;

    undef $pkg->{exists};
    undef $pkg->{id_vector_composite};
    undef $pkg->{id_vector};
    undef $pkg->{id_ref_construct};
    undef $pkg->{id_ins_construct};
    undef $pkg->{ref_start};
    undef $pkg->{ref_end};
    undef $pkg->{ins_start};
    undef $pkg->{ins_end};
    undef $pkg->{ins_ori};
    undef $pkg->{vector_rxn_order};
    undef $pkg->{rxn_name};
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getVectorCompDetails {

    my $pkg = shift;
                                                                                                             

    ($pkg->{id_vector}, $pkg->{id_ref_construct}, $pkg->{id_ins_construct}, $pkg->{ref_start}, $pkg->{ref_end}, $pkg->{ins_start}, $pkg->{ins_end}, $pkg->{ins_ori}, $pkg->{vector_rxn_order}, $pkg->{rxn_name}) = $pkg->{se2}->getRow('TRAP::getVectorCompDetails', [$pkg->{id_vector_composite}], $pkg->{dbh2});

    return $pkg->{id_vector_composite} if ($pkg->{id_vector});
    return(0);
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database vector tables
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setVectorComposite {

    my $pkg = shift;

    # dont go ahead unless there is a name, type and id_vector_type
    unless ($pkg->{id_vector} && $pkg->{id_ref_construct}) {
	print "id_vector and id_ref_construct must be set\n";
	return(0);
    }

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_composite_rxn');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector.\n DB unchanged.\n";
	return(0);
    }
    print "vector composite id to use is $id\n";

    $pkg->{se2}->do('TRAP::setVectorComp', [$id, $pkg->{id_vector}, $pkg->{id_ref_construct}, $pkg->{id_ins_construct}, $pkg->{ref_start}, $pkg->{ref_end}, $pkg->{ins_start}, $pkg->{ins_end}, $pkg->{ins_ori}, $pkg->{vector_rxn_order}, $pkg->{rxn_name}], $pkg->{dbh2});

    return($id);
}

#--------------------------------------------------------------------------------------#

sub updateVectorComposite {

    my $pkg = shift;
    my %args = @_;

    # dont go ahead unless there is an id_vector_composite
    unless ($pkg->{id_vector_composite} && $pkg->{id_vector} && $pkg->{id_ref_construct}) {
	print "id_vector_composite must be set\n";
	return(0);
    }

    $pkg->{se2}->do('TRAP::updateVectorComp', [$pkg->{id_vector}, $pkg->{id_ref_construct}, $pkg->{id_ins_construct}, $pkg->{ref_start}, $pkg->{ref_end}, $pkg->{ins_start}, $pkg->{ins_end}, $pkg->{ins_ori}, $pkg->{vector_rxn_order}, $pkg->{rxn_name}, $pkg->{id_vector_composite}], $pkg->{dbh2});

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
    $pkg->{id_vector_composite} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_vector_composite} if $pkg->{id_vector_composite};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
