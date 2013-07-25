#
# BTRAP   (methods for accessing the genetrap bio-database)
#
# Author: Lucy Stebbings (las)
#
#

use strict;

package BTRAP;

use SqlEngine2;
use Carp;

use TargetedTrap::TRAP::vector;
use TargetedTrap::TRAP::vectorStatus;
 
#use constant TRAP_LOGIN => 'gene_trap_t';
use constant TRAP_LOGIN => 'gene_trap'; ############################### LIVE!!!! ##############################
use constant TRAP_LOGIN_LIVE => 'gene_trap';
use constant TRAP_LOGIN_TEST => 'gene_trap_t';

use constant NO_DEBUG => 0;
use constant DEBUG => 1;


use constant ORIGIN_ELECTRO => 1;
use constant ORIGIN_REGROW => 2;
use constant ORIGIN_TEAM87 => 3;
use constant ORIGIN_TEAM => 4;
use constant ORIGIN_EXT_ORG => 5;
use constant ORIGIN_COMPANY => 6;
       
use constant REGROW_OPEN => 11;
use constant REGROW_CLOSED => 12;

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


#
# Constructor
#
sub new
{
	my $class = shift;
	my %args = @_;

	my $self = {};

	$self->{-login} = $args{-login};

	$self->{se2} = new SqlEngine2();
	$self->{dbh2} = SqlEngine2::getDbh($self->{-login});
	bless $self, $class;
	return $self;
}

#-----------------------------------------------------------------------------------#
# getter
sub se { 
    my $pkg = shift;
    return $pkg->{se2};
}
#-----------------------------------------------------------------------------------#
# getter
sub dbh { 
    my $pkg = shift;
    return $pkg->{dbh2};
}
#-----------------------------------------------------------------------------------#
sub getDate {

    my $pkg = shift;
                                                                                                              
    my ($date) = $pkg->{se2}->getRow('genetrap::getDate', [], $pkg->{dbh2});
    return ($date);
}

sub getProjects {

    my $pkg = shift;
                                                                                                              
    my ($projects) = $pkg->{se2}->getAll('genetrap::getProjects', [], $pkg->{dbh2});
    return ($projects);
}

sub getProject {

    my $pkg = shift;
    my $id = shift;
                                                                                                             
    my ($name) = $pkg->{se2}->getRow('genetrap::getProject', [$id], $pkg->{dbh2});
    return ($name);
}
sub getIdProject {

    my $pkg = shift;
    my $name = shift;
    print "name is $name\n";
                                                                                                             
    my $id = $pkg->{se2}->getRow('genetrap::getIdProject', [$name], $pkg->{dbh2});
    return ($id);
}

sub getVectors {

    my $pkg = shift;
    my $type_id = shift;
    my ($vectors);     

    if ($type_id) {
        ($vectors) = $pkg->{se2}->getAll('TRAP::getTypeVectors', [$type_id], $pkg->{dbh2});
    }
    elsif (defined $type_id) {
	return;
    }
    else {
        ($vectors) = $pkg->{se2}->getAll('TRAP::getVectors', [], $pkg->{dbh2});
    }
    return ($vectors);
}

sub getVectorTypes {

    my $pkg = shift;
                                                                                                              
    my ($vectorTypes) = $pkg->{se2}->getAll('genetrap::getVectorTypes', [], $pkg->{dbh2});
    return ($vectorTypes);
}

sub getVectorType {

    my $pkg = shift;
    my $id = shift;
                                                                                                              
    my ($vectorType) = $pkg->{se2}->getRow('genetrap::getVectorType', [$id], $pkg->{dbh2});

    return ($vectorType);
}

sub getIdVectorType {

    my $pkg = shift;
    my $desc = shift;
                                                                                                              
    my ($idVectorType) = $pkg->{se2}->getRow('genetrap::getIdVectorType', [$desc], $pkg->{dbh2});

    return ($idVectorType);
}

sub getVectorLoci {

    my $pkg = shift;
    my $id_vector = shift;
                                                                                                              
    my ($loci) = $pkg->{se2}->getAll('genetrap::getVectorloci', [$id_vector], $pkg->{dbh2});
    return ($loci);
}

sub getVectorConstructs {

    my $pkg = shift;
    my $vector_id = shift;
    my $validated = shift;

    my ($vectorConstructs);
                                    
    if ($validated && $validated eq 'validated') {
        ($vectorConstructs) = $pkg->{se2}->getAll('TRAP::getValidVectorConstructs', [$vector_id, 1], $pkg->{dbh2});
    }
    elsif ($validated && $validated eq 'unvalidated') {
        ($vectorConstructs) = $pkg->{se2}->getAll('TRAP::getValidVectorConstructs', [$vector_id, 0], $pkg->{dbh2});
    }
    else {
        ($vectorConstructs) = $pkg->{se2}->getAll('TRAP::getVectorConstructs', [$vector_id], $pkg->{dbh2});
    }
    return ($vectorConstructs);
}

sub getVectorBatchesFromConstruct {
    my $pkg = shift;
    my $id = shift;
                                                                                                             
    my ($batches) = $pkg->{se2}->getAll('genetrap::getVectorBatchesFromConstruct', [$id], $pkg->{dbh2});
    return ($batches);
}

sub getVectorIdFromName {
    my $pkg = shift;
    my $name = shift;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getVectorIdFromName', [$name], $pkg->{dbh2});
    return ($id);
}

sub getVectorNameFromId {
    my $pkg = shift;
    my $id = shift;
                                                                                                              
    my ($name) = $pkg->{se2}->getRow('genetrap::getVectorNameFromId', [$id], $pkg->{dbh2});
    return ($name);
}

sub getVectorConFromBatch {
    my $pkg = shift;
    my $id = shift;
                                                                                                             
    my ($id_construct) = $pkg->{se2}->getRow('genetrap::getVectorConFromBatch', [$id], $pkg->{dbh2});
    return ($id_construct);
}

sub getVectorStatus {
    my $pkg = shift;
    my $id = shift;
                                                                                                             
    my $status_details = $pkg->{se2}->getRow('genetrap::getVectorStatus', [$id], $pkg->{dbh2});
    return ($status_details);
}

sub setVectorStatus {
    my $pkg = shift;
    my %args = @_;

    my $isCurrent = 1;
                                                                                                             
    unless ($args{-date}) {
	$args{-date} = $pkg->getDate();
    }

    # set any current statuses to not current
    $pkg->{se2}->do('genetrap::setVectorStatusNotCurrent', [$args{-id_vector}], $pkg->{dbh2});

    # add the new status
    $pkg->{se2}->do('genetrap::setVectorStatus', [$args{-id_vector}, $args{-id_status}, $args{-date}, $args{-id_role}], $pkg->{dbh2});

}


sub getFeatureTypes {

    my $pkg = shift;
                                                                                                              
    my ($oligoTypes) = $pkg->{se2}->getAll('genetrap::getOligoTypes', [], $pkg->{dbh2});
    return ($oligoTypes);
}

sub getFeatureTypeInfo {

    my $pkg = shift;
    my $id_oligo_type = shift;
                                                                                                              
    my ($description, $annealed_seq)  = $pkg->{se2}->getRow('genetrap::getOligoTypeInfo', [$id_oligo_type], $pkg->{dbh2});
    return ($description, $annealed_seq);
}

sub getFeatureTypeByDesc {

    my $pkg = shift;
    my $oligo_desc = shift;
                                                                                                              
    my ($id, $annealed_seq)  = $pkg->{se2}->getRow('genetrap::getOligoTypeByDesc', [$oligo_desc], $pkg->{dbh2});
    return ($id, $annealed_seq);
}

sub getFeatures {

    my $pkg = shift;
    my $id_oligo_type = shift;

    my ($oligos);

    if ($id_oligo_type) {
	print "getting oligos\n";
        ($oligos) = $pkg->{se2}->getAll('genetrap::getOligos', [$id_oligo_type], $pkg->{dbh2});
    }
    else {
	print "getting all oligos\n";
        ($oligos) = $pkg->{se2}->getAll('genetrap::getAllOligos', [], $pkg->{dbh2});
    }
    return ($oligos);
}

sub getFeatureInfo {

    my $pkg = shift;
    my $id_oligo = shift;

    my ($name, $seq, $strand, $start, $end, $build) = $pkg->{se2}->getRow('genetrap::getOligoInfo', [$id_oligo], $pkg->{dbh2});

    return ($name, $seq, $strand, $start, $end, $build);
}

sub getFeatureBySeq {

    my $pkg = shift;
    my $seq = shift;

    my ($id, $name, $strand, $start, $end, $build) = $pkg->{se2}->getRow('genetrap::getOligoBySeq', [$seq], $pkg->{dbh2});
    return ($id, $name, $strand, $start, $end, $build);
}

sub getFeatureByName {

    my $pkg = shift;
    my $name = shift;

    my ($id, $seq, $strand, $start, $end, $build) = $pkg->{se2}->getRow('genetrap::getOligoByName', [$name], $pkg->{dbh2});
    return ($id, $seq, $strand, $start, $end, $build);
}

sub setFeatureType {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_oligo_type');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $args{-description}.\n DB unchanged.\n";
	return(0);
    }
    print "oligo type id to use is $id\n";

    $pkg->{se2}->do('genetrap::setOligoType', [$id, $args{-description}, $args{-annealed_sequence}], $pkg->{dbh2});
    return($id);
}

sub setFeature {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_TT_oligo');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $args{-name}.\n DB unchanged.\n";
	return(0);
    }
    print "oligo id to use is $id\n";

    $pkg->{se2}->do('genetrap::setOligo', [$id, $args{-id_oligo_type}, $args{-oligo_sequence}, $args{-name}, $args{-chr_strand}, $args{-ensembl_start}, $args{-ensembl_end}, $args{-ensembl_build}], $pkg->{dbh2});

    return($id);
}

sub setVectorFeature {

    my $pkg = shift;
    my %args = @_;

    $pkg->{se2}->do('genetrap::setVectorOligo', [$args{-id_vector}, $args{-id_oligo}], $pkg->{dbh2});
}

sub setVectorReagent {

    my $pkg = shift;
    my %args = @_;

    $pkg->{se2}->do('genetrap::setVectorMarker', [$args{-id_vector}, $args{-id_reagent_type}], $pkg->{dbh2});
}

sub removeVectorReagent {

    my $pkg = shift;
    my %args = @_;

    unless ($args{-id_vector} && $args{-id_reagent_type}) {
	print "you must supply an id_vector and id_reagent_type!\n";
	return;
    }

    $pkg->{se2}->do('genetrap::removeVectorMarker', [$args{-id_vector}, $args{-id_reagent_type}], $pkg->{dbh2});
}




sub getCellIdFromName {
    my $pkg = shift;
    my $name = shift;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getCellIdFromName', [$name], $pkg->{dbh2});
    return ($id);
}

sub getCodeFromSampleId {
    my $pkg = shift;
    my $id = shift;
                                                                                                              
    my ($name) = $pkg->{se2}->getRow('genetrap::getCodeFromSampleId', [$id], $pkg->{dbh2});
    return ($name);
}

sub getCellIdFromSampleId {
    my $pkg = shift;
    my $id = shift;
                                                                                                              
    my ($id_cell) = $pkg->{se2}->getRow('genetrap::getCellIdFromSampleId', [$id], $pkg->{dbh2});
    return ($id_cell);
}

sub getLabIdFromName {
    my $pkg = shift;
    my ($name, $id_org) = @_;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getLabIdFromName', [$name, $id_org], $pkg->{dbh2});
    return ($id);
}

sub getUserIdFromName {
    my $pkg = shift;
    my ($name, $id_lab) = @_;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getUserIdFromName', [$name, $id_lab], $pkg->{dbh2});
    return ($id);
}

sub getOrgIdFromName {
    my $pkg = shift;
    my $name = shift;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getOrgIdFromName', [$name], $pkg->{dbh2});
    return ($id);
}

sub getVectorInfo {

    my $pkg = shift;
    my $id_vector = shift;

    my ($name, $type, $frame, $info_location, $desc, $supplier, $supplier_ori, $designer, $designer_ori, $id_vtype, $vtype, $id_target) = $pkg->{se2}->getRow('genetrap::getVectorInfo', [$id_vector], $pkg->{dbh2});

    return ($name, $type, $frame, $info_location, $desc, $supplier, $supplier_ori, $designer, $designer_ori, $id_vtype, $vtype, $id_target);

}

sub getVector {

    my $pkg = shift;
    my $id_vector = shift;

    my ($name, $type, $id_vector_type, $frame, $desc, $supplier, $supplier_ori, $designer, $designer_ori, $info_location, $id_project, $vector_type, $project) = $pkg->{se2}->getRow('genetrap::getVector', [$id_vector], $pkg->{dbh2});

    return ($name, $type, $id_vector_type, $frame, $desc, $supplier, $supplier_ori, $designer, $designer_ori, $info_location, $id_project, $vector_type, $project);

}

sub getVectorNameTypeFromId {

    my $pkg = shift;
    my $id_vector = shift;

    my ($name, $id_vector_type) = $pkg->{se2}->getRow('genetrap::getVectorNameTypeFromId', [$id_vector], $pkg->{dbh2});

    return ($name, $id_vector_type);
}


sub getVectorConstructInfo {

    my $pkg = shift;
    my $id_vector = shift;

    # have to set this to deal with the clob sequence data
    $pkg->{dbh2}->{LongReadLen} = 1000 * 1024;                                                                     
    my $vector_constructs = $pkg->{se2}->getAll('genetrap::getVectorConstructInfo', [$id_vector], $pkg->{dbh2});

    return ($vector_constructs);

}

sub getVectorConstruct {

    my $pkg = shift;
    my $id_construct = shift;

    my ($name, $project) = $pkg->{se2}->getRow('genetrap::getVectorConstruct', [$id_construct], $pkg->{dbh2});

    return ($name, $project);

}

sub getVectorConstructDetails {

    my $pkg = shift;
    my $id_construct = shift;

    # have to set this to deal with the clob sequence data
    $pkg->{dbh2}->{LongReadLen} = 1000 * 1024;                                                                     
    my ($id_vector, $validated, $name, $date, $project, $seq, $dbgss, $id_method) = $pkg->{se2}->getRow('genetrap::getVectorConstructDetails', [$id_construct], $pkg->{dbh2});

    return ($id_vector, $validated, $name, $date, $project, $seq, $dbgss, $id_method);

}

sub updateConstruct {

    my $pkg = shift;
    my %args = @_;

    $pkg->{se2}->do('genetrap::updateConstruct', [$args{-id_vector}, $args{-validated}, $args{-construct_name}, $args{-construct_date}, $args{-project}, $args{-consensus_seq}, $args{-dbgss_accession}, $args{-id_method}, $args{-id_vector_construct}], $pkg->{dbh2});

    return($args{-id_vector_construct});
}

sub setConstruct {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_construct');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $args{-construct_name}/$args{-project}.\n DB unchanged.\n";
	return(0);
    }
    print "construct id to use is $id\n";

    $pkg->{se2}->do('genetrap::setConstruct', [$id, $args{-id_vector}, $args{-validated}, $args{-construct_name}, $args{-construct_date}, $args{-project}, $args{-dbgss_accession}, $args{-id_method}], $pkg->{dbh2});

    if ($args{-consensus_seq}) {
	# select the conseusus_seq for update
	my $sql = "select consensus_seq from vector_construct where id_vector_construct = ? for update";
	my $sth = $pkg->{dbh2}->prepare($sql, {ora_auto_lob => 0} );
	$sth->execute($id);
	my ($char_locator) = $sth->fetchrow_array();
	$sth->finish();
	# write the sequence to the clob
	$pkg->{dbh2}->ora_lob_write($char_locator, 1, $args{-consensus_seq});
    }

    return($id);
}

sub getIncludedVectors {
    my $pkg = shift;
    my $id_construct = shift;

    my ($constructs) = $pkg->{se2}->getAll('genetrap::getIncludedVectors', [$id_construct], $pkg->{dbh2});

    return($constructs);
}

sub setInclude {

    my $pkg = shift;
    my %args = @_;

    $pkg->{se2}->do('genetrap::setInclude', [$args{-id_vector_construct}, $args{-id_vector_include}], $pkg->{dbh2});
}

sub removeInclude {

    my $pkg = shift;
    my %args = @_;

    unless ($args{-id_vector_construct} && $args{-id_vector_include}) {
	print "you must supply an id_vector_construct and id_vector_include!\n";
	return;
    }

    $pkg->{se2}->do('genetrap::removeInclude', [$args{-id_vector_construct}, $args{-id_vector_include}], $pkg->{dbh2});
}

sub setVectorInfo {

    my $pkg = shift;
    my ($name, $type, $frame, $info_location, $desc, $supplier, $supplier_ori, $designer, $designer_ori) = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $name.\n DB unchanged.\n";
	return(0);
    }
    print "vector id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setVectorInfo', [$id, $name, $type, $frame, $info_location, $desc, $supplier, $supplier_ori, $designer, $designer_ori], $pkg->{dbh2});

    return($id);
}

sub setVector {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $args{-name}.\n DB unchanged.\n";
	return(0);
    }
    print "vector id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setVector', [$id, $args{-name}, $args{-type}, $args{-id_vector_type}, $args{-frame}, $args{-description}, $args{-id_value_supplier}, $args{-id_origin_supplier}, $args{-id_value_designer}, $args{-id_origin_designer}, $args{-info_location}, $args{-id_project}], $pkg->{dbh2});

    return($id);
}

sub updateVector {

    my $pkg = shift;
    my %args = @_;

    $pkg->{se2}->do('genetrap::updateVector', [$args{-name}, $args{-type}, $args{-id_vector_type}, $args{-frame}, $args{-description}, $args{-id_value_supplier}, $args{-id_origin_supplier}, $args{-id_value_designer}, $args{-id_origin_designer}, $args{-info_location}, $args{-id_project}, $args{-id_vector}], $pkg->{dbh2});
}

sub setVectorType {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_type');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector type.\n DB unchanged.\n";
	return(0);
    }
    print "vector id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setVectorType', [$id, $args{-vector_type}], $pkg->{dbh2});

    return($id);
}

sub setVectorConValid {

    my $pkg = shift;
    my $id = shift;
    $pkg->{se2}->do('genetrap::setVectorConValid', [$id], $pkg->{dbh2});
}

sub getVectorBatches {

    my $pkg = shift;
    my $id_vector = shift;
                                                                                                              
    my ($id_vector_batches) = $pkg->{se2}->getAll('genetrap::getVectorBatches', [$id_vector], $pkg->{dbh2});
    return ($id_vector_batches);

}

sub getVectorBatchesWithName {

    my $pkg = shift;
    my $id_vector = shift;
    my $vector_name = shift;
                                                                                                              
    my ($id_vector_batches) = $pkg->{se2}->getAll('genetrap::getVectorBatchesWithName', [$id_vector, $vector_name], $pkg->{dbh2});
    return ($id_vector_batches);

}

sub getVectorBatchInfo {

    my $pkg = shift;
    my $id_vector_batch = shift;
                                                                                                              
    my ($id_vector, $batch_date, $batch_name, $concentration, $prepped_by, $prepped_by_ori) = $pkg->{se2}->getRow('genetrap::getVectorBatchInfo', [$id_vector_batch], $pkg->{dbh2});
    return ($id_vector, $batch_date, $batch_name, $concentration, $prepped_by, $prepped_by_ori);

}

sub setVectorBatchInfo {

    my $pkg = shift;
    my ($id_vector, $date, $name, $conc, $prepped_by, $prepped_by_ori) = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_batch');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $id_vector batch.\n DB unchanged.\n";
	return(0);
    }
    print "vector_batch id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setVectorBatchInfo', [$id, $id_vector, $date, $name, $conc, $prepped_by, $prepped_by_ori], $pkg->{dbh2});

    return($id);
}

sub setBatch {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_batch');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to construct $args{-id_vector_construct} batch.\n DB unchanged.\n";
	return(0);
    }
    print "vector_batch id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setBatch', [$id, $args{-id_vector}, $args{-id_vector_construct}, $args{-batch_date}, $args{-batch_name}, $args{-id_value_prepped_by}, $args{-id_origin_prepped_by}, $args{-concentration}, $args{-id_method}], $pkg->{dbh2});

    return($id);
}

sub setVectorBatchInfo2 {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_batch');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector batch.\n DB unchanged.\n";
	return(0);
    }
    print "vector_batch id to use is $id\n";
                                                                                                              
    unless ($args{-date}) {
	$args{-date} = $pkg->getDate();
    }

    # remove the id_vector input later when everything has been swapped over to new tables
    $pkg->{se2}->do('genetrap::setVectorBatchInfo2', [$id, $args{-id_vector}, $args{-id_vector_construct}, $args{-date}, $args{-batch_name}, $args{-conc}, $args{-prepped_by}, $args{-prepped_by_ori}, $args{-id_method}], $pkg->{dbh2});

    return($id);
}

sub setVectorConstructInfo {

    my $pkg = shift;
    my %args = @_;

    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_vector_construct');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to vector construct.\n DB unchanged.\n";
	return(0);
    }
    print "vector_construct id to use is $id\n";

    unless ($args{-date}) {
	$args{-date} = $pkg->getDate();
    }
                                                                                                              
    $pkg->{se2}->do('genetrap::setVectorConstructInfo', [$id, $args{-id_vector}, $args{-validated}, $args{-project}, $args{-dbgss}, $args{-id_method}, $args{-construct_name}], $pkg->{dbh2});

    if ($args{-seq}) {
	# select the conseusus_seq for update
	my $sql = "select consensus_seq from vector_construct where id_vector_construct = ? for update";
	my $sth = $pkg->{dbh2}->prepare($sql, {ora_auto_lob => 0} );
	$sth->execute($id);
	my ($char_locator) = $sth->fetchrow_array();
	$sth->finish();
	# write the sequence to the clob
	$pkg->{dbh2}->ora_lob_write($char_locator, 1, $args{-seq});
    }

    return($id);
}

sub getCells {

    my $pkg = shift;
                                                                                                              
    my ($cells) = $pkg->{se2}->getAll('genetrap::getCells', [], $pkg->{dbh2});
    return ($cells);

}

sub getCellSamples {

    my $pkg = shift;
    my $id_cell_line = shift;
                                                                                                              
    # gets id_cell_line_sample, date_registered, passage_number, id_value,id_origin, cell_line_sample_name
    my ($samples) = $pkg->{se2}->getAll('genetrap::getCellSamples', [$id_cell_line], $pkg->{dbh2});
    return ($samples);

}


# gets the info for a cell line - an original stock
sub getCellInfo {

    my $pkg = shift;
    my $id_cell_line = shift;

    my ($name, $description, $info_location, $designer, $designer_ori, $id_value, $id_origin, $sample_name) = $pkg->{se2}->getRow('genetrap::getCellInfo', [$id_cell_line], $pkg->{dbh2});

    return ($name, $description, $info_location, $designer, $designer_ori, $id_value, $id_origin, $sample_name);

}

# must register a cell line sample when a cell line concept is registered 
sub setCellInfo {

    my $pkg = shift;
    my ($name, $is_transformed, $desc, $info_location, $designer, $designer_ori, $supplier, $supplier_ori, $prepped_by, $prepped_by_ori, $equals_origin, $passage, $date, $sample_name) = @_;

                                                                                                              
    # get an id_cell_line from a sequence
    my $id = &_getBioId($pkg, 'seq_cell_line');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $name.\n DB unchanged.\n";
	return(0);
    }
    print "cell_line id to use is $id\n";

    # get an id_cell_line_sample from a sequence
    my $id2 = &_getBioId($pkg, 'seq_cell_line_sample');
    unless ($id2) {
	carp "couldn't get the next sequence number to assign to cell_line_sample.\n DB unchanged.\n";
	return(0);
    }
    print "cell_line_sample id to use is $id2\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setCellInfo', [$id, $is_transformed, $name, $desc, $info_location, $designer, $designer_ori, $supplier, $supplier_ori], $pkg->{dbh2});

    $pkg->{se2}->do('genetrap::setCellSampleInfo', [$id2, $id, $prepped_by, $prepped_by_ori, $equals_origin, $passage, $date, $sample_name], $pkg->{dbh2});

    return($id, $id2);

}

# enter a new cell sample
sub setCellSampleInfo {

    my $pkg = shift;
    my ($id_cell_line, $id_value, $id_origin, $equals_origin, $passage, $date, $name, $origin_cell_line_sample, $comments, $regrown) = @_;
    my $prepped_by = "";


    # get an id_cell_line_sample from a sequence
    my $id = &_getBioId($pkg, 'seq_cell_line_sample');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to $id_cell_line.\n DB unchanged.\n";
	return(0);
    }
    print "cell_line_sample id to use is $id\n";

    my $id2;


    if ($regrown) {
        print "this is a regrow value $id_value origin $id_origin\n";

        # get an id_regrow from a sequence
	$id2 = &_getBioId($pkg, 'seq_regrow');
	unless ($id2) {
	    carp "couldn't get the next sequence number to assign to regrow.\n DB unchanged.\n";
	    return(0);
	}
	print "regrow id to use is $id2\n";
	$prepped_by = $id_value;  # role for the person who did the regrow
	$id_origin = 2;   # set the origin to 'regrow' in the cell line sample table
                          # the id role of the person prepping will go in regrow status
        $id_value = $id2; # value in cell line sample table now holds the regrow id
	print "now... prepped by $prepped_by origin $id_origin value $id_value\n";
    }

                                                                                                             
    $pkg->{se2}->do('genetrap::setCellSampleInfo', [$id, $id_cell_line, $id_value, $id_origin, $equals_origin, $passage, $date, $name], $pkg->{dbh2});

    if ($regrown) {
	my $id_selection ="";
	my $selection_conc ="";
	my $is_mixed = 0;
	my $is_current = 1;
	$pkg->{se2}->do('genetrap::setRegrowInfo', [$id2, $origin_cell_line_sample, $id_selection, $selection_conc, $is_mixed, $comments], $pkg->{dbh2});
	$pkg->{se2}->do('genetrap::setRegrowStatusInfo', [$id2, $regrown, $date, $is_current, $prepped_by], $pkg->{dbh2});
    }
    return($id, $id2);

}

sub getSuppliers {

    my $pkg = shift;

    my @suppliers = ();
      
 # not sure where to get the list of suppliers from...

    my ($suppliers) = $pkg->{se2}->getAll('genetrap::getCompanies', [], $pkg->{dbh2});

    return ($suppliers);
}

sub getSelectionIdFromBatch {
    my $pkg = shift;
    my $batch = shift;
    my ($id) = $pkg->{se2}->getRow('genetrap::getSelectionIdFromBatch', [$batch], $pkg->{dbh2});
    return ($id);
}

sub getSelections {

    my $pkg = shift;
    my ($selections) = $pkg->{se2}->getAll('genetrap::getSelections', [], $pkg->{dbh2});
    return ($selections);
}

sub getReagentTypes {

    my $pkg = shift;
    my ($selections) = $pkg->{se2}->getAll('genetrap::getReagentTypes', [], $pkg->{dbh2});
    return ($selections);
}

sub getReagentList {

    my $pkg = shift;
    my $id_vector = shift;

    my $reagents = $pkg->{se2}->getAll('genetrap::getReagentList', [$id_vector], $pkg->{dbh2});
    return ($reagents);
}

sub getReagentBatches {

    my $pkg = shift;
    my $id_reagent_type = shift;

    my ($selections) = $pkg->{se2}->getAll('genetrap::getReagentBatches', [$id_reagent_type], $pkg->{dbh2});
    return ($selections);
}

sub getReagentType {

    my $pkg = shift;
    my $id_reagent_type = shift;

    my ($reagent) = $pkg->{se2}->getRow('genetrap::getReagentType', [$id_reagent_type], $pkg->{dbh2});
    return ($reagent);
}

sub getIdReagentType {

    my $pkg = shift;
    my $reagent_type = shift;

    my ($id_reagent_type) = $pkg->{se2}->getRow('genetrap::getIdReagentType', [$reagent_type], $pkg->{dbh2});
    return ($id_reagent_type);
}

sub getSelectionBatchNos {

    my $pkg = shift;
       
    my ($selections) = $pkg->{se2}->getAll('genetrap::getSelectionBatchNos', [], $pkg->{dbh2});
    return ($selections);
}

sub setSelection {

    my $pkg = shift;
    my ($batch, $date, $supplier, $type, $activity) = @_;

    # supplier is a name for now but will be a supplier id eventually
                                                                                                              
    # get an id_selection from a sequence
    my $id = &_getBioId($pkg, 'seq_selection');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to selection media batch.\n DB unchanged.\n";
	return(0);
    }
    print "selection media batch id to use is $id\n";

    print "adding $id $batch $date $supplier $type $activity\n";
    $pkg->{se2}->do('genetrap::setSelection', [$id, $batch, $date, $supplier, $type, $activity], $pkg->{dbh2});

    return($id);
}

sub setReagent {


    my $pkg = shift;
    my %args = @_;

    # get an id_selection from a sequence
    my $id = &_getBioId($pkg, 'seq_reagent');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to reagent batch.\n DB unchanged.\n";
	return(0);
    }
    print "reagent batch id to use is $id\n";

    $pkg->{se2}->do('genetrap::setReagent', [$id, $args{-batch}, $args{-date}, $args{-idSupplier}, $args{-idType}, $args{-activity}], $pkg->{dbh2});

    return($id);
}

sub setReagentType {


    my $pkg = shift;
    my %args = @_;

    # get an id_selection from a sequence
    my $id = &_getBioId($pkg, 'seq_reagent_type');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to reagent type.\n DB unchanged.\n";
	return(0);
    }
    print "reagent type id to use is $id\n";

    $pkg->{se2}->do('genetrap::setReagentType', [$id, $args{-description}], $pkg->{dbh2});

    return($id);
}


sub setReagentUse {

    my $pkg = shift;
    my %args = @_;

    # get an id_selection from a sequence
    my $id = &_getBioId($pkg, 'seq_reagent_use');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to reagent use.\n DB unchanged.\n";
	return(0);
    }
    print "reagent use id to use is $id\n";

    $pkg->{se2}->do('genetrap::setReagentUse', [$id, $args{-id_reagent}, $args{-reagent_concentration}, $args{-use_date}, $args{-comments}, $args{-id_origin}, $args{-value}], $pkg->{dbh2});

    return($id);
}

sub getExternalPeople {

    my $pkg = shift;

    my @people = ();
                                                                                                            
    # select all the external users and their labs ordered by org name, lab name, user name
    my ($people) = $pkg->{se2}->getAll('genetrap::getExtLabUsers', [], $pkg->{dbh2});
    # get things in this order...  u.id_user, o.name, l.name, u.name, u.title, l.id_lab_pi, l.

    return ($people);
}

sub getExtUsers {

    my $pkg = shift;
    my $id_lab = shift;
                                                                                                            
    # select all the external users from an external lab
    my ($users) = $pkg->{se2}->getAll('genetrap::getExtUsers', [$id_lab], $pkg->{dbh2});

    return ($users);
}

sub getExtLabInfo {
    my $pkg = shift;
    my $id_lab = shift;

    my ($org_name, $lab_name, $lab_address, $lab_telephone, $lab_email, $pi_name, $pi_title, $pi_telephone, $pi_email) = $pkg->{se2}->getRow('genetrap::getExtLabInfo', [$id_lab], $pkg->{dbh2});
    return ($org_name, $lab_name, $lab_address, $lab_telephone, $lab_email, $pi_name, $pi_title, $pi_telephone, $pi_email);

}
sub getLabPI {
    my $pkg = shift;
    my $id_lab = shift;

    my ($id_pi) = $pkg->{se2}->getRow('genetrap::getLabPI', [$id_lab], $pkg->{dbh2});
    return ($id_pi);

}

sub getExtUser {
    my $pkg = shift;
    my $id_user = shift;

    my ($org_name, $lab_name, $user_name, $user_title) = $pkg->{se2}->getRow('genetrap::getExtUser', [$id_user], $pkg->{dbh2});

    return ($org_name, $lab_name, $user_name, $user_title);

   }


sub setExtLab {
    my $pkg = shift;
    my ($id_org, $name, $address, $telephone, $email, $pi_name, $pi_title, $pi_email, $pi_telephone) = @_;
    unless ($name) { $name = "$pi_name group"; }
                                                                                                              
    # get an id_lab from a sequence for the lab
    my $id = &_getBioId($pkg, 'seq_ext_lab');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to new external lab.\n DB unchanged.\n";
	return(0);
    }
    print "external lab id to use is $id\n";

    # get an id_usr from a sequence for the pi (a user)
    my $id2 = &_getBioId($pkg, 'seq_ext_user');
    unless ($id2) {
	carp "couldn't get the next sequence number to assign to new lab pi.\n DB unchanged.\n";
	return(0);
    }
    print "external pi user id to use is $id2\n";
                                                                                                              
    # set the lab without the pi id
    print "doing1 $id, $id_org, , $name, $address, $telephone, $email\n";
    $pkg->{se2}->do('genetrap::setExtLab', [$id, $id_org, "", $name, $address, $telephone, $email], $pkg->{dbh2});
    # set the pi entry to the external user table
    print "doing2 $id2, $id, $pi_name, $pi_title, $pi_email, $pi_telephone\n";
    $pkg->{se2}->do('genetrap::setExtUser', [$id2, $id, $pi_name, $pi_title, $pi_email, $pi_telephone], $pkg->{dbh2});
    # add the pi id to the lab entry
    print "doing3 $id2, $id\n";
    $pkg->{se2}->do('genetrap::updatePIid', [$id2, $id], $pkg->{dbh2});

    return($id, $id2);
}


sub setExtUser {
    my $pkg = shift;
    my ($id_lab, $name, $title, $email, $telephone) = @_;

                                                                                                              
    # get an id_user from a sequence
    my $id = &_getBioId($pkg, 'seq_ext_user');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to new external user.\n DB unchanged.\n";
	return(0);
    }
    print "external user id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setExtUser', [$id, $id_lab, $name, $title, $email, $telephone], $pkg->{dbh2});

    return($id);

}

sub setExtOrg {
    my $pkg = shift;
    my ($name, $address, $telephone, $email, $is_commercial) = @_;

                                                                                                              
    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_ext_org');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to new external organisation.\n DB unchanged.\n";
	return(0);
    }
    print "external org id to use is $id\n";
                                                                                                              
    $pkg->{se2}->do('genetrap::setExtOrg', [$id, $name, $address, $telephone, $email, $is_commercial], $pkg->{dbh2});

    return($id);

}


sub updateBioInfo {

    my $pkg = shift;
    my ($table, $pk_col, $pk_val, $field, $value) = @_;

    $value = "\'$value\'";
    $pk_val = "\'$pk_val\'";
    print "setting $field to $value where $pk_col is $pk_val in $table\n";

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'updateInfo',
                                             "update $table
                                              set $field = $value
                                              where $pk_col=$pk_val");
    $pkg->{se2}->do($sth, [], $pkg->{dbh2});
}

sub updateBioInfo2 {

    my $pkg = shift;
    my ($table, $field1, $field1_val,  $field2, $field2_val, $field_set, $value) = @_;

    $value = "\'$value\'";
    $field1_val = "\'$field1_val\'";
    $field2_val = "\'$field2_val\'";
    print "setting $field_set to $value where $field1 is $field1_val and  $field2 is $field2_val in $table\n";

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'updateInfo',
                                             "update $table
                                              set $field_set = $value
                                              where $field1=$field1_val
                                              and  $field2=$field2_val");
    $pkg->{se2}->do($sth, [], $pkg->{dbh2});
}

sub _getBioId {

    my $pkg = shift;
    my $sequence = shift;
#    print "this is the sequence to use $sequence\n";

    return(0) unless ($sequence);

    # get the next id number from a sequence
    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'getBioId',
                                        "select $sequence.nextval from dual");
    my $seq = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});
    return($seq);
}



sub getExtLabs {

    my $pkg = shift;
    my $id_org = shift;
                                                                                                              
    my ($labs) = $pkg->{se2}->getAll('genetrap::getExtLabs', [$id_org], $pkg->{dbh2});
    return ($labs);

}

# gets non-commercial organisations
sub getExtOrgs {

    my $pkg = shift;
                                                                                                              
    my ($orgs) = $pkg->{se2}->getAll('genetrap::getExtOrgs', [], $pkg->{dbh2});
    return ($orgs);
}

sub getExtOrg {

    my $pkg = shift;
    my $id_org = shift;
                                                                                                              
    my ($name, $add, $email, $tel) = $pkg->{se2}->getRow('genetrap::getExtOrg', [$id_org], $pkg->{dbh2});
    return ($name, $add, $email, $tel);
}

sub getRegrowRole {

    my $pkg = shift;
    my ($id_regrow, $status) = @_;
                                                                                                              
    my ($role) = $pkg->{se2}->getRow('genetrap::getRegrowRole', [$id_regrow, $status], $pkg->{dbh2});
    return ($role);
}

sub getSubEntityStatusId {

    my $pkg = shift;
    my %args = @_;
                                                                                                              
    my ($id) = $pkg->{se2}->getRow('genetrap::getSubEntityStatusId', [$args{-entityType}, $args{-entityContentsType}, $args{-description}], $pkg->{dbh2});
    return($id);
}

#  electro script


# get the most recent electroporation ids with 2 or 3 letters
sub getElectros {

    my $pkg = shift;
                                                                                                              
    my ($electros) = $pkg->{se2}->getAll('genetrap::getElectros', [], $pkg->{dbh2});

    return ($electros);

}

# get the current regrows
sub getCurrentRegrows {

    my $pkg = shift;
                                                                                                              
    my ($regrows) = $pkg->{se2}->getAll('genetrap::getCurrentRegrows', [], $pkg->{dbh2});

    return ($regrows);

}

# get the electroporation code corresponding to an id
sub getElectroCode {

    my $pkg = shift;
    my $id_electro = shift;
                                                                                                              
    my ($electro) = $pkg->{se2}->getRow('genetrap::getElectroCode', [$id_electro], $pkg->{dbh2});
    return ($electro);

}

sub getIdElectro {

    my $pkg = shift;
    my $electro_code = shift;

    my ($id_electro) = $pkg->{se2}->getRow('genetrap::getIdElectro', [$electro_code], $pkg->{dbh2});
    return ($id_electro);

}

sub getElectro {

    my $pkg = shift;
    my $electro_code = shift;
    my ($electro, $by, $date) = $pkg->{se2}->getRow('genetrap::getElectro', [$electro_code], $pkg->{dbh2});
    return ($electro, $by, $date);


}

sub setElectro {

    my $pkg = shift;
    my %args = @_;

     if ($args{electro_code}) { print "electro code is $args{electro_code}\n" }
     if ($args{id_cell_sample}) { print "id_cell_sample is $args{id_cell_sample}\n" }
     if ($args{id_vector_batch}) { print "id_vector_batch is $args{id_vector_batch}\n" }
     if ($args{vector_vol}) { print "vector_vol is $args{vector_vol}\n" }
     if ($args{id_selection}) { print "id_selection is $args{id_selection}\n" }
     if ($args{selection_conc}) { print "selection_conc is $args{selection_conc}\n" }
     if ($args{number_cells}) { print "number_cells is $args{number_cells}\n" }
     if ($args{plate_density}) { print "plate_density is $args{plate_density}\n" }
     if ($args{comments}) { print "comments is $args{comments}\n" }
     if ($args{id_status}) { print "id_status is $args{id_status}\n" }
     if ($args{id_role}) { print "id_role is $args{id_role}\n" }
     if ($args{date}) { print "date is $args{date}\n" }
     if (defined $args{dish_no}) { print "dish_no is $args{dish_no}\n" }

    unless ($args{electro_code} && 
            $args{id_cell_sample} && 
            $args{number_cells} &&
            $args{plate_density} &&
            $args{id_status} &&
            $args{id_role} &&
            defined $args{dish_no}) {
	print "incomplete data passed to setElectro\n";
	return ;
    }

    # check the electro code doesn't already exits
    my $id_electro = $pkg->getIdElectro($args{electro_code});
    if ($id_electro) {
	carp "Electroporation code $args{electro_code} is already in use\n";
	return(0);
    }

    unless ($args{date}) { $args{date} = &getDate($pkg); }

    # set the status flag
    my $is_current = 1;

    #get the electroporation id to use from a sequence
    $id_electro = &_getBioId($pkg, 'seq_electroporation');
    unless ($id_electro) {
	carp "couldn't get the next sequence number to assign to new electroporation.\n DB unchanged.\n";
	return(0);
    }
    print "electroporation id to use is $id_electro\n";

    # enter the data into the electroporation table
    $pkg->{se2}->do('genetrap::setElectroporation', [$id_electro, $args{electro_code}, $args{id_cell_sample}, $args{id_selection}, $args{selection_conc}, $args{number_cells}, $args{plate_density}, $args{comments}], $pkg->{dbh2});
    # enter the data into the electroporation status table
    $pkg->{se2}->do('genetrap::setElectroporationStatus', [$id_electro, $args{id_status}, $args{date}, $is_current, $args{id_role}], $pkg->{dbh2});

    # enter the data into the electro_vector_batch table if there is any (may do this in a separate call if multi)
    if ($args{id_vector_batch} && $args{vector_vol}) {
        $pkg->setElectroVectorBatch(-id_electro      => $id_electro,
                                    -id_vector_batch => $args{id_vector_batch},
                                    -vector_vol      => $args{vector_vol});
    }

    # set up the human readable id entries that will be used to keep track of electroporation specific ids
    # list of entities that need an id
    my @entities = (65, 67, 55, 57, 58, 4, 5, 'cell line');
    my $table;
    foreach my $entity(@entities) {
	if ($entity eq 'cell line') { $entity = 0; $table = 'cell_line'; }
	else { $table = 'entity_type'; }
	my $start_number = 1;
	if ($entity eq '55') { $start_number = $args{dish_no} + 1; }
        # get the next unique identifier from a sequence 
        my $id2 = &_getBioId($pkg, 'seq_human_readable');
        $pkg->{se2}->do('genetrap::addHrEntry', [$id2, $id_electro, $start_number, $table, $entity], $pkg->{dbh2});
    }
        
    return($id_electro);
}

#-------------------------------------------------------------------------------------------------------#

sub setElectroVectorBatch {

    my $pkg = shift;
    my %args = @_;

    # enter data into the electro_vector_batch table
    $pkg->{se2}->do('genetrap::setElectroVectorBatch', [$args{-id_electro}, $args{-id_vector_batch}, $args{-vector_vol}], $pkg->{dbh2});

}

#-------------------------------------------------------------------------------------------------------#
# get cell lines and cell line samples associated with the electroporation
sub getElectroLines {

    my $pkg = shift;
    my $id_electro = shift;
    my $electro_code = shift;

    my $cell_lines = {};
    my ($lines) = $pkg->{se2}->getAll('genetrap::getElectroLines', [$electro_code, ORIGIN_ELECTRO], $pkg->{dbh2});
    foreach my $row(@$lines) {
       next unless ($row->[0] && $row->[1]);
       $cell_lines->{$row->[0]}->{cell_line_sample} = $row->[1];
       # if there is an electro code, format the cell line name as well
       if ($electro_code) {
           $cell_lines->{$row->[0]}->{cell_line_code} = $electro_code . (sprintf "%04d", $row->[0]);
       }
    }
    return($cell_lines);
}
 
#-------------------------------------------------------------------------------------------------------#
# get cell lines and cell line samples associated with the electroporation
sub getLinesFromNameElectro {

    my $pkg = shift;
    my %args = @_;

    # get the id_cell_line
    my ($lines) = $pkg->{se2}->getAll('genetrap::getLinesFromNameElectro', [$args{-electro_code}, $args{-cell_line_name}, ORIGIN_ELECTRO], $pkg->{dbh2});

#    my $id_cell_line = $lines1->[0]->[0];

    # gets id_cell_line_sample, date_registered, passage_number, id_value, id_origin, cell_line_sample_name
    # want id_cell_line, id_cell_line_sample, date_registered, cell_line_sample_name only
#    my ($lines2) = $pkg->{se2}->getAll('genetrap::getCellSamples', [$id_cell_line], $pkg->{dbh2});


#    my $lines = [];
#    my $i = 0;
#    foreach my $line(@$lines2) {
#        $lines->[$i]->[0] = $id_cell_line; 
#        $lines->[$i]->[1] = $lines2->[$i]->[0]; 
#        $lines->[$i]->[2] = $lines2->[$i]->[1]; 
#        $lines->[$i]->[3] = $lines2->[$i]->[5]; 
#	$i++;
#    }

    return($lines);
}
 
#-------------------------------------------------------------------------------------------------------#

# get cell lines and cell line samples associated with the electroporation
sub getLinesFromName {

    my $pkg = shift;
    my %args = @_;

    # want id_cell_line, id_cell_line_sample, date_registered, cell_line_sample_name
    my ($lines) = $pkg->{se2}->getAll('genetrap::getLinesFromName', [$args{-cell_line_name}], $pkg->{dbh2});


    return($lines);
}
 
#-------------------------------------------------------------------------------------------------------#

sub get_name_from_origin_value {

    my ($pkg, $pkg2, $pkg3, $value, $ori) = @_;
    my ($value1, $value2);
    my ($person, $org_name, $lab_name, $string, $name, $email, $title) = ("","","","","","","");

    if (($ori == 2) ||                    # team 87 person, value is a id_regrow
        ($ori == 3)) {                    # team 87 person, value is a id_role
        # get the id_role for the id_regrow
	if ($ori == 2) {
	    ($value1) = &getRegrowRole($pkg, $value, '12');
            unless ($value1) {
                carp "couldnt get the role for the regrow $value\n";
		return(0);
	    }
	    if ($value1) { $value = $value1; }	    
	}
        # the value is an id_role not an id_person so get the id_person
	$value2 = $pkg3->getIdPerson($value);
	if ($value2) { $value = $value2; }
	else { 
            carp "couldnt get the id person from the id role $value\n";
	    return(0);
	}
        # get the name from the idPerson
	$person = $pkg2->getUser(-idPerson => $value);
	unless ($person) { 
            carp "couldnt get the person object with idperson $value\n";
	    return(0);
	}

	$name = $person->getForename() . " " . $person->getSurname();
	$email = $person->getEmail();
	unless ($name) { 
            carp "couldnt get the name for the person with idPerson $value\n";
	    return(0);
	}
        $string = "$email, $name";
        return ($string, $name, $email);
    }

    elsif ($ori == 4) {                 # non team 87 person, value is a id_person
        # get the name from the idPerson
	($person) = $pkg2->getUser(-idPerson => $value);
	unless ($person) { 
            carp "couldnt get the person object with idperson $value\n";
	    return(0);
	}

	$name = $person->getForename() . " " . $person->getSurname();
	$email = $person->getEmail();
	unless ($name) { 
            carp "couldnt get the name for the person with idPerson $value\n";
	    return(0);
	}
        $string = "$email, $name";
        return ($string, $name, $email);
    }

    elsif ($ori == 5) {                 # value is an id_user
        # get the name from the external_user table in the bio database
        ($org_name, $lab_name, $name, $title) = &getExtUser($pkg, $value);
	unless ($name) { 
            carp "couldnt get the details for the person with idUser $value\n";
	    return(0);
	}
	$string = "$name, $lab_name, $org_name";
        return ($string, $name, $title, $lab_name, $org_name);
    }

    elsif ($ori == 6) {                 # value is an id_org
        # get the company name from the external_org table in the bio database
	$name = &getExtOrg($pkg, $value);
	unless ($name) { 
            carp "couldnt get the name for the company with idOrg $value\n";
	    return(0);
	}
        return ($name);
    }

    return (0);

}

#------------------------------------------------------------------------------------------------#

sub addSample {

    my $pkg = shift;
    my %args = @_;

    print "checking...\norigin type $args{-origin}\norigin val $args{-value}\nequals origin  $args{-equals_origin}\ndate  $args{-date}\nis_transformed $args{-is_transformed}\npassage number $args{-passage}\n";

    unless ($args{-name}) { $args{-name} = ''; }
    unless ($args{-description}) { $args{-description} = ''; }
    unless ($args{-info_location}) { $args{-info_location} = ''; }
    unless ($args{-designer_value}) { $args{-designer_value} = ''; }
    unless ($args{-designer_origin}) { $args{-designer_origin} = ''; }
    unless ($args{-supplier_value}) { $args{-supplier_value} = ''; }
    unless ($args{-supplier_origin}) { $args{-supplier_origin} = ''; }
    unless ($args{-sample_name}) { $args{-sample_name} = ''; }

    # get the next in the sequence for the id_cell_line_sample
    # get an id_vector from a sequence
    my $id = &_getBioId($pkg, 'seq_cell_line_sample');
    unless ($id) {
	carp "couldn't get the next sequence number to assign to id_cell_line_sample.\n DB unchanged.\n";
	return(0);
    }
    print "cell_line_sample id to use is $id\n";

    # get the next in the sequence for the id_cell_line
    my $id2 = &_getBioId($pkg, 'seq_cell_line');
    unless ($id2) {
	carp "couldn't get the next sequence number to assign to id_cell_line.\n DB unchanged.\n";
	return(0);
    }
    print "cell_line id to use is $id2\n";

    # insert the details into the cell line table
	$pkg->{se2}->do('genetrap::setCellInfo', [$id2, $args{-is_transformed}, $args{-name}, $args{-description}, $args{-info_location}, $args{-designer_value}, $args{-designer_origin}, $args{-supplier_value}, $args{-supplier_origin}], $pkg->{dbh2});

    # insert the details into the cell_line_sample table
	$pkg->{se2}->do('genetrap::setCellSampleInfo', [$id, $id2, $args{-value}, $args{-origin}, $args{-equals_origin}, $args{-passage}, $args{-date}, $args{-sample_name}], $pkg->{dbh2});

    return($id, $id2);

}

#------------------------------------------------------------------------------------------------#

# a set of new electroporation specific sequences is set up each time an electro is registered
# get the hrs from this bio DB
# entry is locked until rollback or setHRs is run
sub getHRs {

    my $pkg = shift;
    my ($entity, $id_electro, $number) = @_;
    print "entity $entity, id_electro $id_electro, number $number\n";

    my ($start, $end, $table, $id);

    if ($entity eq 'cell_line') { $entity = 0; $table = 'cell_line'; }
    else { $table = 'entity_type'; }

    # get existing value for this entity from the human_readable_id table (put a lock on using for update nowait)
    ($start, $id) = $pkg->{se2}->getRow('genetrap::getIdHr', [$id_electro, $table, $entity], $pkg->{dbh2});
    print "start $start id $id\n";
    unless ($start && $id) { return (0) }

    my $sum = $start + $number;
    $end = $sum - 1;
    print "start $start id $id, sum $sum, end $end\n";
    if ($start) {
        return ($start, $end, $sum, $id);
#        $pkg->{se2}->do('genetrap::updateHr', [$sum, $id], $pkg->{dbh2});
    }
    return (0);
}


#------------------------------------------------------------------------------------------------#
# confirm the use of the hr_ids and update the database
sub setHRs {

    my ($pkg, $sum, $id) = @_;

    print "setting the hr id to $sum where the id_human_readable is $id\n";
        $pkg->{se2}->do('genetrap::updateHr', [$sum, $id], $pkg->{dbh2});

}

#------------------------------------------------------------------------------------------------#

# takes a set of cell line codes, goes through fplate wells in order and assigns
# the cell lines codes to the samples
sub assign_numbers {

    my ($pkg, $numbers, $info_f) = @_;

    my ($plate, $well, $samples);
    my @numbers = @$numbers;

    foreach $plate (sort {$a <=> $b} keys %{$info_f}) {
#	print "assign plate $plate\n";
        foreach $well(sort {$a <=> $b} keys %{$info_f->{$plate}->{wells}}) {
#	    print "assign well $well\n";
	    my $sample = $info_f->{$plate}->{wells}->{$well}->{sample_id};
	    my $id_cell_line = $pkg->getCellIdFromSampleId($sample);
            # get the next cell line code off the array
            my $cell_line_code = shift @numbers;
	    print "assign f plate $plate  well $well sample $sample cell code $cell_line_code\n";
            # update the bioDB with the new cell line code
            $pkg->updateBioInfo('cell_line', 'id_cell_line', $id_cell_line, 'cell_line_name', $cell_line_code);
	    $samples->{$sample} = $cell_line_code;
	}
    }
    return ($samples);
}

#------------------------------------------------------------------------------------------------#

sub entryExists {

    my $pkg= shift;
    my %args = @_;

    my ($value, $value2, $select, $from, $where);

    unless ($args{-table} && $args{-column} && $args{-value}) {
	print "-table, -column and -value arguments are required\n";
	return(0);
    }
    if (($args{-column2} && !$args{-value2}) || ($args{-value2} && !$args{-column2})) {
	print "-column2 and -value2 arguments are required if a second column is being queried\n";
    }

    $value = "\'$args{-value}\'";

    $select = "select $args{-column} ";
    $from = "from $args{-table} ";
    $where = "where $args{-column} = $value ";

    if ($args{-column2}) { 
        $value2 = "\'$args{-value2}\'";
        $select = "select $args{-column}, $args{-column2} ";
        $where = "where $args{-column} = $value and $args{-column2} = $value2 ";
    }

#    my ($result) = $pkg->{se2}->getAll('genetrap::entryExists', [$args{-table}, $args{-column}, $args{-value}], $pkg->{dbh2});

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'entryExists',
                                        "$select 
                                         $from
                                         $where");
    my $result = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});
    return($result);

}

#------------------------------------------------------------------------------------------------#

# begin a transaction
#
sub beginTrapTransaction
{
	my $self = shift;
	print "Begining bio transaction\n";
	$self->{se2}->beginTransaction($self->{dbh2});
}

#
# roll back a transaction
#

#------------------------------------------------------------------------------------------------#

sub rollbackTrapTransaction
{
	my $self = shift;
	print "Rollback bio transaction\n";
	$self->{se2}->rollbackTransaction($self->{dbh2});
}

#------------------------------------------------------------------------------------------------#

#
# commit a transaction
#
sub commitTrapTransaction
{
	my $self = shift;
	print "Commit bio transaction\n";
	$self->{se2}->commitTransaction($self->{dbh2});
}

#------------------------------------------------------------------------------------------------#

sub put_image {

    my $pkg = shift;
    my %args = @_;

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'put_image',
                                             "insert into image
                                              (id_image, image_data2)
                                              values ($args{id}, 
                                                      ORDSYS.ORDIMAGE(empty_blob(), NULL,NULL,NULL,NULL,NULL,NULL)) ");
    $pkg->{se2}->do($sth, [], $pkg->{dbh2});
    print "here1\n";

    my $sth2 = $pkg->{se2}->virtualSqlLib('BTRAP', 'put_image',
                                        "SELECT image_data2 into $args{data} from image  
                                         where id_image = $args{id} for UPDATE "); 
    $pkg->{se2}->do($sth2, [], $pkg->{dbh2});
    print "here2\n";

    my $sth3 = $pkg->{se2}->virtualSqlLib('BTRAP', 'put_image',
                                        "UPDATE image set image_data2 = $args{data} where id_image = $args{id}"); 
    $pkg->{se2}->do($sth3, [], $pkg->{dbh2});

    print "here3\n";
}

#---------------------------------------------------------------------------------------#

sub getCellLineFromRegrow {

    my $pkg = shift;
    my $id_regrow = shift;
    my $electro = "";
                                                                                                              
    my ($cell_line, $date, $origin, $value) = $pkg->{se2}->getRow('genetrap::getCellLineFromRegrow', [$id_regrow], $pkg->{dbh2});

    my ($table) = $pkg->{se2}->getRow('genetrap::getOriginTable', [$origin], $pkg->{dbh2});
    if ($table eq 'electroporation') {
	$electro = $pkg->getElectroCode($value);
    }

    return ($cell_line, $date, $electro);

}

#---------------------------------------------------------------------------------------#

sub getRegrowStatuses {

    my $pkg = shift;

    my $statuses = [];

    my $process = [ 11, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12 ] ;

    foreach my $entry(@$process) {
	my $desc = $pkg->getRegrowStatusDesc($entry);
	push @$statuses, [$entry, $desc];
    }
                                                                                                              
    return ($statuses);
}

#---------------------------------------------------------------------------------------#

sub getRegrowStatus {

    my $pkg = shift;
    my $id_regrow = shift;
                                                                                                              
    my ($id_status) = $pkg->{se2}->getRow('genetrap::getRegrowStatus', [$id_regrow], $pkg->{dbh2});
    return ($id_status);

}

#---------------------------------------------------------------------------------------#

sub getRegrowStatusDesc {

    my $pkg = shift;
    my $id_status = shift;
                                                                                                              
    my ($status) = $pkg->{se2}->getRow('genetrap::getRegrowStatusDesc', [$id_status], $pkg->{dbh2});
    return ($status);

}


#---------------------------------------------------------------------------------------#

sub changeRegrowStatus {
    my $pkg = shift;
    my %args = @_;


    # get the current date
    unless ($args{-date}) { $args{-date} = &getDate($pkg); }

    # make other statuses for this regrow non-current
    $pkg->{se2}->do('genetrap::setRegrowStatusesNonCurrent', [$args{-id_regrow}], $pkg->{dbh2});

    # add the new status
    $pkg->{se2}->do('genetrap::setRegrowStatusInfo', [$args{-id_regrow}, $args{-id_status}, $args{-date}, '1', $args{-id_role}], $pkg->{dbh2});

}

#---------------------------------------------------------------------------------------#

sub get_image {

    my $pkg = shift;
    my %args = @_;

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'get_image',
                                        "select image_data2 from image
                                         where id_image = $args{id}");
    my $data = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});
    return($data);

}

#---------------------------------------------------------------------------------------#

sub get_image_content {

    my $pkg = shift;
    my %args = @_;

    my $sth = $pkg->{se2}->virtualSqlLib('BTRAP', 'get_image',
                                        "select i.image_data.getContent() from image i 
                                         where id_image = $args{id}");
    my $data = $pkg->{se2}->getRow($sth, [], $pkg->{dbh2});
    return($data);

}

#---------------------------------------------------------------------------------------#

sub setVectorLocus {
    my $pkg = shift;
    my $locus_id = shift;
    my $id_vector = shift;

    $pkg->{se2}->do('TRAP::setIdVectorLocus', [$locus_id, $id_vector], $pkg->{dbh2});

}
#---------------------------------------------------------------------------------------#
sub getReagentsfromDesignInstance {

    my $pkg = shift;
    my $instance = shift;
    my $vector_type = vector::VTYPE_PRE_TT;
    my $reagent_ids;
                                                                                                            
    my ($ids) = $pkg->{se2}->getAll('TRAP::getReagentsFromDesignInstance', [$instance, $vector_type], $pkg->{dbh2});
    return(0) unless ($ids);
    foreach my $id(@$ids) {
	push @{$reagent_ids}, $id->[0];
    }

    return $reagent_ids;
    return(0);
}
#--------------------------------------------------------------------------------------#
sub updateDesignIdInstanceIdFromName {

    my $pkg = shift;
    my $name = shift;
    my $design_id = shift;
    my $design_instance_id = shift;

    $pkg->{se2}->do('TRAP::updateDesignIdInstanceIdFromName', [$design_id, $design_instance_id, $name], $pkg->{dbh2});
}
#--------------------------------------------------------------------------------------#

1;

