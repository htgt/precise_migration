# oligo (methods to do with submitting oligo details to TRAP)
#
# Author: Lucy Stebbings (las)
#

package oligo;

use Exporter;

use strict;
use SqlEngine2;

use Carp;

use constant OTYPE_D5 => 1;
use constant OTYPE_D3 => 2;
use constant OTYPE_U5 => 3;
use constant OTYPE_U3 => 4;
use constant OTYPE_G5 => 5;
use constant OTYPE_G3 => 6;

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
	if ($args{-id_oligo}) { $self->id_oligo($args{-id_oligo}); } # gets an existing oligo

        # should only be provided if we are not getting an existing oligo
	else {
	    if ($args{-name})             { $self->name($args{-name}); }
	    if ($args{-oligo_type})       { $self->oligo_type($args{-oligo_type}); }
	    if ($args{-id_oligo_type})    { $self->id_oligo_type($args{-id_oligo_type}); }
	    if ($args{-feature_id})       { $self->feature_id($args{-feature_id}); }
	    if ($args{-GC_content})       { $self->GC_content($args{-GC_content}); }
	    if ($args{-molecular_weight}) { $self->molecular_weight( $args{-molecular_weight}); }
	    if ($args{-annealing_temp})   { $self->annealing_temp($args{-annealing_temp}); }
	    if ($args{-oligo_seq})        { $self->oligo_seq($args{-oligo_seq}); }
	    if ($args{-id_vector})        { $self->id_vector($args{-id_vector}); }
	    if ($args{-vector_ids})        { $self->vector_ids($args{-vector_ids}); }
	}

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub id_oligo {
    my $pkg = shift;
    my $id_oligo = shift if @_;

    if ($id_oligo) {
	$pkg->{id_oligo} = $id_oligo;
	&getOligo($pkg);
    }

    return $pkg->{id_oligo};
}
#--------------------------------------------------------------------------------------#
sub name {
    my $pkg = shift;
    $pkg->{name} = shift if @_;
    return $pkg->{name};
}
#--------------------------------------------------------------------------------------#
sub feature_id {
    my $pkg = shift;
    $pkg->{feature_id} = shift if @_;
    return $pkg->{feature_id};
}
#--------------------------------------------------------------------------------------#
sub GC_content {
    my $pkg = shift;
    $pkg->{GCcontent} = shift if @_;
    return $pkg->{GCcontent};
}
#--------------------------------------------------------------------------------------#
sub molecular_weight {
    my $pkg = shift;
    $pkg->{molecular_weight} = shift if @_;
    return $pkg->{molecular_weight};
}
#--------------------------------------------------------------------------------------#
sub annealing_temp {
    my $pkg = shift;
    $pkg->{annealing_temp} = shift if @_;
    return $pkg->{annealing_temp};
}
#--------------------------------------------------------------------------------------#
sub oligo_seq {
    my $pkg = shift;
    $pkg->{oligo_seq} = shift if @_;
    return $pkg->{oligo_seq};
}
#--------------------------------------------------------------------------------------#
sub id_vector {
    my $pkg = shift;
    my $id_vector = shift if @_;

    if ($id_vector) {
	$pkg->{id_vector} = $id_vector;
	push @{$pkg->{vector_ids}}, $id_vector;
    }
    return $pkg->{id_vector};
}
#--------------------------------------------------------------------------------------#
# get/set reference to an array of id_vector entries
sub vector_ids {
    my $pkg = shift;
    $pkg->{vector_ids} = shift if @_;
    return $pkg->{vector_ids};
}
#--------------------------------------------------------------------------------------#
sub id_oligo_type {
    my $pkg = shift;
    my $id_oligo_type = shift if @_;
    if ($id_oligo_type) {
	$pkg->{id_oligo_type} = $id_oligo_type;
	# get the oligo type and set that
	&getOligoType($pkg);
	unless ($pkg->{oligo_type}) {
	    print "id_oligo_type $pkg->{id_oligo_type} not valid\n";
	    undef $pkg->{id_oligo_type};
	    undef $pkg->{oligo_type};
	    return(0);
	}
    }
    return ($pkg->{id_oligo_type}, $pkg->{oligo_type});
}
#--------------------------------------------------------------------------------------#
sub oligo_type {
    my $pkg = shift;
    my $oligo_type = shift if @_;
    if ($oligo_type) {
	$pkg->{oligo_type} = $oligo_type;
	print "oligo type is $pkg->{oligo_type}\n";
	# get the id oligo type and set that
	&getIdOligoType($pkg);
	print "oligo type id is $pkg->{id_oligo_type}\n";
	unless ($pkg->{id_oligo_type}) {
	    print "oligo_type $pkg->{oligo_type} not valid\n";
	    undef $pkg->{id_oligo_type};
	    undef $pkg->{oligo_type};
	    return(0);
	}
    }
    return ($pkg->{oligo_type}, $pkg->{id_oligo_type});
}
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to get information from the TRAP database
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub getOligoType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{oligo_type}) = $pkg->{se2}->getRow('TRAP::getOligoType', [$pkg->{id_oligo_type}], $pkg->{dbh2});

    return $pkg->{oligo_type} if $pkg->{oligo_type};
    return(0);
}
#--------------------------------------------------------------------------------------#

sub getIdOligoType {

    my $pkg = shift;
                                                                                                              
    ($pkg->{id_oligo_type}) = $pkg->{se2}->getRow('TRAP::getIdOligoType', [$pkg->{oligo_type}], $pkg->{dbh2});

    return $pkg->{id_oligo_type} if $pkg->{id_oligo_type};
    return(0);
}

#--------------------------------------------------------------------------------------#

sub getOligo {

    my $pkg = shift;

my $discarded;
                                                                                                              
    ($pkg->{id_oligo_type}, $pkg->{oligo_seq}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{feature_id}, $pkg->{name}, $pkg->{oligo_type}) = $pkg->{se2}->getRow('TRAP::getOligo', [$pkg->{id_oligo}], $pkg->{dbh2});

    if ($pkg->{id_oligo}) {
	my $vectors = $pkg->{se2}->getAll('TRAP::getOligoVectors', [$pkg->{id_oligo}], $pkg->{dbh2});

	foreach my $entry(@$vectors) {
	    push @{$pkg->{vector_ids}}, $entry->[0];
	}
	if ((scalar(@$vectors)) == 1) { $pkg->{id_vector} = $vectors->[0]->[0]; }
    }

    return $pkg->{id_oligo} if $pkg->{id_oligo_type};
    return(0);
}

#--------------------------------------------------------------------------------------#
# note this does not get the vector ids!! 
sub getOligoByTypeSeqFeature {

    my $pkg = shift;
                                                                                                              
    my ($id_oligo, $annealing_temp, $molecular_weight, $GCcontent, $name, $oligo_type) = $pkg->{se2}->getRow('TRAP::getOligoByTypeSeqFeature', [$pkg->{id_oligo_type}, $pkg->{oligo_seq}, $pkg->{feature_id}], $pkg->{dbh2});

    if ($id_oligo) { 
	($pkg->{id_oligo}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{name}, $pkg->{oligo_type}) = ($id_oligo, $annealing_temp, $molecular_weight, $GCcontent, $name, $oligo_type);
    }

    return $pkg->{id_oligo} if $pkg->{id_oligo};
    return(0);
}

#--------------------------------------------------------------------------------------#
# note this does not get the vector ids!! 
sub getOligoByTypeSeq {

    my $pkg = shift;
                                                                                                              
    my ($id_oligo, $annealing_temp, $molecular_weight, $GCcontent, $name, $feature_id, $oligo_type) = $pkg->{se2}->getRow('TRAP::getOligoByTypeSeq', [$pkg->{id_oligo_type}, $pkg->{oligo_seq}], $pkg->{dbh2});

    if ($id_oligo) { 
	($pkg->{id_oligo}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{name}, $pkg->{feature_id}, $pkg->{oligo_type}) = ($id_oligo, $annealing_temp, $molecular_weight, $GCcontent, $name, $feature_id, $oligo_type);
    }

    return $pkg->{id_oligo} if $pkg->{id_oligo};
    return(0);
}

#--------------------------------------------------------------------------------------#
sub getByName {

    my $pkg = shift;
                                                                                                              
    my $discarded;

    ($pkg->{id_oligo}, $pkg->{id_oligo_type}, $pkg->{oligo_seq}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{feature_id},  $pkg->{oligo_type}) = $pkg->{se2}->getRow('TRAP::getOligoByName', [$pkg->{name}], $pkg->{dbh2});


    if ($pkg->{id_oligo}) {
	my $vectors = $pkg->{se2}->getAll('TRAP::getOligoVectors', [$pkg->{id_oligo}], $pkg->{dbh2});

	foreach my $entry(@$vectors) {
	    push @{$pkg->{vector_ids}}, $entry->[0];
	}
	if ((scalar(@$vectors)) == 1) { $pkg->{id_vector} = $vectors->[0]->[0]; }
    }

    return $pkg->{id_oligo} if $pkg->{id_oligo};
    return(0);
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to update the TRAP database vector tables
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#

sub setOligo {

    my $pkg = shift;
    my %args = @_;

    unless ($pkg->{id_oligo_type} && $pkg->{oligo_seq}) {
	print "must supply at least id_oligo_type|oligo_seq\n";
	return(0);
    }

    # see if the oligo is already in the tt_oligo table, if so retrieve the id_oligo
    if ($pkg->{feature_id}) {
	&getOligoByTypeSeqFeature($pkg);
    }
    else {
	&getOligoByTypeSeq($pkg);
    }

    unless ($pkg->{id_oligo}) {
	# get an id_oligo from a sequence
	my $id = &_getBioId($pkg, 'seq_tt_oligo');
	unless ($id) {
	    carp "couldn't get the next sequence number to assign to oligo.\n DB unchanged.\n";
	    return(0);
	}
	print "oligo id to use is $id\n";

	$pkg->{id_oligo} = $id;
                                                                                                          
#	print "MW $pkg->{molecular_weight}, GC $pkg->{GCcontent}\n";

	$pkg->{se2}->do('TRAP::setOligo', [$pkg->{id_oligo}, $pkg->{id_oligo_type}, $pkg->{oligo_seq}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{feature_id}, $pkg->{name}], $pkg->{dbh2});
    }

    # link the oligo to the appropriate vector
    foreach my $id_vector(@{$pkg->{vector_ids}}) {
	$pkg->{se2}->do('TRAP::setVectorOligo', [$id_vector, $pkg->{id_oligo}], $pkg->{dbh2});
    }

    return($pkg->{id_oligo});
}

#--------------------------------------------------------------------------------------#

sub updateOligo {

    my $pkg = shift;
    my %args = @_;

    unless ($pkg->{id_oligo}) {
	print "must supply at least id_oligo\n";
	return(0);
    }

    $pkg->{se2}->do('TRAP::updateOligo', [$pkg->{id_oligo_type}, $pkg->{oligo_seq}, $pkg->{annealing_temp}, $pkg->{molecular_weight}, $pkg->{GCcontent}, $pkg->{feature_id}, $pkg->{name}, $pkg->{id_oligo}], $pkg->{dbh2});
    

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
    $pkg->{id_oligo} = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});

    return $pkg->{id_oligo} if $pkg->{id_oligo};
    return(0);
}

#--------------------------------------------------------------------------------------#

1;
