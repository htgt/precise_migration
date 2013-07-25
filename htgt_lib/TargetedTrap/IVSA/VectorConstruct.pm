### TargetedTrap::IVSA::VectorConstruct
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

package TargetedTrap::IVSA::VectorConstruct;

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


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'vector_id'} = undef;  
  $self->{'vector_construct_id'} = undef;  
  $self->{'vector'} = undef;  
  $self->{'construct_name'} = undef;  
  $self->{'is_best'} = undef;  
  $self->{'consensus_seq'} = undef;
     
  return $self;
}

sub vector {
  my $self = shift;
  $self->{'vector'} = shift if @_;
  return $self->{'vector'};
}
sub vector_id {
  my $self = shift;
  $self->{'vector_id'} = shift if @_;
  if($self->vector) {
    return $self->vector->id;
  } else { 
    return $self->{'vector_id'};
  }
}
sub vector_construct_id {
  my $self = shift;
  if(@_) {
    $self->{'vector_construct_id'} = shift;
    $self->primary_id($self->{'vector_construct_id'});
  }
  return $self->{'vector_construct_id'};
}
sub construct_name {
  my $self = shift;
  $self->{'construct_name'} = shift if @_;
  return $self->{'construct_name'};
}
sub is_best {
  my $self = shift;
  $self->{'is_best'} = shift if @_;
  return $self->{'is_best'};
}

sub consensus_seq {
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

sub seq_length {
  my $self = shift;
  return 0 unless(defined($self->consensus_seq));
  return $self->consensus_seq->length;
}

sub display_info {
  my $self = shift;
  printf("TargetTrap::IVSA::VectorConstruct(db %s ) %s : vector_id=%d : seqlen=%d", 
    $self->id, 
    $self->construct_name, 
    $self->vector_id,
    $self->seq_length
    );
  if($self->is_best) { print(" : best"); }
  print("\n");
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

  # ID_VECTOR_CONSTRUCT NOT NULL NUMBER       
  # ID_VECTOR           NOT NULL NUMBER       
  # VALIDATED           NULL     NUMBER(1,0)  
  # CONSTRUCT_NAME      NULL     VARCHAR2(100)
  # CONSTRUCT_DATE      NULL     DATE         
  # PROJECT             NULL     VARCHAR2(100)
  # CONSENSUS_SEQ       NULL     LONG         
  # DBGSS_ACCESSION     NULL     VARCHAR2(100)
  # ID_METHOD           NULL     NUMBER       
  # CHOSEN              NULL     NUMBER(1,0)  

  $self->vector_construct_id($rowHash->{'ID_VECTOR_CONSTRUCT'});
  $self->vector_id($rowHash->{'ID_VECTOR'});
  $self->construct_name($rowHash->{'CONSTRUCT_NAME'});
  $self->is_best($rowHash->{'CHOSEN'});
      
  # read CONSENSUS_SEQ CLOB if defined
  my $lob_locator = $rowHash->{'CONSENSUS_SEQ'}; 
  if($lob_locator) {
    my $lob_length = $dbh->ora_lob_length($lob_locator);
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$self->construct_name, -seq=>$seq_data);
    $self->consensus_seq($bioseq); 
  }
        
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM vector_construct ".
            "WHERE ID_VECTOR_CONSTRUCT = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  
  my $sql = "SELECT * FROM vector_construct ".
            "WHERE construct_name = ?";
  return $class->fetch_single($db, $sql, $name);
}

sub fetch_all_for_vector_id {
  my $class = shift;
  my $db = shift;
  my $vector_id = shift;
  
  my $sql = "SELECT * FROM vector_construct ".
            "WHERE ID_VECTOR = ? ";
  return $class->fetch_multiple($db, $sql, $vector_id);
}

sub fetch_by_name_vector_id {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  my $vector_id = shift;
  
  my $sql = "SELECT * FROM vector_construct ".
            "WHERE construct_name = ? and id_vector=?";
  return $class->fetch_single($db, $sql, $name, $vector_id);
}


sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }
    
  my $dbID = $self->next_sequence_id('seq_vector_construct');
  $self->vector_construct_id($dbID);
  
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT INTO vector_construct (ID_VECTOR_CONSTRUCT, ID_VECTOR, CONSTRUCT_NAME, CHOSEN, CONSTRUCT_DATE) ".
            "VALUES(?,?,?,?,SYSDATE)";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->vector_id);
  $sth->bind_param(3, $self->construct_name);
  $sth->bind_param(4, $self->is_best);
  $sth->execute();
  $sth->finish;

}



1;

