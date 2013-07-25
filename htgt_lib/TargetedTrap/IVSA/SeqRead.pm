### TargetedTrap::SeqRead
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Hacked by david.jackson@sanger.ac.uk
# Was maintained by Jessica Severin (jessica@sanger.ac.uk) 
# Was maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author las
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact Team87 on implemetation/design detail: htgt@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

#three global variables (in a true OO language these would be class private variables)
#keys are a composite of the databae and either the id or trace_label
my $__ivsa_seqread_global_id_cache = {};
my $__ivsa_seqread_global_trace_label_cache = {};
my $__ivsa_seqread_global_should_cache = 0;


package TargetedTrap::IVSA::SeqRead;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::ConstructClone;

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# Class methods
#################################################

sub set_cache_behaviour {
  my $class = shift;
  my $mode = shift;
  
  $__ivsa_seqread_global_should_cache = $mode;
  
  if(defined($mode) and ($mode eq '0')) {
    #if turning off caching, then flush the caches
    $__ivsa_seqread_global_id_cache = {};
    $__ivsa_seqread_global_trace_label_cache = {};
  }
}


sub new_from_fasta {
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
    $obj->trace_label($bioseq->id); 
    $obj->convert_trace_label();
    if($bioseq->desc =~ /bases (\d+) to (\d+)/) {
      $obj->ql($1);
      $obj->qr($2);
    }
  }
  return $obj;
}


sub _clipped_dna { #helper function for new_from_traceserver_project
  #get all clip info and provides most clipped seq
  my$s=shift; 
  my(@l,@r); 
  for(map{$s->get_clip($_)} 0..($s->get_num_clips -1)){push @l,$_->get_start; push @r,$_->get_end} 
  my($l)=sort{$b<=>$a}grep{$_}@l; 
  my($r)=sort{$a<=>$b}grep{$_}@r; 
  return (undef,$l,$r) if $r<$l;
  my$dna=$s->get_dna; 
  $dna=substr($dna,0,$r); 
  $dna=substr($dna,$l-1); 
  return ($dna,$l,$r);
} 

sub new_from_traceserver_project {
  #returns an array of SeqRead objects created from Internal TraceServer project
  my ($class, $project) = @_;
  my @r;

  use TraceServer; 
  my $ts = TraceServer->new(TS_DIRECT, TS_READ_ONLY, "") or die "Could not connect to Internal Trace Server"; 
  my $group = $ts->get_group($project, q(PROJ)) or die "Could not get group for project $project from Internal Trace Server"; 
  # warn "new_from_traceserver_project: ".join(" ",$group->get_name, $group->get_type, $group->count_members)."\n";
  
  my %donereads; 
  my $cnd=0; 
  foreach (@{$group->get_members}){#little bit odd this: we get sequences for the project
    my$r=$ts->get_read_by_seq_id($_); #we get the read for the sequence
    my $ds=$r->get_sequence; #we get the default sequence for the read
    if ($_==$ds->get_id) { #we only consider sequences which are the default sequence for their read

      # next unless $r->get_name =~ m/HEPD0637_1_A.*a01/; # DEBUGGING

      my ($seq,$lc,$rc) = _clipped_dna($ds);
      my $desc = join(", ", $r->get_status_description, (map{$_->get_type.":".$_->get_start.",".$_->get_end}map{$ds->get_clip($_)}0..($ds->get_num_clips -1)), "ts_seq_id:".$ds->get_id);
      my $bs = Bio::Seq->new( -id => $r->get_name, -seq => $seq, -alphabet => 'dna', -desc => $desc);
      my $obj = $class->new();
      $obj->{_desc} = $desc; #yuck - but we need somewhere to stuff the desc when there is no bioseq
      $obj->sequence($bs) if $r->get_status_description =~ /PASS/i; #don't put bioseq object in if fail....
      $obj->trace_label($r->get_name);
      $obj->convert_trace_label();
      $obj->ql($lc);
      $obj->qr($rc);
      push @r, $obj;
    }else{
      $cnd++ ;
    }
    $donereads{$r->get_name}++; 
  }
  my $crr = scalar(grep{$_>1}values%donereads); 
  warn "new_from_traceserver_project: $crr reads repeated, $cnd members with non default sequence\n" if $crr or $cnd;
  return \@r;
}

#################################################
# Instance methods
#################################################


sub init {
  my $self = shift;
  $self->SUPER::init;
  
  $self->{'_primer'} = undef; #object
  $self->{'_clone'} = undef; #TargetedTrap::IVSA::ConstructClone

  $self->{'_trace_label'} = undef;
  $self->{'_plate'} = '';
  $self->{'_clone_num'} = '';
  $self->{'_well'} = '';
  $self->{'_oligo_name'} = '';
  $self->{'_iteration'} = '';
#  $self->{'_plate_iteration'} = '';  ##### use this for the amalgamated plate 7 runs!!
  $self->{'_plate_iteration'} = 'A';
  $self->{'_contamination'} = undef;
  
  $self->{'_sequence'} = undef; #Bio::Seq object
  $self->{'_hits'} = [];
  
  return $self;
}

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->{'_sequence'} = undef;
  $self->{'_trace'} = undef;
  $self->{'_hits'} = undef;
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

sub primer_oligo {
  my $self = shift;
  $self->{'_primer'} = shift if @_;
  return $self->{'_primer'};
}


sub clone {
  my $self = shift;

  #set if parameter is provided
  if(@_) {
    my $clone = shift;
    unless($clone->isa('TargetedTrap::IVSA::ConstructClone')) {
      throw('$clone is not a TargetedTrap::IVSA::ConstructClone');
    }
    $self->{'_clone'} = $clone;
  }

  #lazy load from database if possible
  if(!defined($self->{'_clone'}) and 
     defined($self->database) and 
     defined($self->vector_batch_id))
  {
    #lazy load from database if possible
    my $clone = TargetedTrap::IVSA::ConstructClone->fetch_by_vector_batch_id(
         $self->database, $self->vector_batch_id);
    if(defined($clone)) {
      $self->{'_clone'} = $clone;
      $clone->add_seqread($self);
    }
  }

  return $self->{'_clone'};
}

#sub vector_batch_id {
#  my $self = shift;
#  $self->{'_vector_batch_id'} = shift if @_;
#  return $self->{'_vector_batch_id'};
#}

sub trace_label {
  my $self = shift;
  $self->{'_trace_label'} = shift if @_;
  $self->{'_trace_label'} = '' unless defined($self->{'_trace_label'});
  return $self->{'_trace_label'};
}

sub contamination {
  my $self = shift;
  $self->{'_contamination'} = shift if @_;
  return $self->{'_contamination'};
}

sub ql {
  my $self = shift;
  $self->{'_ql'} = shift if @_;
  return $self->{'_ql'};
}
sub qr {
  my $self = shift;
  $self->{'_qr'} = shift if @_;
  return $self->{'_qr'};
}
sub quality_length {
  my $self = shift;
  if(defined($self->ql) and defined($self->qr)) {
    return $self->qr - $self->ql;
  } else { return undef; }
}

sub plate {
  #PC00004 or PG00004 or PCD00004_A or PGD00004_A or GR00002_A
  my $self = shift;
  if(@_) {
    my $plate = shift;
    $self->{'_plate'} = $plate;
    if($plate =~ /P[CG]D?(\d+)/) {
      $self->{'_plate_num'} = int($1);
    }elsif($plate =~ /([A-Z]{2,7}\d+(?:_\d+)?)/i) {
      $self->{'_plate_num'} = $1;
    }else{warn qq(Problem with plate name "$plate")}
  }
  $self->{'_plate'} = '' unless defined($self->{'_plate'});
  return $self->{'_plate'};
}

sub plate_num {
  my $self = shift;
  return $self->{'_plate_num'};
}

sub plate_iteration {
  my $self = shift;
  $self->{'_plate_iteration'} = shift if @_;
#  $self->{'_plate_iteration'} = 'A' unless (defined($self->{'_plate_iteration'}) && ($self->{'_plate'} eq "PG00007"));
  return $self->{'_plate_iteration'};
}

sub project {
  # readonly method returns plate and clone_interation like 'PC00010_A'
  my $self = shift;
  if (($self->{'_plate'} eq "PG00007") && !($self->plate_iteration)) {
      return sprintf("%s", $self->plate);
  }
  else {
      return sprintf("%s_%s", $self->plate, $self->plate_iteration);
  }
}

sub clone_num {
  my $self = shift;
  $self->{'_clone_num'} = shift if @_;
  $self->{'_clone_num'} = '' unless defined($self->{'_clone_num'});
  return $self->{'_clone_num'};
}

sub iteration {
  my $self = shift;
  $self->{'_iteration'} = shift if @_;
  $self->{'_iteration'} = '' unless defined($self->{'_iteration'});
  return $self->{'_iteration'};
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

sub clone_tag {
    my $self = shift;
    unless ( $self->clone ) {
        # $self->clone( TargetedTrap::IVSA::ConstructClone->new_from_seqread($self) );
        die "No Clone set for SeqRead [" . $self->trace_label . "]"
    }
    return $self->clone->clone_tag;
}

sub oligo_name {
  #eventually will be replaces by redirecting
  #call to the Oligo/Primer object
  my $self = shift;
  $self->{'_oligo_name'} = shift if @_;
  if(defined($self->primer_oligo)) {
    return $self->primer_oligo->name;
  }
  return $self->{'_oligo_name'};
}

sub sequence {
  #eventually will be replaces by redirecting
  #call to the Oligo/Primer object
  my $self = shift;
  if(@_) {
    my $seq = shift;
    unless(defined($seq) && $seq->isa('Bio::Seq')) {
      print('sequence argument must be a Bio::Seq');
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

sub add_hit {
  my $self = shift;
  my $hit = shift;
  push @{$self->{'_hits'}}, $hit; 
}

sub hits {
  my $self = shift;
  return $self->{'_hits'};
}

sub convert_trace_label {
  my $self = shift;
	
  my $label = $self->trace_label();
  my $well = undef;
  my $primer = undef;
  
  #printf("convert_trace_label : %s :", $label."\n");
  
  # PC000012a08.p1ke		# read naming style
  if($label =~ /(P[CG]\d\d\d\d\d)(\d\d?)([a-hA-H]\d\d?)\.p1k([a-z]?)/) {
    #printf(" mode1\n");
    $self->plate($1);
    $self->clone_num($2);
    $well = uc($3);  
    $primer = $4;
    
    if(!defined($primer)) { $primer = "_"; };
    if($primer eq '') { $primer = '_'; }
    $self->trace_primer_to_oligo_name($primer, 1);
    $well =~ /(\w)(\d+)/;
    $self->well($well);
  }

  # try generic matching... 
  # HTGR01001_A4h12.p1kePNF EPD0014_1_A_1b02.p1kjR3 PC00007_1b03.p1kbLRR GR0007_A_1b02.p1kR3 GW00007_a_1b02.p1kjR3 EPD00229_5_B_1-1h12.p1k HEPD00525_1_1_B_1a04.p1kR2R RHEPD0017_B1h03.p1kaR2R PC00071_A_4h12.p1kaLRR PG00102_Y_4h10.p1keLR EPD00230_1_A_1_2f11.p1kLR
  
  # old regular expression, for reference
  #elsif($label =~ /^([A-Z]+\d+(?:_\d\d?)?)(?:_\d)?_([A-Za-z])?(?:_\d)?_?(\d-?\d?)([A-Za-z]\d\d?)\.p1k([a-z]?)(\w*)$/) {
  #elsif($label =~ /^([A-Z]+\d+(?:_\d\d?)?)(?:_\d)?_([A-Za-z])?(?:_\d)?_(\d-?\d?)([A-Za-z]\d\d?)\.p1k([a-z]?)(\w*)$/) {
 
  elsif ( $label =~ $TargetedTrap::IVSA::Constants::PLATE_REGEXP ) {
  
    #printf(" mode4\n");
    $self->plate($1);
    $self->plate_iteration($2) if defined($2);
    $self->clone_num($3);
    $well = uc($4);  
    my $iteration = $5;
    $primer = $6;
    
    if($primer =~ /^([A-Z0-9]+)[a-z]?$/){
      if(!($primer eq $1)){
        warn "read $label - replacing primer name $primer with $1\n";
        $primer = $1;
      }
    }else{
      die "primer name $primer doesn't split into an upper-case-plus-number and an optional lower-case part\n";
    }

    $iteration ||= "_";
    $self->oligo_name($primer);
    #$well =~ /(\w)(\d+)/;
    $self->well($well);
    $self->iteration($iteration) if defined($iteration);
  }
  else{warn qq(Problem with trace label "$label")}
    
  #printf("%s : primer='%s'  oligo_name = %s\n", $label, $primer, $self->oligo_name);
  #$self->display_info;
}

 

sub trace_primer_to_oligo_name {
	my $self = shift;
  my $label = shift;
  my $pset = shift;
  #printf("convert '%s' pset=%d\n", $label, $pset);
  
  my $PM = {};
  if ($pset == 1 ) {
    #plate PC00003
    $PM = {
          ''  => 'R3',
          '_' => 'R3',
          'a' => 'R4',
          'b' => 'LRR',
          'c' => 'LFR',
          'd' => 'R1R',
          'e' => 'R2R',
          'f' => 'Z1',
          'g' => 'Z2',
          'h' => 'R3F',
          'i' => 'R4R',
          'j' => 'R3',
          'k' => 'R4',
          'l' => 'LRR',
          'm' => 'LFR',
          'n' => 'Z1',
          'o' => 'R2R',
          'p' => 'IFRT',
    };
  } else {
    throw("UNKNOWN PSET ($pset) in SeqRead\n");
  }

  my $oligo = $PM->{$label};
  if(defined($oligo)) { $self->oligo_name($oligo); }

}


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
  my $str = sprintf("SeqRead(%s) %23s : %d q(%d-%d) : %s_%s_%s_%s %3s (%s) : %s....", 
    $id,
    $self->trace_label,
    $self->seq_length,
    $self->ql, $self->qr,
    $self->plate,
    $self->plate_iteration,
    $self->well,
    $self->clone_num,
    $self->oligo_name, 
    $self->iteration,
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

  # ID_SEQ_READ                            NOT NULL NUMBER(38)
  # ID_VECTOR_BATCH                        NOT NULL NUMBER(38)
  # PRIMER_OLIGO_ID                        NOT NULL NUMBER(38)
  # READ_NAME                              VARCHAR2(1024)
  # PROJECT_NAME                           VARCHAR2(512)
  # CLONE_NUM                              VARCHAR2(512)
  # ITERATION                              NUMBER(38)
  # PLATE                                  VARCHAR2(512)
  # WELL                                   VARCHAR2(10)
  # SEQUENCE                               CLOB
 
  $self->primary_id($rowHash->{'SEQREAD_ID'});
#  $self->vector_batch_id($rowHash->{'ID_VECTOR_BATCH'});
  $self->trace_label($rowHash->{'READ_NAME'});
  $self->plate($rowHash->{'PLATE_NAME'});
  $self->clone_num($rowHash->{'CLONE_NUM'});
  $self->iteration($rowHash->{'ITERATION'});
  $self->well($rowHash->{'WELL'});
  $self->ql($rowHash->{'QL'});
  $self->qr($rowHash->{'QR'});
  $self->oligo_name($rowHash->{'OLIGO_NAME'});
  $self->plate_iteration($rowHash->{'PLATE_ITERATION'});
  
  # read SEQUENCE CLOB
  my $lob_locator = $rowHash->{'SEQUENCE'}; 
  my $lob_length = $dbh->ora_lob_length($lob_locator);
  if(($lob_length > 0) and ($lob_locator)) {
    my $seq_data = $dbh->ora_lob_read($lob_locator, 1, $lob_length);
    my $bioseq = Bio::Seq->new(-id=>$self->trace_label, -seq=>$seq_data);
    $self->sequence($bioseq); 
  }

  if($__ivsa_seqread_global_should_cache != 0) {
    #hash the oligos since they are constants for a given database and oligo_id
    $__ivsa_seqread_global_id_cache->{$self->database() . $self->id} = $self;
    $__ivsa_seqread_global_trace_label_cache->{$self->database() . $self->trace_label} = $self;
  }

  #printf("fetched : %s\n", $self->description);

  return $self;
}


sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }
    
  my $dbID = $self->next_sequence_id('seq_qc_seqread');
  $self->primary_id($dbID);
    
  my $dbh = $self->database->get_connection;  
  my $sql = qq/
      INSERT INTO QC_SEQREAD (
        SEQREAD_ID,
        PRIMER_OLIGO_ID,
        READ_NAME,
        PLATE_NAME,
        CLONE_NUM,
        ITERATION,
        PLATE_NUMBER,
        WELL,
        COMMENTS,
        QL,
        QR,
        QUALITY_LENGTH,
        OLIGO_NAME,
        CONSTRUCT_CLONE_ID,
	PLATE_ITERATION, 
	SEQUENCE) 
	VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?, EMPTY_CLOB())/;
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
#  $sth->bind_param(2, $self->clone->vector_batch_id); 
  if($self->primer_oligo) { 
    $sth->bind_param(2, $self->primer_oligo->id);
  } else {
    $sth->bind_param(2, undef);
  }
  $sth->bind_param(3, $self->trace_label);
  $sth->bind_param(4, $self->plate);
  $sth->bind_param(5, $self->clone_num);
  $sth->bind_param(6, $self->iteration);
  $sth->bind_param(7, $self->plate_num);
  $sth->bind_param(8, $self->well);
  $sth->bind_param(9, $self->{_desc}||$self->sequence->desc);
  $sth->bind_param(10, $self->ql);
  $sth->bind_param(11, $self->qr);
  $sth->bind_param(12, $self->quality_length);
  $sth->bind_param(13, $self->oligo_name);
  $sth->bind_param(14, $self->clone->id);
  $sth->bind_param(15, $self->plate_iteration);
  $sth->execute();
  $sth->finish;
#        ID_VECTOR_BATCH,

  #now store the sequence into the CLOB
  my $seq_string = '';
  if(defined($self->sequence)) { $seq_string = $self->sequence->seq; }
  if($seq_string) { 
    $sql = "SELECT sequence FROM qc_seqread WHERE seqread_id=? FOR UPDATE";
    $sth = $dbh->prepare( $sql, { ora_auto_lob => 0 } );
    $sth->execute( $dbID );
    my ( $char_locator ) = $sth->fetchrow_array();
    $sth->finish();
    #print("char_loc = ", $char_locator, "\n");

    $dbh->ora_lob_write( $char_locator, 1, $seq_string );  #offset starts at 1
  }

}




##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  if($__ivsa_seqread_global_should_cache != 0) {
    my $seqread = $__ivsa_seqread_global_id_cache->{$db . $id};
    return $seqread if(defined($seqread));
  }
  
  my $sql = "SELECT * FROM qc_seqread WHERE seqread_id = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_by_trace_label {
  my $class = shift;
  my $db = shift;
  my $label = shift;
  
  if($__ivsa_seqread_global_should_cache != 0) {
    my $seqread = $__ivsa_seqread_global_trace_label_cache->{$db . $label};
    return $seqread if(defined($seqread));
  }
  
  my $sql = "SELECT * FROM qc_seqread WHERE read_name = ? order by seqread_id desc";
  return $class->fetch_single($db, $sql, $label);
}


sub fetch_all_alignments {
  my $self = shift;
  #reset all hits, flushes and reloads all hits
  my $hits = TargetedTrap::IVSA::AlignFeature->fetch_all_by_seqread_id($self->database, $self->id);
  $self->{'_hits'} = $hits;
  foreach my $hit (@{$hits}) {
    $hit->seqread($self); #avoids lazy load
  }
  return 0;
}



1;

