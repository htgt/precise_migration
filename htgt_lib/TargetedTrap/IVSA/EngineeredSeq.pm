### TargetedTrap::IVSA::EngineeredSeq
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

#three global variables (in a true OO language these would be class private variables)
#keys are a composite of the databae and either the id or trace_label
my $__ivsa_engineeredseq_global_id_cache = {};
my $__ivsa_engineeredseq_global_name_cache = {};
my $__ivsa_engineeredseq_global_should_cache = 0;


package TargetedTrap::IVSA::EngineeredSeq;

use strict;
use warnings;

require Bio::Seq;
require Bio::SeqIO;
use Data::Dumper;
use JSON;
use Try::Tiny;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

require TargetedTrap::IVSA::GenomicRegion;
require TargetedTrap::IVSA::SyntheticConstruct;

require TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# Class methods
#################################################

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__ivsa_engineeredseq_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__ivsa_engineeredseq_global_id_cache = {};
    $__ivsa_engineeredseq_global_name_cache = {};
  }
}


sub new_from_fasta_file {
  #returns an array of SeqRead objects created from fasta sequences
  my $class = shift;
  my $fasta_file = shift;
  
  #printf("TargetedTrace::SeqRead::new_from_fasta\n");
  
  my $obj_array = [];
  my $seqio = Bio::SeqIO->new(-file => $fasta_file, -format => 'fasta');
  while (my $seq = $seqio->next_seq) {
    my $obj = $class->new_from_bioseq($seq);
    #$obj->display_info;
    push @$obj_array, $obj;
  }
  return $obj_array;
}


sub new_from_bioseq {
  #return a SeqRead object created from a Bio::Seq object
  my $class = shift;
  my $bioseq = shift;
  
  my $obj = $class->new();
  
  $obj->sequence($bioseq);
  if(defined($bioseq->id)) { 
    $obj->name($bioseq->id); 
  }
  return $obj;
}


#################################################
# Instance methods
#################################################


sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'_name'} = undef;
  $self->{'_subclass'} = '';
  $self->{'_type'} = '';
  $self->{'_sequence'} = undef; #Bio::Seq object
  $self->{'feature_cache'} = {}; #all features have a primary_label which uniquely IDs it
  $self->{'_hits'} = [];
  $self->{'qctests'} = {}; #hashed on clone_tag

  return $self;
}

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->{'_sequence'} = undef;
  $self->{'_hits'} = undef;
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

sub name {
  my $self = shift;
  $self->{'_name'} = shift if @_;
  $self->{'_name'} = $self->unique_tag unless defined($self->{'_name'});
  return $self->{'_name'};
}

sub type {
  my $self = shift;
  $self->{'_type'} = shift if @_;
  return $self->{'_type'};
}

sub subclass {
  my $self = shift;
  $self->{'_subclass'} = shift if @_;
  $self->{'_subclass'} = '' unless defined($self->{'_subclass'});
  return $self->{'_subclass'};
}

sub sequence {
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
  return 0.0 unless($self->sequence);
  return $self->sequence->length;
}

sub unique_tag {
  my $self = shift;
  my $tag = sprintf('engseq_%s', $self->id);
  return $tag;
}

#################################################

sub revcom {
  my $self = shift;
  
  my $rev_self = $self->copy;
  
  my $bioseq = $self->sequence->revcom;
  my $seqlen = $bioseq->length;
  #warn sprintf("region length= %d\n", $seqlen);
  #now we need to copy the SeqFeatures over and revcom them
  foreach my $sf ( $self->sequence->get_all_SeqFeatures() ) {
    #copy SeqFeature
    my $feat = ref($sf)->new; 

    #reverse the coordinates
    $feat->primary_tag($sf->primary_tag);
    $feat->source_tag($sf->source_tag);
    $feat->display_name($sf->display_name);
    $feat->annotation($sf->annotation);  #shares annotation object

    $feat->strand(1);
    $feat->start($seqlen - $sf->end);
    $feat->end($seqlen - $sf->start);
    #printf("  orig seqfeat %s : %d, %d %s\n", $sf, $sf->start, $sf->end, $sf->display_name);
    #printf("           rev %s : %d, %d %s\n", $feat, $feat->start, $feat->end, $feat->display_name);
    
    $bioseq->add_SeqFeature($feat);
  }
  
  $rev_self->sequence($bioseq);
  return $rev_self;
}


sub find_seqfeature {
  my $self = shift;
  my $label = shift;
  
  #search through the SeqFeature annotations looking for $label
  my $found = $self->{'feature_cache'}->{$label};
  return $found if($found);
  
  foreach my $sf ( $self->sequence->get_all_SeqFeatures() ) {
    my $ac = $sf->annotation;
    if($ac) {
      foreach my $key ( $ac->get_all_annotation_keys() ) {
        if($key eq $label) { $found = $sf; }
        foreach my $annotation ( $ac->get_Annotations($key) ) {
          if($annotation->value eq $label) { $found = $sf; }
        }
      }        
    }
  }
  $self->{'feature_cache'}->{$label} = $found;
  return $found;
}


sub seqfeatures_in_range {
  my $self = shift;
  my $start = shift;
  my $end = shift;

  #search through all the the features and return those that
  #overlap with the start/end window.  coordinates in reference to
  #the start of this sequence (ie $self->sequence)
  my @sf_list;
  foreach my $sf ( $self->sequence->get_all_SeqFeatures() ) {
    if($sf->start <= $end and $sf->end >= $start) {
      push @sf_list, $sf;
    }
  }
  return \@sf_list;
}


sub display_seqfeature {
  my $self = shift;
  my $sf = shift;
  
  return unless($sf);
  
  printf("  %s : %d-%d %d", 
        $sf->primary_tag, 
        $sf->start, $sf->end, $sf->strand);
  my $ac = $sf->annotation;
  if($ac) {
    foreach my $key ( $ac->get_all_annotation_keys() ) {
      my @anno_list = $ac->get_Annotations($key);
      foreach my $annotation ( @anno_list ) {
        # value is an Bio::AnnotationI, and defines a "as_text" method
        print " : ", $key,"=[", $annotation->value,"]";
      }
    }        
  }
  printf("\n");
}

sub display_all_seqfeatures {
  my $self = shift;
  printf("all_seqfeatures\n");
  foreach my $sf ( $self->sequence->get_all_SeqFeatures() ) {
    $self->display_seqfeature($sf);
  }
}


#################################################

sub add_hit {
  my $self = shift;
  my $hit = shift;
  
  unless(defined($hit) && $hit->isa('TargetedTrap::IVSA::AlignFeature')) {
    throw('add_hit param must be a TargetedTrap::IVSA::AlignFeature');
  }
  push @{$self->{'_hits'}}, $hit; 
}

sub hits {
  my $self = shift;
  return $self->{'_hits'};
}

sub all_matching_seqreads {
  #returns array of SeqRead object which match through hits(AlignFeature)
  my $self = shift;
  my $seqread_hash = {};
  foreach my $hit (@{$self->hits}) {
    my $seqread = $hit->seqread;
    next unless($seqread);    
    $seqread_hash->{$seqread->trace_label} = $seqread;
  }
  my @reads = values %{$seqread_hash};
  return \@reads;
}

sub all_matching_clones {
  #returns array of ConstructClone object which match through hits(AlignFeature)
  my $self = shift;
  my $clone_hash = {};
  foreach my $hit (@{$self->hits}) {
    my $clone = $hit->seqread->clone;
    next unless($clone);    
    $clone_hash->{$clone->clone_tag} = $clone;
  }
  my @clones = values %{$clone_hash};
  return \@clones;
}


####################################################
# QCTest section
####################################################
sub add_qctest {
  my $self = shift;
  my $qctest = shift;
  
  return unless($qctest);
  $self->{'qctests'}->{$qctest->construct->clone_tag} = $qctest;
}

sub best_qctest {
  my ($self, $qctest) = @_;
  if($qctest) {
    if($self->{'best_qctest'}) { #unset old 'best'
      $self->{'best_qctest'}->is_best_for_engseq_in_run(0);
    }
    $qctest->is_best_for_engseq_in_run(1);
    $self->{'best_qctest'} = $qctest;
    $self->add_qctest($qctest);
  }
  return $self->{'best_qctest'};
}

sub get_qctest_for_clone {
  my $self = shift;
  my $clone = shift;
  return $self->{'qctests'}->{$clone->clone_tag};
}

sub get_all_qctests {
  my $self = shift;
  my @tests = values %{$self->{'qctests'}};
  return \@tests;
}

#################################################

sub display_info {
  my $self = shift;
  printf("%s\n", $self->description);
}

sub description {
  my $self = shift;

  my $id = $self->primary_id;
  my $seq = '';
  if($self->sequence and $self->sequence->seq) {
    $seq = substr($self->sequence->seq, 0, 30);
  }
  if(!defined($seq)) { $seq = ''; }
  
  unless(defined($id)) { $id=''; }
  my $str = sprintf("engseq(%s) %s : %d:%s....", 
    $id,
    $self->name,
    $self->seq_length,
    $seq);
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
 
  $self->primary_id($rowHash->{'ENGINEERED_SEQ_ID'});
  $self->type($rowHash->{'TYPE'});
  $self->name($rowHash->{'NAME'});
  
  # read SEQUENCE CLOB
  my $is_circular = $rowHash->{'IS_CIRCULAR'}; 
  my $lob_locator = $rowHash->{'SEQUENCE'}; 
  my $lob_length = $dbh->ora_lob_length($lob_locator);
  if(($lob_length > 0) and ($lob_locator)) {
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$self->name, -is_circular=>$is_circular, -seq=>$seq_data);
    $self->sequence($bioseq); 
  }
  
  #now load the ANNOTATION_FEATURE(s)
  $self->fetch_features;

  if($__ivsa_engineeredseq_global_should_cache != 0) {
    #hash the oligos since they are constants for a given database and oligo_id
    $__ivsa_engineeredseq_global_id_cache->{$self->database() . $self->id} = $self;
    $__ivsa_engineeredseq_global_name_cache->{$self->database() . $self->name} = $self;
  }

  #printf("fetched : %s\n", $self->description);
  
  return $self;
}

sub is_genomic {
  my $self = shift;
  $self->{_is_genomic} = shift if @_;
  return $self->{_is_genomic};
}

sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }

  if(!defined($self->sequence)) { 
    throw('sequence not defined, fail to store');
  }

  my $dbID = $self->next_sequence_id('seq_engineered_seq');
  $self->primary_id($dbID);

  my $dbh = $self->database->get_connection;
  my $sql = qq/
      INSERT INTO ENGINEERED_SEQ (
        ENGINEERED_SEQ_ID,
        SUBCLASS,
        TYPE,
        NAME,
        IS_CIRCULAR,
        IS_GENOMIC,
        SEQUENCE) 
      VALUES(?,?,?,?,?,?, EMPTY_CLOB())/;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->subclass);
  $sth->bind_param(3, $self->type);
  $sth->bind_param(4, $self->name);
  $sth->bind_param(5, $self->sequence->is_circular);
  $sth->bind_param(6, $self->is_genomic);
  $sth->execute();
  $sth->finish;

  #now store the sequence into the CLOB
  my $seq_string = '';
  if(defined($self->sequence)) { $seq_string = $self->sequence->seq; }
  if($seq_string) { 
    $sql = "SELECT sequence FROM engineered_seq WHERE engineered_seq_id=? FOR UPDATE";
    $sth = $dbh->prepare( $sql, { ora_auto_lob => 0 } );
    $sth->execute( $dbID );
    my ( $char_locator ) = $sth->fetchrow_array();
    $sth->finish();
    #print("char_loc = ", $char_locator, "\n");

    $dbh->ora_lob_write( $char_locator, 1, $seq_string );  #offset starts at 1
  }
  
  #store all ANNOTATION_FEATURE
  if($self->sequence) {
    foreach my $sf ($self->sequence->get_all_SeqFeatures()) {
      $self->store_feature($sf);
    }
  }
}


sub store_feature {
  my $self = shift;
  my $sf = shift;

  my $tags = {};
  my $ac = $sf->annotation;
  if($ac->get_num_of_annotations) {
    foreach my $key ( $ac->get_all_annotation_keys() ) {
      my @anno_list = $ac->get_Annotations($key);
      foreach my $annotation ( @anno_list ) {
        $tags->{$key} = $annotation->value;
        unless($sf->display_name) {
          $sf->display_name($annotation->value);
        }
      }
    }
  }
  my $tags_json;
  if (keys %{ $tags }) {
    $tags_json = to_json($tags);
  }

  my $dbID = $self->next_sequence_id('seq_annotation_feature');  
  my $dbh = $self->database->get_connection;  
  my $sql = qq/
      INSERT INTO ANNOTATION_FEATURE (
        ANNOTATION_FEATURE_ID,
        ENGINEERED_SEQ_ID,
        SOURCE_TAG,
        LABEL,
        LOC_START,
        LOC_END,
        ORI,
        COMMENTS,
        TAGS
      ) 
      VALUES(?,?,?,?,?,?,?,?,?)/;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->id);
  $sth->bind_param(3, $sf->primary_tag);
  $sth->bind_param(4, $sf->display_name);
  $sth->bind_param(5, $sf->start);
  $sth->bind_param(6, $sf->end);
  $sth->bind_param(7, $sf->strand);
  $sth->bind_param(8, undef);
  $sth->bind_param(9, $tags_json);
  $sth->execute();
  $sth->finish;
    
}


sub fetch_features {
  my $self = shift;  

  my $sql = "SELECT * from ANNOTATION_FEATURE where ENGINEERED_SEQ_ID=?";
  my $dbh = $self->database->get_connection;
  my $sth = $dbh->prepare($sql);
  $sth->execute($self->id);

  while(my $row_hash = $sth->fetchrow_hashref) {
    my $tag;
    try {
       $tag = from_json( $row_hash->{'TAGS'} );
    }
    catch {
        $tag = eval( $row_hash->{'TAGS'} );
    };
    
    my $feat = new Bio::SeqFeature::Generic ( 
              -start        => $row_hash->{'LOC_START'}, 
              -end          => $row_hash->{'LOC_END'},
              -strand       => $row_hash->{'ORI'}, 
              -primary      => $row_hash->{'SOURCE_TAG'}, #?
              -source_tag   => $row_hash->{'SOURCE_TAG'},
              -display_name => $row_hash->{'LABEL'},
              -tag          => $tag
    );
    $self->sequence->add_SeqFeature($feat);
  }
  
  $sth->finish;
  return $self;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  #printf("EngineeredSeq::fetch_by_id\n");
  #printf("  class=%s\n", $class);
  if($__ivsa_engineeredseq_global_should_cache != 0) {
    my $engseq = $__ivsa_engineeredseq_global_id_cache->{$db . $id};
    return $engseq if(defined($engseq));
  }
  
  my $sql = "SELECT subclass FROM engineered_seq WHERE engineered_seq_id = ?";
  my $subclass = $class->fetch_col_value($db, $sql, $id);
  #printf("sublass=(%s)\n", $subclass);
  
  if($subclass eq 'genomic_region') {
    return TargetedTrap::IVSA::GenomicRegion->fetch_by_id($db, $id);
  } elsif($subclass eq 'synthetic_vector') {
    return TargetedTrap::IVSA::SyntheticConstruct->fetch_by_id($db, $id);
  } else {
    $sql = "SELECT * FROM engineered_seq WHERE engineered_seq_id = ?";
    return $class->fetch_single($db, $sql, $id);
  }
}


sub fetch_by_name {
  my $class = shift;
  my $db = shift;
  my $name = shift;
  
  if($__ivsa_engineeredseq_global_should_cache != 0) {
    my $seqread = $__ivsa_engineeredseq_global_name_cache->{$db . $name};
    return $seqread if(defined($seqread));
  }
  
  my $sql = "SELECT * FROM engineered_seq WHERE name = ?";
  return $class->fetch_single($db, $sql, $name);
}


sub fetch_all_alignments {
  my $self = shift;
  #reset all hits, flushes and reloads all hits
  my $hits = TargetedTrap::IVSA::AlignFeature->fetch_all_by_engseq_id($self->database, $self->engineered_seq_id);
  $self->{'_hits'} = $hits;
  foreach my $hit (@{$hits}) {
    $hit->engineered_seq($self); #avoids lazy load
  }
  return 0;
}


1;

