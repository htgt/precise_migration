### TargetedTrap::IVSA::Oligo
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

my $_ivsa_oligo_global_id_hash = {};
my $_ivsa_oligo_global_name_hash = {};

package TargetedTrap::IVSA::Oligo;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# Class methods
#################################################
sub new_from_bioseq {
  #return a SeqRead object created from a Bio::Seq object
  my $class = shift;
  my $bioseq = shift;
  
  my $obj = $class->new();
  
  $obj->sequence($bioseq);
  if(defined($bioseq->id)) { 
    $obj->oligo_name($bioseq->id); 
  }
  return $obj;
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'_oligo_name'} = undef;  
  $self->{'_sequence'} = undef; #Bio::Seq object
  
  return $self;
}

sub name {
  #eventually will be replaces by redirecting
  #call to the Oligo/Primer object
  my $self = shift;
  $self->{'_oligo_name'} = shift if @_;
  return $self->{'_oligo_name'};
}

sub sequence {
  #eventually will be replaces by redirecting
  #call to the Oligo/Primer object
  my $self = shift;
  if(@_) {
    my $seq = shift;
    unless(defined($seq) && $seq->isa('Bio::Seq')) {
      throw('sequence argument must be a Bio::Seq');
    }
    $self->{'_sequence'} = $seq;
  }
  return $self->{'_sequence'};
}

sub display_info {
  my $self = shift;

  printf("TargetTrap::IVSA::Oligo(db %s ) %23s : %s\n", 
    $self->id,
    $self->name, 
    $self->sequence->seq);
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

  # ID_OLIGO         NOT NULL NUMBER          
  # ID_OLIGO_TYPE    NOT NULL NUMBER          
  # OLIGO_SEQ        NULL     VARCHAR2(255)   
  # ANNEALING_TEMP   NULL     DOUBLE PRECISION
  # MOLECULAR_WEIGHT NULL     DOUBLE PRECISION
  # GC_CONTENT       NULL     DOUBLE PRECISION
  # FEATURE_ID       NULL     NUMBER          
  # NAME             NULL     VARCHAR2(80)    
  
  $self->primary_id($rowHash->{'ID_OLIGO'});
  $self->name($rowHash->{'NAME'});
  
  # read SEQUENCE CLOB
  my $seq_data = $rowHash->{'OLIGO_SEQ'}; 
  my $bioseq = Bio::Seq->new(-id=>$self->name, -seq=>$seq_data);
  $self->sequence($bioseq); 

  #hash the oligos since they are constants for a given database and oligo_id
  $_ivsa_oligo_global_id_hash->{$self->database() . $self->id} = $self;
  $_ivsa_oligo_global_name_hash->{$self->database() . $self->name} = $self;

  #printf("fetched : "); $self->display_info;
    
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $oligo = $_ivsa_oligo_global_id_hash->{$db . $id};
  return $oligo if(defined($oligo));

  my $sql = "SELECT * FROM tt_oligo WHERE id_oligo = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $label = shift;
  
  my $oligo = $_ivsa_oligo_global_name_hash->{$db . $label};
  return $oligo if(defined($oligo));

  my $sql = "SELECT * FROM tt_oligo WHERE name = ?";
  return $class->fetch_single($db, $sql, $label);
}



1;

