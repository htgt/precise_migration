### TargetedTrap::IVSA::QCTestPrimer
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

A helper object for managing the lazy loading of details of a QCTest.  This object is directly 
linked with QCTest.  It is never needed to be fetched outside of the context of the QCTest 
it belongs to.  All real work is done by QCTest.

=head1 CONTACT

Contact Jessica Severin on implemetation/design detail: jessica@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::QCTestPrimer;

use strict;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::AlignFeature;

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
  $self->SUPER::init;

  $self->{'primer'}        = '';
  $self->{'status'}        = 'no_reads';
  $self->{'qctest'}        = undef;
  $self->{'alignment'}     = undef;
  $self->{'seq_align_id'}  = undef;
  $self->{'seqread'}       = undef;
  $self->{'seqread_id'}    = undef;
  $self->{'is_valid'}      = 0; #defualt to fail, set when OK
                
  return $self;
}


#################################################

sub primer {
  my $self = shift;
  $self->{'primer'} = shift if(@_);
  return $self->{'primer'};
}
sub status {
  my $self = shift;
  $self->{'status'} = shift if(@_);
  return $self->{'status'};
}
sub is_valid {
  my $self = shift;
  $self->{'is_valid'} = shift if(@_);
  return $self->{'is_valid'};
}
sub qctest {
  my $self = shift;
  $self->{'qctest'} = shift if(@_);
  return $self->{'qctest'};
}

sub alignment {
  my $self = shift;
  if(@_) {
    my $seqalign = shift;
    unless(defined($seqalign) && $seqalign->isa('TargetedTrap::IVSA::AlignFeature')) {
      throw('alignment param must be a TargetedTrap::IVSA::AlignFeature');
    }
    $self->{'alignment'} = $seqalign;
    $self->{'seqread'}   = $seqalign->seqread;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'alignment'}) and 
     defined($self->database) and 
     defined($self->{'seq_align_id'})) 
  {
    #lazy load from database if possible
    my $seqalign = TargetedTrap::IVSA::AlignFeature->fetch_by_id(
         $self->database, $self->{'seq_align_id'});
    if(defined($seqalign)) {
      $self->{'alignment'} = $seqalign;
      $self->{'seqread'}   = $seqalign->seqread;
    }
  }
  
  return $self->{'alignment'};
}


sub seqread {
  my $self = shift;
  if(@_) {
    my $seqread = shift;
    unless(defined($seqread) && $seqread->isa('TargetedTrap::IVSA::SeqRead')) {
      throw('seqread param must be a TargetedTrap::IVSA::SeqRead');
    }
    $self->{'seqread'} = $seqread;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'seqread'}) and 
     defined($self->database) and 
     defined($self->{'seqread_id'})) 
  {
    #lazy load from database if possible
    my $seqread = TargetedTrap::IVSA::SeqRead->fetch_by_id(
         $self->database, $self->{'seqread_id'});
    if(defined($seqread)) {
      $self->{'seqread'} = $seqread;
    }
  }
  
  return $self->{'seqread'};
}


#################################################

sub display_info {
  my $self = shift;
  printf("%s\n", $self->description); 
}

sub description {
  my $self = shift;
  my $str = '';  
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

  #QC_TEST_PRIMER_ID NOT NULL NUMBER       
  #QC_TEST_ID        NOT NULL NUMBER       
  #SEQ_ALIGN_ID      NULL     NUMBER       
  #PRIMER_STATUS     NULL     VARCHAR2(255)
  #PRIMER_NAME       NULL     VARCHAR2(32) 
  #SEQREAD_ID        NULL     NUMBER       
  
  $self->primary_id($rowHash->{'QCTEST_PRIMER_ID'});
  $self->primer($rowHash->{'PRIMER_NAME'});
  $self->status($rowHash->{'PRIMER_STATUS'});
  $self->is_valid($rowHash->{'IS_VALID'});

  #for lazy loading
  $self->{'seqread_id'} = $rowHash->{'SEQREAD_ID'};
  $self->{'seq_align_id'} = $rowHash->{'SEQ_ALIGN_ID'};
    
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM qctest_primer WHERE qctest_primer_id = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_by_qctest_id {
  my $class = shift;
  my $db = shift;
  my $test_id = shift;
  
  my $sql = "SELECT * FROM qctest_primer WHERE QCTEST_RESULT_ID=? order by qctest_primer_id";
  return $class->fetch_multiple($db, $sql, $test_id);
}

##### DBObject store method #####

sub store {
  my $self = shift;
  my $db = shift;

  my $test_id = undef;
  my $db_hit_id = undef;
  my $seqread_id = undef;
    
  $test_id = $self->qctest->id if($self->qctest);
  $db_hit_id = $self->alignment->id if($self->alignment);
  $seqread_id = $self->seqread->id if($self->seqread);
  
  if($db) { $self->database($db); }

  my $test_primer_id = $self->next_sequence_id('seq_qctest_primer');
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT INTO QCTEST_PRIMER (
                QCTEST_PRIMER_ID,
                QCTEST_RESULT_ID,
                SEQ_ALIGN_ID,
                SEQREAD_ID,
                PRIMER_STATUS,
                IS_VALID,
                PRIMER_NAME
             ) VALUES(?,?,?,?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $test_primer_id);
  $sth->bind_param(2, $test_id);
  $sth->bind_param(3, $db_hit_id);
  $sth->bind_param(4, $seqread_id);
  $sth->bind_param(5, $self->status);
  $sth->bind_param(6, $self->is_valid);
  $sth->bind_param(7, $self->primer);
  $sth->execute();
  $sth->finish;
}


1;

