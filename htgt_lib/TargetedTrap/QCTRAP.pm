# QCTRAP 
# genetrap specific methods for accessing vector design oracle database
# and for transferring data to TRAP
#
# Author: Lucy Stebbings (las)
#

use strict;

package QCTRAP;

use SqlEngine2;
use Carp;

#use constant QC_LOGIN => 'qc_t';
use constant QC_LOGIN => 'qc';
use constant QC_LOGIN_TEST => 'qc_t';
use constant QC_LOGIN_LIVE => 'qc';

# for the sql_lib files...
#use lib '/nfs/team71/dba/las/cvs_cbi4/src/vector_production/sql'; # for testing locally
use lib '/software/team87/lib/sql';

#-----------------------------------------------------------------------------------#
#
# Constructor
#
sub new {
	my $class = shift;
	my %args = @_;

	my $self = {};

	$self->{-login} = $args{-login};

	$self->{se} = new SqlEngine2();
	$self->{dbh} = SqlEngine2::getDbh($self->{-login});

	bless $self, $class;

	return $self;
}

#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
# getters and setters
#-----------------------------------------------------------------------------------#
#-----------------------------------------------------------------------------------#
sub qctest_run_id {
    my $pkg = shift;

    $pkg->{id_run} = shift if @_;
    return $pkg->{id_run};
}
#-----------------------------------------------------------------------------------#
sub design_instance_plate {
    my $pkg = shift;
    $pkg->{plate} = shift if @_;

    return $pkg->{plate};
}
#-----------------------------------------------------------------------------------#
# this is the stage as defined in synthetic_vector not qctest_run
sub synthetic_vector_stage {
    my $pkg = shift;
    $pkg->{vec_stage} = shift if @_;

    return $pkg->{vec_stage};
}
#-----------------------------------------------------------------------------------#
sub drop_run {

    my $pkg = shift;

    return unless ($pkg->{id_run});

    $pkg->{se}->do('QCTRAP::deleteRunPrimers', [$pkg->{id_run}], $pkg->{dbh});
    $pkg->{se}->do('QCTRAP::deleteRunResults', [$pkg->{id_run}], $pkg->{dbh});
    $pkg->{se}->do('QCTRAP::deleteRun', [$pkg->{id_run}], $pkg->{dbh});
}

#-----------------------------------------------------------------------------------#
# this is getting everything picked for a design_instance plate NOT the design plate!! Only OK for simple cases.
# may need to go back to the actual design plate ultimately... see how things go
sub get_distribution_plate {

    my $pkg = shift;

    my $hash = {};

    # returns s.design_well,  c.name,  r.qctest_run_id, s.cassette_formula,  c.id_vector_batch
    my $data = $pkg->{se}->getAll('QCTRAP::get_distribution_plate', [$pkg->{plate}, $pkg->{vec_stage}], $pkg->{dbh});

    foreach (@$data) { 
	my $design_well = $_->[0];
	my $construct_name = $_->[1];
	my $qctest_run_id = $_->[2];
	my $qctest_result_id = $_->[3];
	my $cassette_formula = $_->[4];
	my $id_vector_batch = $_->[5];

	$hash->{$qctest_result_id} = [$construct_name, $design_well, $qctest_run_id, $qctest_result_id, $cassette_formula, $id_vector_batch]; 
    }
    return($hash);
}

#-----------------------------------------------------------------------------------#
#
# begin a transaction
#
sub beginQCTransaction {
	my $self = shift;
	print "Begining Vector QC transaction\n";
	$self->{se}->beginTransaction($self->{dbh});
}

#------------------------------------------------------------------------------------------------#
#
# roll back a transaction
#
sub rollbackQCTransaction {
	my $self = shift;
	print "Rollback Vector QC transaction\n";
	$self->{se}->rollbackTransaction($self->{dbh});
}

#------------------------------------------------------------------------------------------------#
#
# commit a transaction
#
sub commitQCTransaction {
	my $self = shift;
	print "Commit Vector QC transaction\n";
	$self->{se}->commitTransaction($self->{dbh});
}

#------------------------------------------------------------------------------------------------#
1;














