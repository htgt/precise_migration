### TargetedTrap::IVSA::ConstructClone
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Was maintained by Jessica Severin (jessica@sanger.ac.uk) 
# Was maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Maintained by team87 infomratics (htgt@sanger.ac.uk) 
# Author htgt
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact team87 informatics on implemetation/design detail: htgt@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

#three global variables (in a true OO language these would be class private variables)
#keys are a composite of the databae and either the id or trace_label
my $__ivsa_constructclone_global_id_cache = {};
my $__ivsa_constructclone_global_should_cache = 0;

package TargetedTrap::IVSA::ConstructClone;

use strict;
use Carp;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper::Concise;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::Constants;
use TargetedTrap::IVSA::SeqRead;

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);


#################################################
# Class methods
#################################################
sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__ivsa_constructclone_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__ivsa_constructclone_global_id_cache = {};
  }
}

sub _process_trace_label {
    my ( $self, $trace_label, $allele ) = @_;

    unless ( $trace_label =~ $TargetedTrap::IVSA::Constants::PLATE_REGEXP ) {
        carp "could not process trace_label: [$trace_label]";
    }

    if ($allele) {
        return join '_', $1, $2, uc $4;
    }
    else {
        return join '_', $1, $2, uc $4, $3;
    }
}

sub new_from_seqread {
    my $class   = shift;
    my $seqread = shift;
    my $allele  = shift;
    my $obj     = $class->new();

    $obj->clone_num( $seqread->clone_num ) unless ($allele);

    $obj->plate( $seqread->project );
    $obj->well( $seqread->well );
    $obj->clone_tag(
        $obj->_process_trace_label( $seqread->trace_label, $allele ) );
    $obj->add_seqread($seqread);

    return $obj;
}

sub clone_tag {
  my $self = shift;
  if (@_) {
    $self->{_clone_tag} = shift;
  }
  return $self->{_clone_tag};
}

#################################################
# Instance methods
#################################################


sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'_exp_engineered_seq'} = undef;
  $self->{'_plate'} = '';
  $self->{'_plate_num'} = undef;
  $self->{'_clone_num'} = '';
  $self->{'_well'} = '';
  $self->{'seqreads'} = {}; 
  $self->{'att_site_anal'} = {};
#  $self->{'_vector_id'} = undef;
#  $self->{'_vector_construct_id'} = undef;
  $self->{'_vector_batch_id'} = undef;
  $self->{'_vector_type'} = '';
  $self->{_clone_tag} = undef;

  return $self;
}


sub plate {
  return TargetedTrap::IVSA::SeqRead::plate(@_);
}

sub plate_num {
  my $self = shift;
  return $self->{'_plate_num'};
}

sub clone_num {
  my $self = shift;
  $self->{'_clone_num'} = shift if @_;
  $self->{'_clone_num'} = '' unless defined($self->{'_clone_num'});
  return $self->{'_clone_num'};
}

sub well {
  my $self = shift;
  $self->{'_well'} = shift if @_;
  return $self->{'_well'};
}

sub well_short {
  my $self = shift;
  if($self->{'_well'} =~ /(\w)(\d+)/) {
    my $wellname = $1; 
    my $wellnum = $2+0;
    return uc($wellname . $wellnum);
  }
  return $self->{'_well'};
}

sub vector_type {
  my $self = shift;
  #should be 'intermediate' or 'final'
  $self->{'_vector_type'} = shift if @_;
  $self->{'_vector_type'} = '' unless defined($self->{'_vector_type'});
  return $self->{'_vector_type'};
}

sub expected_engineered_seq {
  #The SyntheticConstruct or GenomicRegion (ie Design) we are trying to create
  #99.9% this will be a SyntheticConstruct, but for those rare cases where we have
  #an incomplete design, I want to make sure I have a fall back plan.
  my ($self, $eng_seq) = @_;
  if($eng_seq) {
    unless($eng_seq->isa('TargetedTrap::IVSA::EngineeredSeq')) {
      print('$eng_seq is not a TargetedTrap::IVSA::EngineeredSeq');
    }
    $self->{'_exp_engineered_seq'} = $eng_seq;
  }
  return $self->{'_exp_engineered_seq'};
}

##########################################
# TRAP database ID access methods
##########################################

#sub vector_id {
#  my $self = shift;
#  $self->{'_vector_id'} = shift if @_;
#  return $self->{'_vector_id'};
#}
#sub vector_construct_id {
#  my $self = shift;
#  $self->{'_vector_construct_id'} = shift if @_;
#  return $self->{'_vector_construct_id'};
#}
sub vector_batch_id {
  my $self = shift;
  $self->{'_vector_batch_id'} = shift if @_;
  return $self->{'_vector_batch_id'};
}


##########################################
# SeqRead methods
##########################################

sub add_seqread {
  my $self = shift;
  my $seqread = shift;

  unless(defined($seqread) && $seqread->isa('TargetedTrap::IVSA::SeqRead')) {
    print('add_seqread param must be a TargetedTrap::IVSA::SeqRead');
  }

  #double link so read knows clone and clone knows read
  $self->{'seqreads'}->{$seqread->trace_label} = $seqread;
  $seqread->clone($self);
  
  return $self;
}

sub seqreads {
  my $self = shift;
  my @seqreads = values %{$self->{'seqreads'}};
  return \@seqreads;
}

sub seqreads_for_primer {
  my $self = shift;
  my $primer = shift;

  my @seqreads;  
  foreach my $seqread (values %{$self->{'seqreads'}}) {
    if($primer eq $seqread->oligo_name) { push @seqreads, $seqread; }
  }
  return \@seqreads;
}

sub best_seqread_for_primer {
  my $self = shift;
  my $primer = shift;

  my $best_read = undef;
  foreach my $seqread (values %{$self->{'seqreads'}}) {
    next if($primer ne $seqread->oligo_name);
    if(!defined($best_read)) { $best_read = $seqread; }
    if($seqread->seq_length > $best_read->seq_length) { $best_read = $seqread; }
  }
  return $best_read;
}

sub seqread_count {
  my $self = shift;
  return scalar(values %{$self->{'seqreads'}});
}

sub known_primers {
  my $self = shift;

  my $primers = {};
  foreach my $seqread (values %{$self->{'seqreads'}}) {
    $primers->{$seqread->oligo_name} = 1;
  }
  my @primer_array = keys %$primers;
  return \@primer_array;
}

##########################################
# Hit related methods
##########################################

sub all_hits {
  my $self = shift;
  my @hits;
  foreach my $seqread (values %{$self->{'seqreads'}}) {
    push @hits, @{$seqread->hits};
  }
  return \@hits;
}

sub total_hit_count {
  my $self = shift;
  return scalar(@{$self->all_hits});
}

sub best_qctest {
  my ($self, $qctest) = @_;
  if($qctest) {
    if($self->{'best_qctest'}) { #unset old 'best'
      $self->{'best_qctest'}->is_best_for_construct_in_run(0);
    }
    $qctest->is_best_for_construct_in_run(1);
    $self->{'best_qctest'} = $qctest;
  }
  return $self->{'best_qctest'};
}


##########################################

sub display_info {
  my $self = shift;

  printf("ConstructClone: %s_%d %s : %s seqreads : %d hits", 
      $self->plate,
      $self->clone_num,
      $self->well,
      $self->seqread_count,
      $self->total_hit_count
      );
  #printf("%s : ", $self->{'primer_combo_test'});
  
  #foreach my $oligo_id (sort keys %{$self->{'best_well_primer_scores'}}) {
  #  printf("%4s=%6.2f ", $oligo_id, $self->{'best_well_primer_scores'}->{$oligo_id});
  #}
  printf("\n");
}

sub description {
  my $self = shift;

  my $str = sprintf("ConstructClone: %s : %s seqreads : %d hits", 
      $self->clone_tag,
      $self->seqread_count,
      $self->total_hit_count
      );
  return $str;
}


#################################################
#
# DBObject override methods
#
#################################################

##### DBObject instance override methods #####

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;

  my $id = $rowHash->{'CONSTRUCT_CLONE_ID'};

  if($__ivsa_constructclone_global_should_cache != 0) {
    my $t_self = $__ivsa_constructclone_global_id_cache->{$self->database() . $id};
    if(defined($t_self)) {
      return $t_self;  #override the new creation and return object allready stored in cache
    }
  }

  $self->primary_id($rowHash->{'CONSTRUCT_CLONE_ID'});
#  $self->vector_construct_id($rowHash->{'ID_VECTOR_CONSTRUCT'});
#  $self->vector_id($rowHash->{'ID_VECTOR'});
  $self->vector_batch_id($rowHash->{'ID_VECTOR_BATCH'});
  $self->vector_type($rowHash->{'VECTOR_TYPE'});

  #these three data items are used to construct 'clone_tag'
  $self->plate($rowHash->{'PLATE'});
  $self->well($rowHash->{'WELL'});
  $self->clone_num($rowHash->{'CLONE_NUMBER'});
  
  #store newly created object into cache
  if($__ivsa_constructclone_global_should_cache != 0) {
    $__ivsa_constructclone_global_id_cache->{$self->database() . $self->id} = $self;
  }
  return $self;
}


sub store {
  my $self = shift;
  my $db = shift;
  my $forcestore = shift;
  if($db) { $self->database($db); }
  
  my ($dbID, $sql);
  unless($forcestore){
   # alleles don't have a clone num so have to do this to stop duplicate records in construct_clone
   if ($self->clone_num) { 
       $sql = "select construct_clone_id from construct_clone where plate=? and well=? and clone_number=? order by construct_clone_id desc";
       $dbID = $self->fetch_col_value($db, $sql, $self->plate, $self->well, $self->clone_num); 
   } 
   else { 
       $sql = "select construct_clone_id from construct_clone where plate=? and well=? and clone_number is null order by construct_clone_id desc";
       $dbID = $self->fetch_col_value($db, $sql, $self->plate, $self->well); 
   } 

   if($dbID) {
     $self->primary_id($dbID);
     return $self;
   }
  }

  #not in database, so go ahead and store
  $dbID = $self->next_sequence_id('seq_construct_clone');
  $self->primary_id($dbID);
  
  my $dbh = $self->database->get_connection;  
  $sql = qq/
      INSERT INTO CONSTRUCT_CLONE (
        CONSTRUCT_CLONE_ID,
        NAME,
        PLATE,
        WELL,
        CLONE_NUMBER,
        ID_VECTOR_BATCH,
        VECTOR_TYPE
      ) 
      VALUES(?,?,?,?,?,?,?)/;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->clone_tag);
  $sth->bind_param(3, $self->plate);
  $sth->bind_param(4, $self->well);
  $sth->bind_param(5, $self->clone_num);
#  $sth->bind_param(6,  $self->vector_id);
#  $sth->bind_param(7, $self->vector_construct_id);
  $sth->bind_param(6, $self->vector_batch_id);
  $sth->bind_param(7, $self->vector_type);

  $sth->execute();
  $sth->finish;
}
#        ID_VECTOR,
#        ID_VECTOR_CONSTRUCT,


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  if($__ivsa_constructclone_global_should_cache != 0) {
    my $clone = $__ivsa_constructclone_global_id_cache->{$db . $id};
    return $clone if(defined($clone));
  }

  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE CONSTRUCT_CLONE_ID = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_by_plate_type {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  my $type = shift;
  
  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE PLATE=? AND VECTOR_TYPE=?";
  return $class->fetch_single($db, $sql, $plate, $type);
}

sub fetch_by_plate_well_type {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  my $well = shift;
  my $type = shift;
  
  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE PLATE=? AND WELL=? AND VECTOR_TYPE=? order by construct_clone_id desc";
  return $class->fetch_single($db, $sql, $plate, $well, $type);
}


sub fetch_by_vector_batch_id {
  my $class = shift;
  my $db = shift;
  my $batch_id = shift;
  
  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE ID_VECTOR_BATCH = ?";
  return $class->fetch_single($db, $sql, $batch_id);
}

#sub fetch_by_vector_construct_id {
#  my $class = shift;
#  my $db = shift;
#  my $construct_id = shift;
  
#  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE ID_VECTOR_CONSTRUCT = ?";
#  return $class->fetch_single($db, $sql, $construct_id);
#}

sub fetch_all_by_expected_engineered_seq_id {
  my $class = shift;
  my $db = shift;
  my $design_id = shift;
  
  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE EXPECTED_ENGSEQ_ID = ?";
  return $class->fetch_multiple($db, $sql, $design_id);
}

sub fetch_all_by_observed_engineered_seq_id {
  my $class = shift;
  my $db = shift;
  my $design_id = shift;
  
  my $sql = "SELECT * FROM CONSTRUCT_CLONE WHERE EXPECTED_ENGSEQ_ID = ?";
  return $class->fetch_multiple($db, $sql, $design_id);
}


sub fetch_seqreads {
  my $self = shift;
  
  my $dbh = $self->database->get_connection;  
  my $sql = "SELECT SEQREAD_ID FROM qc_seqread WHERE CONSTRUCT_CLONE_ID=?";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->id);
  $sth->execute();
  
  while(my ($dbID) = $sth->fetchrow_array()) {
    my $seqread = TargetedTrap::IVSA::SeqRead->fetch_by_id($self->database, $dbID);
    $self->add_seqread($seqread);
  }
  $sth->finish;
  
  return 0;
}


sub fetch_all_alignments {
  my $self = shift;
  
  if($self->seqread_count == 0) {
    $self->fetch_seqreads($self->database);
  }  
  foreach my $seqread (@{$self->seqreads}) {
    $seqread->fetch_all_alignments;
  }
}

sub update_batch {
    my $self = shift;
    my $db = shift;

    # update the id_vector_batch on the construct clone
    unless ($self->vector_batch_id) {
	print "No batch to add to " . $self->description . "\n";
	return;
    }
    print "update batch\n";
    if ($db) { $self->database($db); }

    print "checking for the batch\n";
#    my $sql = "select id_vector_batch from construct_clone where name=?";
#    my ($id) = $self->fetch_single($db, $sql, $tag); 

    my $dbh = $self->database->get_connection;  

    my $id;
    my $sql = qq/ select id_vector_batch from construct_clone where name=? /;
    my $sth1 = $dbh->prepare($sql);
    $sth1->bind_param(1, $self->clone_tag);
    $sth1->execute();
    while(my ($ID) = $sth1->fetchrow_array()) {
	$id = $ID;
    }
    $sth1->finish;
    
    if ($id && $id == $self->vector_batch_id) {	print "batch already set\n"; }
    if ($id) { print "batch already set to $id - different to " . $self->vector_batch_id . "!\n"; }

    print "batch not set so updating\n";
    $sql = qq/ UPDATE construct_clone set id_vector_batch=? where name=? /;
    my $sth = $dbh->prepare($sql);
    $sth->bind_param(1, $self->vector_batch_id);
    $sth->bind_param(2, $self->clone_tag);
    $sth->execute();
    $sth->finish;

}

1;

