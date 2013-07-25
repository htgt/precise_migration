### TargetedTrap::IVSA::VectorBatch
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

package TargetedTrap::IVSA::VectorBatch;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
use Bio::EnsEMBL::Utils::Exception qw( throw warning );

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
  
  $self->{'batch_name'} = 'a';  
  $self->{'id_origin_prepped_by'} = 3; #team87 
  $self->{'id_value_prepped_by'} = 30531; #default to jessica's id  
  
  return $self;
}

sub vector_id {
  my $self = shift;
  $self->{'vector_id'} = shift if @_;
  return $self->{'vector_id'};
}
sub vector_construct_id {
  my $self = shift;
  $self->{'vector_construct_id'} = shift if @_;
  return $self->{'vector_construct_id'};
}
sub batch_name {
  my $self = shift;
  $self->{'batch_name'} = shift if @_;
  unless(defined($self->{'batch_name'})) { $self->{'batch_name'} = ''; }
  return $self->{'batch_name'};
}
sub id_origin_prepped_by {
  my $self = shift;
  $self->{'id_origin_prepped_by'} = shift if @_;
  return $self->{'id_origin_prepped_by'};
}
sub id_value_prepped_by {
  my $self = shift;
  $self->{'id_value_prepped_by'} = shift if @_;
  return $self->{'id_value_prepped_by'};
}

sub display_info {
  my $self = shift;
  printf("TargetTrap::IVSA::VectorBatch(db %s ) %s : vector_construct_id=%d\n", 
    $self->id, 
    $self->batch_name, 
    $self->vector_construct_id,
    );
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

  # ID_VECTOR_BATCH      NOT NULL NUMBER          
  # ID_VECTOR            NOT NULL NUMBER          
  # BATCH_DATE           NULL     DATE            
  # CONCENTRATION        NULL     DOUBLE PRECISION
  # BATCH_NAME           NULL     VARCHAR2(20)    
  # ID_VALUE_PREPPED_BY  NULL     NUMBER          
  # ID_ORIGIN_PREPPED_BY NOT NULL NUMBER          
  # ID_VECTOR_CONSTRUCT  NULL     NUMBER          
  # ID_METHOD            NULL     NUMBER          

  $self->primary_id($rowHash->{'ID_VECTOR_BATCH'});
  $self->vector_id($rowHash->{'ID_VECTOR'});
  $self->vector_construct_id($rowHash->{'ID_VECTOR_CONSTRUCT'});
  $self->batch_name($rowHash->{'BATCH_NAME'});
  $self->id_origin_prepped_by($rowHash->{'ID_ORIGIN_PREPPED_BY'});
  $self->id_value_prepped_by($rowHash->{'ID_VALUE_PREPPED_BY'});
      
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "select * from vector_batch where id_vector_batch=?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  
  my $sql = "select * from VECTOR_BATCH ".
            "where BATCH_NAME = ?";
  return $class->fetch_single($db, $sql, $name);
}

sub fetch_all_for_vector_construct_id {
  my $class = shift;
  my $db = shift;
  my $construct_id = shift;
  
  my $sql = "SELECT * FROM VECTOR_BATCH ".
            "WHERE ID_VECTOR_CONSTRUCT = ? ";
  return $class->fetch_multiple($db, $sql, $construct_id);
}


sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }
    
  my $dbID = $self->next_sequence_id('seq_vector_batch');
  $self->primary_id($dbID);
  
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT INTO vector_batch (ID_VECTOR_BATCH, BATCH_NAME, ID_VECTOR_CONSTRUCT, ID_VECTOR ".
             ", ID_ORIGIN_PREPPED_BY, ID_VALUE_PREPPED_BY, BATCH_DATE) ".
            "VALUES(?,?,?,?,?,?,SYSDATE)";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->batch_name);
  $sth->bind_param(3, $self->vector_construct_id);
  $sth->bind_param(4, $self->vector_id);
  $sth->bind_param(5, $self->id_origin_prepped_by);
  $sth->bind_param(6, $self->id_value_prepped_by);
  $sth->execute();
  $sth->finish;
}



1;

