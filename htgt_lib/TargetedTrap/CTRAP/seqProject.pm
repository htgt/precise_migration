#  (methods to do with getting sets of sequence data)
#
# Author: Lucy Stebbings (las)
#

package seqProject;

use Exporter;

use strict;
use TargetedTrap::TRAPutils;

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

	if ($args{-se_TRAP}) { $self->se_TRAP($args{-se_TRAP}); } # sets the api for getting data from the qc schema
	if ($args{-dbh_TRAP}) { $self->dbh_TRAP($args{-dbh_TRAP}); } # sets the api for getting data from the qc schema

	if ($args{-ligation}) { $self->ligation($args{-ligation}); } # sets the ligation
	elsif ($args{-clone}) { $self->clone($args{-clone}); }
	elsif ($args{-project}) { $self->project($args{-project}); }

	return $self;
}

#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
# methods to do get/sets and check the data
#--------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------#
sub ligation {
    my $pkg = shift;
    my $ligation = shift if @_;
    if ($ligation) {
	$pkg->{ligation} = $ligation;
	# get all details
	&get_details($pkg);
	return(0) unless $pkg->{ligation};
    }
    return $pkg->{ligation};
}
#--------------------------------------------------------------------------------------#
# get/set clone name
sub clone {
    my $pkg = shift;
    my $clone = shift if @_;

    if ($clone) {
	unless ($pkg->{ligation}) {
	    $pkg->{clone} = $clone;
	    &getLigationFromName($pkg);
	}
    }
    return $pkg->{clone};
}
#--------------------------------------------------------------------------------------#
# get/set project name
sub project {
    my $pkg = shift;
    my $project = shift if @_;

    if ($project) {
	unless ($pkg->{ligation}) {
	    $pkg->{project} = $project;
	    &getLigationFromName($pkg);
	}
    }

    return $pkg->{project};
}
#--------------------------------------------------------------------------------------#
# qc api
sub se_TRAP {
    my $pkg = shift;
    $pkg->{se_TRAP} = shift if @_;
    return $pkg->{se_TRAP};
}
#-----------------------------------------------------------------------------------#
# qc api
sub dbh_TRAP {
    my $pkg = shift;
    $pkg->{dbh_TRAP} = shift if @_;
    return $pkg->{dbh_TRAP};
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# getters for plates
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# returns an array of source_plate_ids
sub SO_plate_ids {
    my $pkg = shift;

    my @plate_ids = ();

    foreach my $plate_id(sort {$a <=> $b} keys %{$pkg->{so_plates}}) {
	push @plate_ids, $plate_id;
    }
    return \@plate_ids;
}

#-----------------------------------------------------------------------------------#
sub SO_plate_name {
    my $pkg = shift;
    my $plate_id = shift;
    return($pkg->{so_plates}->{$plate_id}->{platename});
}
#-----------------------------------------------------------------------------------#
sub SO_plate_id {
    my $pkg = shift;
    my $plate_name = shift;
    return($pkg->{so_plate_ids}->{$plate_name}->{plate_id});
}
#-----------------------------------------------------------------------------------#
sub id_sourceplatemap {
    my $pkg = shift;
    my $plate_id = shift;
    my $well = shift; # eg A1
    return($pkg->{so_plates}->{$plate_id}->{wells}->{$well}->{id_sourceplatemap});
}
#-----------------------------------------------------------------------------------#
sub samplename {
    my $pkg = shift;
    my $plate_id = shift;
    my $well = shift; # eg A1
    return($pkg->{so_plates}->{$plate_id}->{wells}->{$well}->{samplename});
}
#-----------------------------------------------------------------------------------#
sub id_vector_batch {
    my $pkg = shift;
    my $plate_id = shift;
    my $well = shift; # eg A1
    my $dont_get_batch = shift; # 1
    unless ($pkg->{so_plates}->{$plate_id}->{wells}->{$well}->{id_batch}) {
	unless ($dont_get_batch) { &getIdBatch($pkg, $plate_id, $well); }
    }
    return($pkg->{so_plates}->{$plate_id}->{wells}->{$well}->{id_batch});
}
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# DB queries
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub get_details {

    my $pkg = shift;

    ($pkg->{clone}, $pkg->{project}) = $pkg->{se3}->getRow('CTRAP::getProjectFromLigation', [$pkg->{ligation}],$pkg->{dbh3});

    unless ($pkg->{clone}) { 
	$pkg->{ligation} = undef; 
	return(0); 
    }

    # get the plates
    my $plates = $pkg->{se3}->getAll('CTRAP::getSourcePlates', [$pkg->{ligation}],$pkg->{dbh3});

    foreach my $row(@$plates) {
	$pkg->{so_plates}->{$row->[0]}->{platename} = $row->[1];
	$pkg->{so_plate_ids}->{$row->[1]}->{plate_id} = $row->[0];

    }

    # get the id_sourceplatemaps for each well on each plate
    foreach my $plate(keys %{$pkg->{so_plates}}) {
	my $wells = $pkg->{se3}->getAll('CTRAP::getIdSourceplatemaps', [$plate],$pkg->{dbh3});
	foreach my $row(@$wells) {
	    my $well = uc($row->[1]) . $row->[2];
	    my $id_sourceplatemap = $row->[0];
	    my $samplename = $row->[3];
	    $pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_sourceplatemap} = $id_sourceplatemap;
	    $pkg->{so_plates}->{$plate}->{wells}->{$well}->{samplename} = $samplename;
	}
    }

}

#--------------------------------------------------------------------------#
sub getLigationFromName {
    my $pkg = shift;

    my $name;
    if ($pkg->{clone}) { $name = $pkg->{clone}; }
    elsif ($pkg->{project}) { $name = $pkg->{project}; }

    unless ($name) {
	print "project or clone name not set!!\n";
	return(0);
    }

    ($pkg->{ligation}) = $pkg->{se3}->getRow('CTRAP::getLigationFromName', [$name],$pkg->{dbh3});

    &get_details($pkg);

}
#--------------------------------------------------------------------------#

sub getIdBatch {
    my $pkg = shift;
    my $plate = shift;
    my $well = shift;

    # get a list of seqread names  corresponding to the id_sourceplatemap
    my $seqread_names = $pkg->{se3}->getAll('CTRAP::getSeqreadNames', [$pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_sourceplatemap}],$pkg->{dbh3});

    my $name  =  $seqread_names->[0]->[0];

    # use these names to retrieve the id_vector_batch from vector_qc schema (accessed from TRAP)
    # (not all are entered into the qc_seqread table so got to work through them)
    foreach (@$seqread_names) {
	my $name = $_->[0];
	($pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_batch}) = $pkg->{se_TRAP}->getRow('TRAP::getBatchFromSeqread', [$name],$pkg->{dbh_TRAP});
	last if ($pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_batch});
    }
    if ($pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_batch}) { print "batch name $name, id $pkg->{so_plates}->{$plate}->{wells}->{$well}->{id_batch}\n"; }
}

#--------------------------------------------------------------------------#

1;
