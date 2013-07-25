### TargetedTrap::IVSA::Vector
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

package TargetedTrap::IVSA::Vector;

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
  
  $self->{'name'} = undef;  
  $self->{'vector_type'} = undef;  
  $self->{'design_id'} = undef;  
  
  return $self;
}

sub name {
  my $self = shift;
  $self->{'name'} = shift if @_;
  return $self->{'name'};
}
sub vector_type {
  my $self = shift;
  $self->{'vector_type'} = shift if @_;
  return $self->{'vector_type'};
}
sub design_id {
  my $self = shift;
  $self->{'design_id'} = shift if @_;
  return $self->{'design_id'};
}

sub display_info {
  my $self = shift;
  printf("TargetTrap::IVSA::Vector(db %s ) %s : %s : design_id=%d\n", 
    $self->id,
    $self->name, 
    $self->vector_type,
    $self->design_id
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

  # ID_VECTOR          NOT NULL NUMBER       
  # FRAME              NULL     VARCHAR2(2)  
  # NAME               NOT NULL VARCHAR2(80) 
  # TYPE               NOT NULL VARCHAR2(8)  
  # DESCRIPTION        NULL     VARCHAR2(250)
  # INFO_LOCATION      NULL     VARCHAR2(250)
  # ID_VALUE_SUPPLIER  NULL     NUMBER       
  # ID_ORIGIN_SUPPLIER NULL     NUMBER       
  # ID_VALUE_DESIGNER  NULL     NUMBER       
  # ID_ORIGIN_DESIGNER NULL     NUMBER       
  # ID_VECTOR_TYPE     NOT NULL NUMBER       
  # ID_INFO_GROUP      NULL     NUMBER       
  # ID_PROJECT         NULL     NUMBER       
  # DESIGN_ID          NULL     NUMBER       
  
  $self->primary_id($rowHash->{'ID_VECTOR'});
  $self->name($rowHash->{'NAME'});
  $self->vector_type($rowHash->{'VECTOR_TYPE'});
  $self->design_id($rowHash->{'DESIGN_ID'});
      
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT v.*, vt.description as vector_type FROM vector v ".
            "JOIN vector_type_dict vt on(v.id_vector_type = vt.id_vector_type) ".
            "WHERE id_vector = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  
  my $sql = "SELECT v.*, vt.description as vector_type FROM vector v ".
            "JOIN vector_type_dict vt on(v.id_vector_type = vt.id_vector_type) ".
            "WHERE name = ?";
  return $class->fetch_single($db, $sql, $name);
}

sub fetch_by_design_and_type {
  my $class = shift;
  my $db = shift;
  my $design_id = shift;
  my $vector_type = shift;
  
  my $sql = "SELECT v.*, vt.description as vector_type FROM vector v ".
            "JOIN vector_type_dict vt on(v.id_vector_type = vt.id_vector_type) ".
            "WHERE design_id = ? ".
            "AND vt.description = ?";
  return $class->fetch_single($db, $sql, $design_id, $vector_type);
}



1;

