### TargetedTrap::DBObject
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Author: Jessica Severin (jessica@sanger.ac.uk) 
#
=head1 NAME

DBObject - DESCRIPTION of Object

=head1 SYNOPSIS

=head1 DESCRIPTION

DBObject is an abstract superclass that is a variation on the
ActiveRecord design pattern.  Instead of actively mapping
a table into an object, this will actively map the result of
a query into an object.  The query is standardized for a subclass
of this object, and the columns returned by the query define
the attributes of the object.  This gives much more flexibility 
than the standard implementation of ActiveRecord.  Maybe a
better name for this variant would be ActiveQuery.

In this particular implementation of this design pattern
(mainly due to some limitations in perl) several aspects
must be hand coded as part of the implementation of a 
subclass.  Subclasses must handcode
- all accessor methods
- override the mapRow method 
- APIs for all explicit fetch methods 
  (by using the superclass fetch_single and fetch_multiple)
- the store methods are coded by general DBI code (no assistance)
But the particular database handle is assigned at an instance level
not for the Class. The only restriction is that the database handle 
can run the query.

Future implementations could do more automatic code generation
but this version already speeds development time by 2x-3x
without imposing any limitations and retains all the flexibility
of handcoding.

=head1 CONTACT

Contact Jessica Severin on implemetation/design detail: 
      jessica@sanger.ac.uk
      jessica@ebi.ac.uk
      jessica.severin@gmail.com

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut


package TargetedTrap::DBObject;

use strict;
use TargetedTrap::DBSQL::Database;
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

#################################################
# Factory methods
#################################################

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self,$class;
  $self->init(@args);  
  return $self;
}

sub init {
  my $self = shift;
  #internal variables minimal allocation
  $self->{'_database'} = undef;  
  return $self;
}

sub copy {
  my $self = shift;
  my $class = ref($self);
  my $copy = $class->new;
  foreach my $key (keys %{$self}) {
    $copy->{$key} = $self->{$key};
  }
  #print('self = ', $self, "\n");
  #print('copy = ', $copy, "\n");

  return $copy;
}

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

#################################################
# Instance methods
#################################################

sub database {
  my $self = shift;
  if(@_) {
    my $db = shift;
    unless(defined($db) and ($db->isa('TargetedTrap::DBSQL::Database'))) {
      print("$db is not a TargetedTrap::DBSQL::Database");
    }
    $self->{'_database'} = $db;
  }
  return $self->{'_database'};
}

sub primary_id {
  my $self = shift;
  $self->{'_primary_db_id'} = shift if @_;
  return $self->{'_primary_db_id'};
}

sub id {
  my $self = shift;
  $self->{'_primary_db_id'} = shift if @_;
  if(!defined($self->{'_primary_db_id'})) { return ''; }
  return $self->{'_primary_db_id'}; 
}

sub unique_id {
  #method returns unique id.  If in database can use database_id
  #if only in memory uses perl object id
  my $self = shift;
  if($self->primary_id) { return $self->database .'_'. $self->primary_id; }
  return $self;
}

#################################################
# Framework database methods 
# fetch methods are class level
# insert/update/delete are instance level
#################################################

=head2 fetch_single

  Arg (1)    : $database (TargetedTrap::DBSQL::Database
  Arg (2)    : $sql (string of SQL statement with place holders)
  Arg (3...) : optional parameters to map to the placehodlers within the SQL
  Example    : $obj = $self->fetch_single($db, "select * from my_table where id=?", $id);
  Description: General purpose template method for fetching a single instance
               of this class(subclass) using the mapRow method to convert
               a row of data into an object.
  Returntype : instance of this Class (subclass)
  Exceptions : none
  Caller     : subclasses (not public methods)

=cut

sub fetch_single {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  print ("no database defined\n") unless($db);
  my $dbc = $db->get_connection;
  my $sth = $dbc->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute(@params);
  
  my $obj = undef;
  my $row_hash = $sth->fetchrow_hashref;
  if($row_hash) {
    $obj = $class->new();
    $obj->database($db);
    $obj = $obj->mapRow($row_hash, $dbc);  #required by subclass
  }
  
  $sth->finish;
  return $obj;
}


=head2 fetch_multiple

  Arg (1)    : $database (TargetedTrap::DBSQL::Database
  Arg (2)    : $sql (string of SQL statement with place holders)
  Arg (3...) : optional parameters to map to the placehodlers within the SQL
  Example    : $obj = $self->fetch_single($db, "select * from my_table where id=?", $id);
  Description: General purpose template method for fetching an array of instance
               of this class(subclass) using the mapRow method to convert
               a row of data into an object.
  Returntype : array of instance of this Class (subclass)
  Exceptions : none
  Caller     : subclasses (not public methods)

=cut

sub fetch_multiple {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  print ("no database defined\n") unless($db);
  my $obj_list = [];
  
  my $dbc = $db->get_connection;  
  my $sth = $dbc->prepare($sql, { ora_auto_lob => 0 });
  $sth->execute(@params);
  while(my $row_hash = $sth->fetchrow_hashref) {

    my $obj = $class->new();
    $obj->database($db);
    $obj->mapRow($row_hash, $dbc);  #required by subclass

    push @$obj_list, $obj;
  }
  $sth->finish;
  return $obj_list;
}


sub execute_sql {
  my $self = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;
  
  print ("no database defined\n") unless($db);
  my $dbc = $db->get_connection;  
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  $sth->finish;
}

=head2 fetch_col_value

  Arg (1)    : $sql (string of SQL statement with place holders)
  Arg (2...) : optional parameters to map to the placehodlers within the SQL
  Example    : $value = $self->fetch_col_value($db, "select some_column from my_table where id=?", $id);
  Description: General purpose function to allow fetching of a single column from a single row.
  Returntype : scalar value
  Exceptions : none
  Caller     : within subclasses to easy development

=cut

sub fetch_col_value {
  my $class = shift;
  my $db = shift;
  my $sql = shift;
  my @params = @_;

  print ("no database defined\n") unless($db);
  my $dbc = $db->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  my ($value) = $sth->fetchrow_array();
  $sth->finish;
  return $value;
}


sub test_exists {
  my $self = shift;
  my $sql = shift;
  my @params = @_;

  print ("no database defined\n") unless($self->database);
  my $dbc = $self->database->get_connection;
  my $sth = $dbc->prepare($sql);
  $sth->execute(@params);
  my $exists=0;
  if(my $row_hash = $sth->fetchrow_hashref) { $exists=1; }
  $sth->finish;
  return $exists;
}

#################################################
# Subclass must override these methods
#################################################
sub mapRow {
  my $self = shift;
  my $row_hash = shift;
  my $dbh = shift; #optional 
  
  print ("mapRow must be implemented by subclasses");
  #should by implemented by subclass to map columns into instance variables

  return $self;
}

sub store {
  my $self = shift;
  print ("store must be implemented by subclass");
}


#################################################
#
# internal methods
#
#################################################

sub next_sequence_id {
  my $self = shift;
  my $sequenceName = shift;
  
  my $dbh = $self->database->get_connection;
  
  my $sql = 'select '. $sequenceName . '.nextval from sys.dual';  
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  my ($dbID) = $sth->fetchrow_array();
  $sth->finish;
  #printf("incremented sequence $sequenceName id:%d\n", $dbID);
  
  return $dbID;
}




1;





