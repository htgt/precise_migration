### TargetedTrap::IVSA::QCTestRun
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Jessica Severin (jessica@sanger.ac.uk) 
# Maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author las
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact Jessica Severin on implemetation/design detail: jessica@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::QCTestRun;

use strict;
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# Class methods
#################################################

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  my %args = @_;
  $self->SUPER::init(@_);
  
  $self->{'run_date'} = '';
  $self->{'prog_version'} = '';
  $self->{'comments'} = undef;
  $self->{'stage'} = 'post_cre';
  $self->{'is_public'} = 0;
  $self->{'design_plate'} = undef;
  $self->{'minscore'} = 30.0;
  
  $self->{'designs'} = {};
  $self->{'clones'} = {};
  $self->{'qctests'} = [];

  return $self;
}

sub run_date {
  my $self = shift;
  $self->{'run_date'} = shift if(@_);
  return $self->{'run_date'};
}
sub prog_version {
  my $self = shift;
  $self->{'prog_version'} = shift if(@_);
  return $self->{'prog_version'};
}
sub comments {
  my $self = shift;
  $self->{'comments'} = shift if(@_);
  return $self->{'comments'};
}
sub stage {
  my $self = shift;
  $self->{'stage'} = shift if(@_);
  return $self->{'stage'};
}
sub is_public {
  my $self = shift;
  $self->{'is_public'} = shift if(@_);
  return $self->{'is_public'};
}
sub design_plate {
  my $self = shift;
  $self->{'design_plate'} = shift if(@_);
  return $self->{'design_plate'};
}
sub clone_plate {
  my $self = shift;
  $self->{'clone_plate'} = shift if(@_);
  return $self->{'clone_plate'};
}
sub minscore {
  my $self = shift;
  $self->{'minscore'} = shift if(@_);
  return $self->{'minscore'};
}

sub design_db {
  my $self = shift;
  $self->{'design_db'} = shift if(@_);
  return $self->{'design_db'};
}

####################################################
# QCTestResult section
####################################################
sub add_qctest {
  my $self = shift;
  my $qctest = shift;
  
  return unless($qctest);
  push @{$self->{'qctests'}}, $qctest;
}

sub get_all_qctests {
  my $self = shift;
  return $self->{'qctests'};
}

sub find_best_test_for_clone {
  my $self = shift;
  my $construct = shift;
  
  if($construct->best_qctest) {
    return $construct->best_qctest;
  }
  my $best = undef;
  foreach my $qctest (@{$self->{'qctests'}}) {
    next unless( $qctest->construct->clone_tag eq $construct->clone_tag ); # this line is wrong. it is testing string equality which is not what we want
    if($qctest->is_better($best)) { $best = $qctest; }
  }
  $construct->best_qctest($best);
  return $best;
}

sub store_all_qctests {
  my $self = shift;
  foreach my $qctest (@{$self->{'qctests'}}) {  
    $qctest->store($self->database); 
  }
}

#############################################
# statistics
#############################################
sub qctest_count {
  my $self = shift;
  $self->{'qctest_count'} = shift if(@_);
  if(!defined($self->{'qctest_count'})) { $self->calc_stats; }
  return $self->{'qctest_count'};
}

sub valid_construct_count {
  my $self = shift;
  $self->{'valid_construct_count'} = shift if(@_);
  if(!defined($self->{'valid_construct_count'})) { $self->calc_stats; }
  return $self->{'valid_construct_count'};
}

sub valid_design_count {
  my $self = shift;
  $self->{'valid_design_count'} = shift if(@_);
  if(!defined($self->{'valid_design_count'})) { $self->calc_stats; }
  return $self->{'valid_design_count'};
}

sub total_construct_count {
  my $self = shift;
  $self->{'total_construct_count'} = shift if(@_);
  if(!defined($self->{'total_construct_count'})) { $self->calc_stats; }
  return $self->{'total_construct_count'};
}

sub total_design_count {
  my $self = shift;
  $self->{'total_design_count'} = shift if(@_);
  if(!defined($self->{'total_design_count'})) { $self->calc_stats; }
  return $self->{'total_design_count'};
}

sub perfect_pass_design_count {
  my $self = shift;
  $self->{'perfect_pass_design_count'} = shift if(@_);
  if(!defined($self->{'perfect_pass_design_count'})) { $self->calc_stats; }
  return $self->{'perfect_pass_design_count'};
}


sub calc_stats {
  my $self = shift;
  return if($self->{'calc_stats'});
 
  $self->{'qctest_count'} = scalar (@{$self->{'qctests'}});
  $self->{'valid_construct_count'} = 0;
  $self->{'valid_design_count'} = 0;
  $self->{'total_construct_count'} = 0;
  $self->{'total_design_count'} = 0;
  $self->{'perfect_pass_design_count'} = 0;

  foreach my $qctest (@{$self->{'qctests'}}) {
    if($qctest->is_best_for_engseq_in_run) {
      $self->{'total_design_count'}++;
      if($qctest->is_valid) { $self->{'valid_design_count'}++; }
      if($qctest->is_perfect) { $self->{'perfect_pass_design_count'}++; }
    }
    if($qctest->is_best_for_construct_in_run) {
      $self->{'total_construct_count'}++;
      if($qctest->is_valid) { $self->{'valid_construct_count'}++; }
    }    
  }
  $self->{'calc_stats'} = 1;
}

sub display_stats {
  my $self = shift;
  $self->display_info;
  printf("  total qctests        : %s\n", $self->qctest_count);
  printf("  valid constructs     : %d / %d\n", $self->valid_construct_count, $self->total_construct_count);
  printf("  valid designs        : %d / %d\n", $self->valid_design_count, $self->total_design_count);
  printf("  prefect pass designs : %d / %d\n", $self->perfect_pass_design_count, $self->total_design_count);
}
#############################################

sub display_info {
  my $self = shift;
  printf("%s\n", $self->description);
}

sub description {
  my $self = shift;
  my $str = sprintf("QCTestRun[%s] %s : %s : %s", 
          $self->id,
          $self->run_date,
          $self->prog_version, 
          $self->comments
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
  
  $self->primary_id($rowHash->{'QCTEST_RUN_ID'});
  $self->comments($rowHash->{'COMMENTS'});
  $self->prog_version($rowHash->{'PROGRAM_VERSION'});
  $self->run_date($rowHash->{'RUN_DATE'});
  $self->stage($rowHash->{'STAGE'});
  $self->is_public($rowHash->{'IS_PUBLIC'});
  $self->design_plate($rowHash->{'DESIGN_PLATE'});
  $self->clone_plate($rowHash->{'CLONE_PLATE'});
    
  $self->valid_construct_count($rowHash->{'VALID_CONSTRUCT_COUNT'});
  $self->valid_design_count($rowHash->{'VALID_DESIGN_COUNT'});
  $self->total_construct_count($rowHash->{'TOTAL_CONSTRUCT_COUNT'});
  $self->total_design_count($rowHash->{'TOTAL_DESIGN_COUNT'});
  $self->perfect_pass_design_count($rowHash->{'PERFECT_PASS_DESIGN_COUNT'});
  $self->qctest_count($rowHash->{'QCTEST_COUNT'});

  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM qctest_run WHERE qctest_run_id = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_by_design_plate {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  
  my $sql = "SELECT * FROM qctest_run WHERE design_plate = ?";
  return $class->fetch_multiple($db, $sql, $plate);
}

sub fetch_valid_by_plate_stage {
  my $class = shift;
  my $db = shift;
  my $plate = shift;
  
  my $sql = "SELECT * FROM qctest_run WHERE design_plate = ?";
  return $class->fetch_multiple($db, $sql, $plate);
}

sub fetch_all {
  my $class = shift;
  my $db = shift;
  
  my $sql = "SELECT * FROM qctest_run order by qctest_run_id";
  return $class->fetch_multiple($db, $sql);
}


##### private creation method #####

sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }

  my $dbID = $self->next_sequence_id('seq_qctest_run');
  $self->primary_id($dbID);
  
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT INTO QCTEST_RUN (
                RUN_DATE,
                QCTEST_RUN_ID,
                PROGRAM_VERSION,
                COMMENTS,
                STAGE,
                DESIGN_PLATE,
                CLONE_PLATE,
                IS_PUBLIC
             ) VALUES(SYSDATE,?,?,?,?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->prog_version);
  $sth->bind_param(3, $self->comments);
  $sth->bind_param(4, $self->stage);
  $sth->bind_param(5, $self->design_plate);
  $sth->bind_param(6, $self->clone_plate);
  $sth->bind_param(7, $self->is_public);
  $sth->execute();
  $sth->finish;
  
  my $run_date = $self->fetch_col_value($db, 'select run_date from qctest_run where QCTEST_RUN_ID=?', $dbID);
  $self->run_date($run_date);
  
}


sub db_update_stats {
  my $self = shift;
  
  my $dbh = $self->database->get_connection;  
  my $sql = "UPDATE QCTEST_RUN SET
                VALID_CONSTRUCT_COUNT=?,
                VALID_DESIGN_COUNT=?,
                TOTAL_CONSTRUCT_COUNT=?,
                TOTAL_DESIGN_COUNT=?,
                PERFECT_PASS_DESIGN_COUNT=?,
                QCTEST_COUNT=?
             WHERE QCTEST_RUN_ID=?";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->valid_construct_count);
  $sth->bind_param(2, $self->valid_design_count);
  $sth->bind_param(3, $self->total_construct_count);
  $sth->bind_param(4, $self->total_design_count);
  $sth->bind_param(5, $self->perfect_pass_design_count);
  $sth->bind_param(6, $self->qctest_count);
  $sth->bind_param(7, $self->primary_id);
  $sth->execute();
  $sth->finish;
      
  return $self;
}



1;

