### Bio::CigarSeqPair
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Jessica Severin (jessica@sanger.ac.uk) 
# author jessica
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION

YASAP : Yet Another Sequence Alignment Pair 
Yet Another attempt at creating a clean object to represent HSP (alignment pairs)
as parsed from cigar line output (SSAHA2 and exonerate output options)

Uses Bio::CigarSeq objects to manage each sequence of the alignment pair.

CigarSeq is a wrapper around a Bio::Seq to hold cigar_line based alignment 
information to easily facilitate database storage and conversion 
into SimpleAlign and also maintaining the low memory footprint idea
of the cigar format.

The Bio::Seq object is not manipulated so it can be shared among many
CigarSeq objects and is in the original form in which it was inputed
into the alignment program (SSAHA2 or exonerate).  All manipulations
to reconstruct the alignment and to do alignment analysis are calculated
as needed and do not modify the original Bio::Seq data.

This makes for a rather thin wrapper around the Bio::Seq and cigar alignment data.  
It also makes memory usage more minimal since the sequences are not being copied, 
modified and stored in each alignment like in the SimpleAlign/LocatableSeq objects. 

The coordinate system of the cigar line is 0 referenced start..end exclusive
so length = end - start.  So a perfect alignment on the first ten bases of a
sequence would be recorded 0..10  M10

=head1 CONTACT

Author: Jessica Severin : jessica@sanger.ac.uk, jessica.severin@gmail.com

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=for Pod::Coverage::TrustPod
    align_length
    calc_identity
    cigar_line
    cmatch
    comments
    description
    display_info
    evalue
    get_simple_align
    get_subalignment
    h_cigarseq
    identity
    init
    init_from_cigar_output
    map_score
    new
    percent_identity
    print_pair_format_alignment
    q_cigarseq
    raw_alignment
    score

=cut

package Bio::CigarSeqPair;

use strict;
use Bio::Seq;
use Bio::SimpleAlign;

#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use Bio::CigarSeq;


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

sub DESTROY {
  my $self = shift;
  #If I need to do any cleanup - do it here
  $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}


#################################################
# Instance methods
#################################################


sub init {
  my $self = shift;
  my %args = @_;

  $self->{'raw'} = undef;
  $self->{'cigar_line'} = undef;
  $self->{'score'} = undef;
  $self->{'map_score'} = undef;
  $self->{'cmatch'} = undef;
  $self->{'evalue'} = undef;
  $self->{'comments'} = undef;
  $self->{'ident'} = undef;
  $self->{'perc_ident'} = undef;
  $self->{'align_length'} = undef;
  
  if($args{-cigar}) {
    $self->init_from_cigar_output($args{-cigar});
  }

	return $self;
}

sub init_from_cigar_output {
  my $self = shift;
	my $hit_line = shift;
  
  $self->raw_alignment($hit_line);
  
  #cigar: PC00008_1a11.p1ktZ1 0 414 - 2:163055045:163079816:-1:OTTMUSE00000010167 12746 13161 + 404 M 91 D 1 M 323

	my @f = split(/\s+/,$hit_line);
  
  my $qseq = $self->q_cigarseq;
  #$qseq->sequence(...);  
  $qseq->name($f[1]);
  $qseq->start($f[2]);
  $qseq->end($f[3]);
  $qseq->ori($f[4]);
  
  my $hseq = $self->h_cigarseq;
  #$hseq->sequence(...);  
  $hseq->name($f[5]);
  $hseq->start($f[6]);
  $hseq->end($f[7]);
  $hseq->ori($f[8]);

  $self->cmatch($f[9]);

  my $cigar = '';
  for(my $x=10; $x<scalar(@f); $x++) { $cigar .= $f[$x]; }
  $self->cigar_line($cigar);

  #printf("  cigar = '%s'\n", $cigar);


  #need both(q/h) wrapped BioSeqs for this to work 
  #$self->calc_identity; 
  
	return $self;
}


##########################################

sub raw_alignment {
  my $self = shift;
  $self->{'raw'} = shift if @_;
  return $self->{'raw'};
}

sub cigar_line {
  my $self = shift;
  if(@_) {
    my $cigar = shift;
    $self->{'cigar_line'} = $cigar;
    $self->q_cigarseq->cigar_line($cigar);
  
    #invert the cigar for the hit D->I I->D
    my $hcigar = $cigar;
    $hcigar =~ s/D/d/g;
    $hcigar =~ s/I/D/g;
    $hcigar =~ s/d/I/g;
    $self->h_cigarseq->cigar_line($hcigar);
  }
  return $self->{'cigar_line'};
}

sub score {
  my $self = shift;
  $self->{'score'} = shift if @_;
  return $self->{'score'};
}

sub map_score {
  my $self = shift;
  $self->{'map_score'} = shift if @_;
  unless(defined($self->{'map_score'})) { $self->calc_identity; }
  return $self->{'map_score'};
}

sub cmatch {
  my $self = shift;
  $self->{'cmatch'} = shift if @_;
  return $self->{'cmatch'};
}

sub evalue {
  my $self = shift;
  $self->{'evalue'} = shift if @_;
  return $self->{'evalue'};
}

sub comments {
  my $self = shift;
  $self->{'comments'} = shift if @_;
  return $self->{'comments'};
}

sub identity {
  my $self = shift;
  $self->{'ident'} = shift if @_;
  unless(defined($self->{'ident'})) { $self->calc_identity; }
  return $self->{'perc_ident'};
}

sub percent_identity {
  my $self = shift;
  $self->{'perc_ident'} = shift if @_;
  unless(defined($self->{'perc_ident'})) { $self->calc_identity; }
  return $self->{'perc_ident'};
}

sub align_length {
  my $self = shift;
  $self->{'align_length'} = shift if @_;
  unless(defined($self->{'align_length'})) { $self->calc_identity; }
  return $self->{'align_length'};
}

sub calc_identity {
  my $self = shift;

  my $seq1 = $self->q_cigarseq->locatable_seq->seq;
  my $seq2 = $self->h_cigarseq->locatable_seq->seq;
  my $ident=0;
  for(my $x=0; $x<length($seq1); $x++) {
    if(substr($seq1,$x,1) eq substr($seq2, $x,1)) { $ident++; }
  }
  $self->{'align_length'} = length($seq1);
  $self->{'ident'} = $ident;
  $self->{'perc_ident'} = 100.0 * $ident / length($seq1);
  $self->{'map_score'} = $self->{'perc_ident'} * 
             ($self->q_cigarseq->align_length / $self->q_cigarseq->sequence->length);

  #printf("ident = %d\n", $ident); 
  #printf("align_length = %d\n", $self->{'align_length'});
  #printf("perc_ident = %1.2f\n", $self->{'perc_ident'});
  #printf("map_score = %1.2f\n", $self->{'map_score'});
}



#####################  Query  ###########################
sub q_cigarseq {
  my $self = shift;
  if(!defined($self->{'_q_cigarseq'})) {
    $self->{'_q_cigarseq'} = new Bio::CigarSeq;
  }
  return $self->{'_q_cigarseq'};
}


#####################  Hit  ###########################
sub h_cigarseq {
  my $self = shift;
  if(!defined($self->{'_h_cigarseq'})) {
    $self->{'_h_cigarseq'} = new Bio::CigarSeq;
  }
  return $self->{'_h_cigarseq'};
}


##########################################

sub description {
  my $self = shift;

  my $str = sprintf("HIT %s -> %s : ", $self->q_cigarseq->name, $self->h_cigarseq->name);
  
  $str .= sprintf("%s %1.2f/%1.2f  q:%d-%d %s1 ", 
          $self->cmatch,
          $self->map_score, $self->percent_identity,
          $self->q_cigarseq->start, $self->q_cigarseq->end, $self->q_cigarseq->ori);

  $str .= sprintf("h:%d-%d %s1 : %s", $self->h_cigarseq->start, $self->h_cigarseq->end,  $self->h_cigarseq->ori, $self->cigar_line);

  return $str;
}

sub display_info {
  my $self = shift;
  printf("%s\n", $self->description);
}

##########################################

sub get_simple_align {
  my $self = shift;
  
  my $sa = Bio::SimpleAlign->new();
  $sa->add_seq($self->q_cigarseq->locatable_seq);
  $sa->add_seq($self->h_cigarseq->locatable_seq);

  return $sa;
}


sub print_pair_format_alignment {
  my ($self, $aaPerLine) = @_;
  
  if(!defined($aaPerLine)) { $aaPerLine = 80; }
  
  my $seq1 = $self->q_cigarseq->locatable_seq;
  my $seq2 = $self->h_cigarseq->locatable_seq;
  
  #my $alignment = $self->get_simple_align;
  #my ($seq1, $seq2)  = $alignment->each_seq;
  
  my $seqStr1 = $seq1->seq();
  my $seqStr2 = $seq2->seq();
  
  my $label_len = length($seq1->id);
  if(length($seq2->id) > $label_len) { $label_len = length($seq2->id); }
  $label_len += 3;

  my $label1 = $seq1->id . sprintf(" %s ", $self->q_cigarseq->ori);
  for (my $x=$label_len - length($label1); $x>=0; $x--) { $label1 = ' ' . $label1; }
  my $label2 = "   ";
  for (my $x=$label_len - length($label2); $x>=0; $x--) { $label2 = ' ' . $label2; }
  my $label3 = $seq2->id . sprintf(" %s ", $self->h_cigarseq->ori);
  for (my $x=$label_len - length($label3); $x>=0; $x--) { $label3 = ' ' . $label3; }

  my $line2 = "";
  for(my $x=0; $x<length($seqStr1); $x++) {
    if(substr($seqStr1,$x,1) eq substr($seqStr2, $x,1)) { $line2.='|'; } else { $line2.=' '; }
  }

  my $offset=0;
  my $numLines = (length($seqStr1) / $aaPerLine);
  while($numLines>0) {
    printf("$label1 %s\n", substr($seqStr1,$offset,$aaPerLine));
    printf("$label2 %s\n", substr($line2,$offset,$aaPerLine));
    printf("$label3 %s\n", substr($seqStr2,$offset,$aaPerLine));
    print("\n");
    $offset+=$aaPerLine;
    $numLines--;
  }
}


sub get_subalignment {
  my $self = shift;
  my $cons_start = shift;
  my $cons_end = shift;
  
#print "cons $cons_start $cons_end\n";  
#print "query " . $self->q_cigarseq->start . "-" . $self->q_cigarseq->end . "\n";  
#print "hit " . $self->h_cigarseq->start . "-" . $self->h_cigarseq->end . "\n";  
#map the consensus coordinates down into the 'query' coordinate space
  my $query_start = $self->q_cigarseq->coord_consensus_2_seq($cons_start);
  my $query_end   = $self->q_cigarseq->coord_consensus_2_seq($cons_end);
  #printf("  query coordinates %d-%d\n", $query_start, $query_end);
  
  #map the consensus coordinates down into the 'hit' coordinate space
  my $hit_start = $self->h_cigarseq->coord_consensus_2_seq($cons_start);
  my $hit_end   = $self->h_cigarseq->coord_consensus_2_seq($cons_end);
  #printf("  hit coordinates %d-%d\n", $hit_start, $hit_end);
  if ($cons_start == 0) {
      unless (defined($query_start)) { $query_start = $self->q_cigarseq->start; }
      unless (defined($hit_start)) { $hit_start = $self->h_cigarseq->start; }
  }
  #print "query |$query_start| |$query_end| hit |$hit_start| |$hit_end|\n"; 

  #now use the alignment_string() method and the consensus coordinates to generate
  #subregions of consensus, this captures the sequence variation to generate the
  #new cigar line
  my $query_cons_seq = $self->q_cigarseq->alignment_string;
  $query_cons_seq = substr($query_cons_seq, $cons_start, $cons_end - $cons_start);

  my $hit_cons_seq = $self->h_cigarseq->alignment_string;
  $hit_cons_seq = substr($hit_cons_seq, $cons_start, $cons_end - $cons_start);
  
  #printf("query : %s\n", $query_cons_seq);
  #printf("hit   : %s\n", $hit_cons_seq);
  my $cigar = '';
  my $count=1;
  my $last_cigar_char = '';
  my $cigar_char = '';
  for(my $x=0; $x<length($query_cons_seq); $x++) {
    my $q_char = substr($query_cons_seq,$x,1);
    my $h_char = substr($hit_cons_seq,$x,1);
    if($q_char eq '-') { $cigar_char = 'D'; }
    elsif($h_char eq '-') { $cigar_char = 'I'; }
    else { $cigar_char = 'M'; }
    if($cigar_char eq $last_cigar_char) { 
      $count++; 
    } else {
      if($last_cigar_char) {
        $cigar .= $last_cigar_char;
        if($count > 1) { $cigar .= $count; } 
      }
      $last_cigar_char = $cigar_char;
      $count = 1;
    }
  }
  #push the last one on now
  if($last_cigar_char) {
    $cigar .= $last_cigar_char;
    if($count > 1) { $cigar .= $count; } 
  }
  #printf("cigar : %s\n", $cigar);
  
  #first make a perfect copy of alignment
  my $subalign = $self->copy;

  #reset the EngineeredSeq (is 'h_cigarseq') to focus on the B site
  $subalign->h_cigarseq->start($hit_start);
  $subalign->h_cigarseq->end($hit_end);

  #reset the SeqRead (ie q_cigarseq) to focus on the corresponding
  #(ie remapped) coordinates of the B site
  $subalign->q_cigarseq->start($query_start);
  $subalign->q_cigarseq->end($query_end);
  
  $subalign->cigar_line($cigar);
  
  return $subalign;
}


1;

