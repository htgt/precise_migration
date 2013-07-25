### TargetedTrap::IVSA::AlignFeature
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

YASAP : Yet Another Sequence Alignment Pair 
Yet Another attempt at creating a clean object to represent HSP (alignment pairs)
as parsed from cigar lines and stored in a database

Multiple inheritance (TargetedTrap::DBObject and Bio::CigarSeqPair) to 
facilitate integration of CigarSeqPair objects into the Eucomm/Komp
vector QC database system.

Part of the Vector QC system.  This object can manage alignments from any
SeqRead in the system against any EngineeredSeq type object.  This includes
SyntheticConstruct, GenomicRegion, VectorComponent, and SyntheticAllele
objects.

=head1 CONTACT

Contact Jessica Severin on implemetation/design detail: jessica@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::AlignFeature;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::SeqRead;
use TargetedTrap::IVSA::EngineeredSeq;

use Bio::CigarSeqPair;
use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject Bio::CigarSeqPair);


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

  $self->{'seqread'} = undef;
  $self->{'engineered_seq'} = undef;
  $self->{'is_best'} = "";  
  $self->{'loc_status'} = 'locfail';
  $self->{'extra_info'} = {};
  $self->{'overlapping_features'} = undef;
  
	if($args{-cigar}) {
    $self->init_from_cigar_output($args{-cigar});
  }

	return $self;
}


sub copy {
  #make a copy of this alignment
  my $self = shift;
  
  my $hit = new TargetedTrap::IVSA::AlignFeature(-cigar => $self->raw_alignment);    
  $hit->engineered_seq($self->engineered_seq);
  $hit->seqread($self->seqread); 

  return $hit;
}

##########################################

sub seqread {
  my $self = shift;
  if(@_) {
    my $seqread = shift;
    unless(defined($seqread) && $seqread->isa('TargetedTrap::IVSA::SeqRead')) {
      throw('seqread param must be a TargetedTrap::IVSA::SeqRead');
    }
    $self->{'seqread'} = $seqread;
    $self->q_cigarseq->sequence($seqread->sequence);  
    #no auto reverse linking (adding the hit to the seqread)
  }
  
  #lazy load from database if possible
  if(!defined($self->{'seqread'}) and 
     defined($self->database) and 
     defined($self->{'seq_read_id'}))
  {
    #lazy load from database if possible
    my $seqread = TargetedTrap::IVSA::SeqRead->fetch_by_id($self->database, $self->{'seq_read_id'});
    if(defined($seqread)) {
      $self->{'seqread'} = $seqread;
      $self->q_cigarseq->sequence($seqread->sequence);  
      $self->q_cigarseq->name($seqread->trace_label);  
      $seqread->add_hit($self); #reverse linking only done for lazy_load
    }
  }

  return $self->{'seqread'};
}


sub engineered_seq {
  my ($self, $eng_seq) = @_;
  if($eng_seq) {
    unless(defined($eng_seq) && $eng_seq->isa('TargetedTrap::IVSA::EngineeredSeq')) {
      throw('engineered_seq param must be a TargetedTrap::IVSA::EngineeredSeq');
    }
    $self->{'engineered_seq'} = $eng_seq;
    $self->h_cigarseq->sequence($eng_seq->sequence);  
    $self->h_cigarseq->name($eng_seq->name);
  }
  
  #lazy load from database if possible
  if(!defined($self->{'engineered_seq'}) and 
     defined($self->database) and 
     defined($self->{'engineered_seq_id'}))
  {
    #lazy load from database if possible
    my $eng_seq = TargetedTrap::IVSA::EngineeredSeq->fetch_by_id($self->database, $self->{'engineered_seq_id'});
    if(defined($eng_seq)) {
      $self->{'engineered_seq'} = $eng_seq;
      $self->h_cigarseq->sequence($eng_seq->sequence);  
      $self->h_cigarseq->name($eng_seq->name);
      $eng_seq->add_hit($self);
    }
  }

  return $self->{'engineered_seq'};
}

sub is_expected {
  #convenience method to check if this is an alignment with the expected design
  my $self = shift;
  if(defined($self->engineered_seq) and 
     defined($self->seqread) and
     defined($self->seqread->clone) and
     defined($self->seqread->clone->expected_engineered_seq) and
     ($self->seqread->clone->expected_engineered_seq->unique_id eq 
      $self->engineered_seq->unique_id))
  { return 'is_expected'; }
  else { return ''; }
}

sub loc_status {
  my $self = shift;
  $self->{'loc_status'} = shift if @_;
  return $self->{'loc_status'};
}

sub extra_info {
  my ($self, $tag) = @_;
  if($tag) {
    $self->{'extra_info'}->{$tag} = $tag;
  }
  my $str = join(',', keys(%{$self->{'extra_info'}}));
  return $str;
}

##########################################

sub has_feature {
  my $self = shift;
  my $feat_name = shift;
  
  unless(defined($self->{'overlapping_features'})) {
    $self->_load_overlapping_features;
  }
  my $found = $self->{'overlapping_features'}->{$feat_name};
  return $found;
}

sub _load_overlapping_features {
  my $self = shift;

  $self->{'overlapping_features'} = {};
  my $engseq  = $self->engineered_seq;
  return unless($engseq);
  my $sf_list = $engseq->seqfeatures_in_range($self->h_cigarseq->start, $self->h_cigarseq->end);
  foreach my $sf (@$sf_list) {
    my $ac = $sf->annotation;
    if($ac) {
      foreach my $key ( $ac->get_all_annotation_keys() ) {
        next if($key eq 'translation');
        foreach my $annotation ( $ac->get_Annotations($key) ) {
          $self->{'overlapping_features'}->{$annotation->value} = $sf;
        }
      }        
    }
  }
}

sub show_features {
  my $self = shift;

  my $seqread = $self->seqread;
  my $engseq  = $self->engineered_seq;
  return unless($engseq);
  my $sf_list = $engseq->seqfeatures_in_range($self->h_cigarseq->start, $self->h_cigarseq->end);
  foreach my $sf (@$sf_list) {
    printf("  %s : %d-%d %d", 
          $sf->primary_tag, 
          $sf->start, $sf->end, $sf->strand);
    my $ac = $sf->annotation;
    if($ac) {
      foreach my $key ( $ac->get_all_annotation_keys() ) {
        next if($key eq 'translation');
        my @anno_list = $ac->get_Annotations($key);
        foreach my $annotation ( @anno_list ) {
          # value is an Bio::AnnotationI, and defines a "as_text" method
          print " : ", $key,"=[", $annotation->value,"]";
        }
      }        
    }
    printf("\n");
  }
}


sub observed_features {
  my $self = shift;
  
  unless($self->{'feature_string'}) {     
    unless(defined($self->{'overlapping_features'})) {
      $self->_load_overlapping_features;
    }
    $self->{'feature_string'} = join(', ', keys %{$self->{'overlapping_features'}});
  }
  return $self->{'feature_string'};
}


##########################################

sub description {
  my $self = shift;
  my $seqread = $self->seqread;

  my $str = sprintf("HIT(%s) %4s (%s) : ", $self->id, $seqread->oligo_name, $seqread->clone_tag);

  my $status = $self->loc_status;
  if($self->extra_info) { $status .= sprintf("(%s)", $self->extra_info); }
  $str .= sprintf("%11s", $status);

  $str .= sprintf("%5s %6.2f/%6.2f ", 
          $self->cmatch,
          $self->map_score, $self->percent_identity);

  my $tstr = sprintf("q:%d-%d %s1", $self->q_cigarseq->start, $self->q_cigarseq->end,  $self->q_cigarseq->ori);
  while(length($tstr) < 17) { $tstr .= " "; }
  $str .= sprintf(": %s ", $tstr);

  $tstr = sprintf("h:%d-%d %s1", $self->h_cigarseq->start, $self->h_cigarseq->end,  $self->h_cigarseq->ori);
  while(length($tstr) < 17) { $tstr .= " "; }
  $str .= sprintf(": %s ", $tstr);

  $str .= sprintf("Seqread(%s) ", $seqread->trace_label);

  if($self->engineered_seq) {
    $str .= sprintf("=> EngSeq(%s)", $self->engineered_seq->name);
  }
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

  #printf("processing maprow ", $rowHash, "\n"); 
   
  $self->primary_id($rowHash->{'SEQ_ALIGN_ID'});
  $self->evalue($rowHash->{'EVALUE'});
  $self->score($rowHash->{'SCORE'});
  $self->cmatch($rowHash->{'CMATCH'});
  $self->map_score($rowHash->{'MAP_SCORE'});
  $self->identity($rowHash->{'IDENTICAL_MATCHES'});
  $self->percent_identity($rowHash->{'PERCENT_IDENTITY'});
  $self->align_length($rowHash->{'ALIGN_LENGTH'});
  $self->loc_status($rowHash->{'LOC_STATUS'});
  $self->cigar_line($rowHash->{'CIGAR_LINE'});
  $self->comments($rowHash->{'COMMENTS'});

  $self->{'seq_read_id'} = $rowHash->{'SEQREAD_ID'};
  $self->{'engineered_seq_id'} = $rowHash->{'ENGINEERED_SEQ_ID'};

  my $qseq = $self->q_cigarseq;
  $qseq->start($rowHash->{'SEQREAD_START'});
  $qseq->end($rowHash->{'SEQREAD_END'});
  $qseq->ori($rowHash->{'SEQREAD_ORI'});
  $qseq->cigar_line($rowHash->{'CIGAR_LINE'});
  
  my $hseq = $self->h_cigarseq;
  $hseq->start($rowHash->{'ENGSEQ_START'});
  $hseq->end($rowHash->{'ENGSEQ_END'});
  $hseq->ori($rowHash->{'ENGSEQ_ORI'});
  #invert the cigar for the hit
  my $hcigar = $rowHash->{'CIGAR_LINE'};
  $hcigar =~ s/D/d/g;
  $hcigar =~ s/I/D/g;
  $hcigar =~ s/d/I/g;
  $hseq->cigar_line($hcigar);
  
  return $self;
}


sub store {
    my $self = shift;
    my $db   = shift;
    if ($db) { $self->database($db); }

    if ( !defined( $self->seqread->primary_id ) ) {
        printf(
"ERROR!!!! can't store alignment because SeqRead (%s) has NULL seqread_id\n",
            $self->seqread->trace_label );
        return 1;
    }
    if ( !defined( $self->engineered_seq->id ) ) {
        printf(
"ERROR!!!! can't store alignment because EngineeredSeq has NULL ENGINEERED_SEQ_ID\n"
        );
        return 1;
    }

    if ( $self->test_exists ) { # if ( my $old_test = $self->test_exists ) {
		# if ( any { $old_test->{$_} ne $self->$_ } keys %{ $old_test } ) {
        my $dbh = $self->database->get_connection;
        my $sql = qq/
		UPDATE SEQ_ALIGN_FEATURE SET
        SCORE              = ?,
        EVALUE             = ?,
        ALIGN_LENGTH       = ?,
        IDENTICAL_MATCHES  = ?,
        PERCENT_IDENTITY   = ?,
        CMATCH             = ?,
        LOC_STATUS         = ?,
        COMMENTS           = ?,
        MAP_SCORE          = ?
		WHERE SEQ_ALIGN_ID = ?
		/;
        my $sth = $dbh->prepare($sql);
        $sth->execute(
            $self->score,            $self->evalue,
            $self->align_length,     $self->identity,
            $self->percent_identity, $self->cmatch,
            $self->loc_status,       $self->comments,
            $self->map_score,        $self->primary_id,
        );
        $sth->finish;
		# }
        return 1;
    }

    my $dbID = $self->next_sequence_id('seq_seq_align_feature');
    $self->primary_id($dbID);

    my $dbh = $self->database->get_connection;
    my $sql = qq/
      INSERT INTO SEQ_ALIGN_FEATURE (
          SEQ_ALIGN_ID,
          SEQREAD_ID,
          SEQREAD_START,
          SEQREAD_END,
          SEQREAD_ORI,
          ENGINEERED_SEQ_ID,
          ENGSEQ_START,
          ENGSEQ_END,
          ENGSEQ_ORI,
          SCORE,
          EVALUE,
          ALIGN_LENGTH,
          IDENTICAL_MATCHES,
          PERCENT_IDENTITY,
          CMATCH,
          LOC_STATUS,
          CIGAR_LINE,
          COMMENTS,
          MAP_SCORE
      ) 
      VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)/;
    my $sth = $dbh->prepare($sql);
    $sth->bind_param( 1, $dbID );
    $sth->bind_param( 2, $self->seqread->id );
    $sth->bind_param( 3, $self->q_cigarseq->start );
    $sth->bind_param( 4, $self->q_cigarseq->end );
    $sth->bind_param( 5, $self->q_cigarseq->ori );
    $sth->bind_param( 6, $self->engineered_seq->id );
    $sth->bind_param( 7, $self->h_cigarseq->start );
    $sth->bind_param( 8, $self->h_cigarseq->end );
    $sth->bind_param( 9, $self->h_cigarseq->ori );

    $sth->bind_param( 10, $self->score );
    $sth->bind_param( 11, $self->evalue );
    $sth->bind_param( 12, $self->align_length );
    $sth->bind_param( 13, $self->identity );
    $sth->bind_param( 14, $self->percent_identity );
    $sth->bind_param( 15, $self->cmatch );
    $sth->bind_param( 16, $self->loc_status );
    $sth->bind_param( 17, $self->cigar_line );
    $sth->bind_param( 18, $self->comments );
    $sth->bind_param( 19, $self->map_score );
    $sth->execute();
    $sth->finish;
}

sub test_exists {
  my $self = shift;
  
  my $dbh = $self->database->get_connection;
  my $sql = qq/
        SELECT SEQ_ALIGN_ID 
        FROM seq_align_feature WHERE
            SEQREAD_ID=? AND
            SEQREAD_START=? AND
            SEQREAD_END=? AND
            SEQREAD_ORI=? AND
            ENGINEERED_SEQ_ID=? AND
            ENGSEQ_START=? AND
            ENGSEQ_END=? AND
            ENGSEQ_ORI=? AND
            CIGAR_LINE=?
         /;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->seqread->id);
  $sth->bind_param(2, $self->q_cigarseq->start);
  $sth->bind_param(3, $self->q_cigarseq->end);
  $sth->bind_param(4, $self->q_cigarseq->ori);
  $sth->bind_param(5, $self->engineered_seq->id);
  $sth->bind_param(6, $self->h_cigarseq->start);
  $sth->bind_param(7, $self->h_cigarseq->end);
  $sth->bind_param(8, $self->h_cigarseq->ori);
  $sth->bind_param(9, $self->cigar_line);
  $sth->execute();
  my ($dbID) = $sth->fetchrow_array(); # fetchrow_hashref
  $sth->finish;
  
  if(defined($dbID)) { 
    $self->primary_id($dbID);
    return 1; # return a hashref
  } 
  return 0;
}



##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM seq_align_feature WHERE seq_align_id = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_by_seqread_id {
  my $class = shift;
  my $db = shift;
  my $seqread_id = shift;
  
  my $sql = "SELECT * FROM seq_align_feature WHERE seqread_id = ?";
  return $class->fetch_multiple($db, $sql, $seqread_id);
}

sub fetch_all_by_vector_construct_id {
  my $class = shift;
  my $db = shift;
  my $vector_construct_id = shift;
  
  my $sql = "SELECT * FROM seq_align_feature WHERE id_vector_construct = ?";
  return $class->fetch_multiple($db, $sql, $vector_construct_id);
}

1;

