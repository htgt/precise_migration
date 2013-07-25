### TargetedTrap::IVSA::AlignFeatureLocTest
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
Vector Design and TRAP lims systems

=head1 CONTACT

  Contact Jessica Severin on implemetation/design detail: jessica@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::AlignFeatureLocTest;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::Design;
use TargetedTrap::IVSA::SeqRead;
use TargetedTrap::IVSA::VectorConstruct;
use TargetedTrap::IVSA::AlignFeature;

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# Class methods / functions
#################################################


sub show_map {
  print "\nR3F>-R3>--->---<R1R-<Z1-Z2>-R2R>---->----#######>#######---->----<LFR-<LR-LRR>------->---<R4-<R4R\n\n";
}


#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  $self->SUPER::init(@_);
  my %args = @_;
  
  if($args{'-alignment'}) { $self->alignment($args{'-alignment'}); }
  
  return $self;
}

sub alignment {
  my $self = shift;
  $self->{'_alignment'} = shift if @_;
  return $self->{'_alignment'};
}



#################################################
#
# original 12e12 analysis method
#
#################################################


sub test_genomic_region_loc {
  my $self = shift;

  my $hit = $self->alignment;
  
  #$hit->display_info;
  
  my $design = $hit->design;
  
  my $exon_strand = $design->exon_strand;  # +1 or -1
  
  #print "Design oligo position check: \n";

  my $exon_start  = 12000;
  my $exon_len    = ($design->region_chr_end - $design->region_chr_start +1) - (2*12000);
  my $exon_end    = $exon_start + $exon_len;
  
  #print "Exon start/end: $exon_start - $exon_end strand: $exon_strand length: $exon_len \n";

  my $oligo_id  = $hit->seqread->oligo_name;
  my $id        = $hit->seqread->trace_label;
  my $score     = $hit->cmatch . " " . $hit->{'is_best'};
  
  ########################
  my $hit_start = $hit->h_cigarseq->start;
  my $hit_end   = $hit->h_cigarseq->end;
  my $hit_ori   = $hit->q_cigarseq->ori; #either '-' or '+'

  #printf("  testing primer loc : %s %d-%d %s\n", $oligo_id, $hit_start, $hit_end, $hit_ori);

  #print $hit->{'raw'},"\n";
  
  #my $sig 	= get_trace_signal_average($hit->seqread->plate, $id);
  #y $lane 	= get_trace_lane($hit->seqread->plate, $id);
  #$id 		= "$id\t$sig/$lane";
  
  $hit->loc_status(0);  #initialize to 'failed'
  
  if ($oligo_id eq 'R3F'){ # upstream (fwd)
    if (($hit_start < $exon_start) and ($hit_ori eq '+')) {
      #print "  $id\toligo $oligo_id upstream location\t";
      #print "OK ($hit_end < $exon_start)";
      my $diff = $exon_start - $hit_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    } 
  }
  if ($oligo_id eq 'R3'){ # upstream (fwd)
    if (($hit_start < $exon_start) and ($hit_ori eq '+')) {
      #print "  $id\toligo $oligo_id upstream location\t";
      #print "OK ($hit_end < $exon_start)";
      my $diff = $exon_start - $hit_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    } 
  }
  if ($oligo_id eq 'R1R'){ # upstream (rev)
    if (($hit_end < $exon_start) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id upstream location\t";
      #print "OK ($hit_end < $exon_start)";
      my $diff = $exon_start - $hit_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'Z1'){ # upstream (rev)
    if (($hit_end < $exon_start) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_start > $exon_end)";
      my $diff = $exon_start - $hit_start +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'Z2'){ # upstream (fwd)
    if (($hit_start < $exon_start) and ($hit_ori eq '+')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_start > $exon_end)";
      my $diff = $exon_start - $hit_start +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'R2R'){ # upstream (fwd)
    if (($hit_start < $exon_start) and ($hit_ori eq '+')) {
      #print "  $id\toligo $oligo_id upstream  location\t";
      #print "OK ($hit_start < $exon_start)";
      my $diff = $exon_start - $hit_start +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  
  if ($oligo_id eq 'LFR'){ # downstream (rev)
    if (($hit_end > $exon_end) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_end > $exon_end)";
      my $diff = $hit_end - $exon_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'LR'){ # downstream (rev)
    if (($hit_end > $exon_end) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_end > $exon_end)";
      my $diff = $hit_end - $exon_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'LRR'){ # downstream (fwd)
    if (($hit_start > $exon_end) and ($hit_ori eq '+')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_start > $exon_end)";
      my $diff = $hit_start - $exon_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'R4'){ # downstream (rev)
    if (($hit_end > $exon_end) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_start > $exon_end)";
      my $diff = $hit_start - $exon_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  if ($oligo_id eq 'R4R'){ # downstream (rev)
    if (($hit_end > $exon_end) and ($hit_ori eq '-')) {
      #print "  $id\toligo $oligo_id downstream location\t";
      #print "OK ($hit_start > $exon_end)";
      my $diff = $hit_start - $exon_end +1;
      #print "\t$diff\t[score: $score]";
      #print "\n";
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }

  #post gateway specific primers  
  if ($oligo_id eq 'L3'){ # upstream (fwd)
    if (($hit_start < $exon_start) and ($hit_ori eq '+')) {
      my $diff = $exon_start - $hit_end +1;
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    } 
  }
  if ($oligo_id eq 'UNK'){ # inside Exon (fwd)
    if (($hit_ori eq '+') and ($hit_start >= $exon_start-1150) and ($hit_start <= $exon_end+1170)) {
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $hit_start - $exon_start +1;
    }
  }
  if ($oligo_id eq 'FCHK'){ # upstream (rev)
    if (($hit_ori eq '-') and ($hit_end < $exon_start)) {
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $exon_start - $hit_end +1;
    } 
  }
  if ($oligo_id eq 'NF'){ # upstream (fwd)
    if (($hit_ori eq '+') and ($hit_start < $exon_start)) {
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $exon_start - $hit_start +1;
    }
  }
  if ($oligo_id eq 'L4'){ # downstream (rev)
    if (($hit_end > $exon_end) and ($hit_ori eq '-')) {
      my $diff = $hit_start - $exon_end +1;
      $hit->loc_status(1);
      $hit->{'loc_dist'} = $diff;
    }
  }
  
  #printf("  loc_status = %d\n", $hit->loc_status); 
}

#################################################

sub test_synthetic_construct_loc {
  my $self = shift;
  my $cre_applied = shift;

  my $hit = $self->alignment;
  $hit->loc_status('locfail');

  my $seqread = $hit->seqread;
  my $engseq  = $hit->engineered_seq;
  my $design = $engseq->design;
  
  my $five_arm_feat  = $engseq->find_seqfeature('5 arm');
  my $three_arm_feat = $engseq->find_seqfeature('3 arm');
  my $target_feat    = $engseq->find_seqfeature('target region');
  
  unless($five_arm_feat and $three_arm_feat and ($cre_applied or $design->is_deletion or $design->is_insertion or $target_feat)) {
    printf("ERROR in SyntheticConstruct annotation!!!\n");
    return;
  }
  
  my $oligo_id  = $hit->seqread->oligo_name;

  my $overlap=0;
  if($overlap = test_feat_overlap($hit, $five_arm_feat)) {
    $hit->loc_status('fail_5arm_' . $overlap);
  } elsif($overlap = test_feat_overlap($hit, $three_arm_feat)) {
    $hit->loc_status('fail_3arm_' . $overlap);
  } elsif($target_feat and $overlap = test_feat_overlap($hit, $target_feat)) {
    $hit->loc_status('fail_target_'. $overlap);
  } else { 
    #all primers except FSI, BSO, XMI, PGO, FCHK or IRES need to have a minimum amount of genomic arm
    if($oligo_id eq 'FCHK') { 
      $hit->loc_status('FCHK_vector');
    }elsif($oligo_id eq 'IRES') { 
      $hit->loc_status('IRES_vector');
    }elsif(
      $oligo_id eq 'FSI' or $oligo_id eq 'BSO' or $oligo_id eq 'XMI' or $oligo_id eq 'PGO'
       or ($cre_applied and $oligo_id eq 'LR')
    ) { 
      $hit->loc_status('only_vector');
    } else {
      $hit->loc_status('only_vector');
      return; #need to have a minimum amount of genomic arm
    }
  }  

  if ($oligo_id eq 'R3F') { $self->test_R3F; } 
  if ($oligo_id eq 'R3') { $self->test_R3; } 
  if ($oligo_id eq 'R1R') { $self->test_R1R; } 
  if ($oligo_id eq 'Z1') { $self->test_Z1; } 
  if ($oligo_id eq 'Z2') { $self->test_Z2; } 
  if ($oligo_id eq 'R2R') { $self->test_R2R; } 
  if ($oligo_id eq 'UNK') { $self->test_UNK; } 
  if ($oligo_id eq 'LF') { $self->test_LF; } 
  if ($oligo_id eq 'LFR') { $self->test_LFR; } 
  if ($oligo_id eq 'LR') { $self->test_LR($cre_applied); } 
  if ($oligo_id eq 'LRR') { $self->test_LRR; } 
  if ($oligo_id eq 'R4') { $self->test_R4; }   
  if ($oligo_id eq 'SP6') { $self->test_SP6; }   
  if ($oligo_id eq 'SP6B') { $self->test_SP6B; }   
  if ($oligo_id eq 'R4R') { $self->test_R4R; }   
  if ($oligo_id eq 'G3') { $self->test_G3; }   
  if ($oligo_id eq 'G5') { $self->test_G5; }   

  if ($oligo_id eq 'IFRT') { $self->test_IFRT; }   
  if ($oligo_id eq 'L1') { $self->test_L1; }   
  if ($oligo_id eq 'L3') { $self->test_L3; }   
  if ($oligo_id eq 'L4') { $self->test_L4; }   
  if ($oligo_id eq 'NF') { $self->test_NF; }   
  if ($oligo_id eq 'PNF') { $self->test_NF; }   
  if ($oligo_id eq 'IRES') { $self->test_IRES; }   
  
  if ($oligo_id eq 'FCHK') { $self->test_FCHK;}
  #  if($engseq->cassette_formula =~ /l1l2_st/) {
  #    $self->test_FCHK_st; 
  #  } elsif($engseq->cassette_formula =~ /l1l2_gt/) {
  #    $self->test_FCHK_gt; 
  #  }
  #  $self->fchk_subalign_test();
  #}
  
  if ($oligo_id eq 'FSI') { $self->test_FSI; }   
  if ($oligo_id eq 'PGO') { $self->test_PGO; }   
  if ($oligo_id eq 'BSO') { $self->test_BSO; }   
  if ($oligo_id eq 'XMI') { $self->test_XMI; }   

  if ($oligo_id eq 'LREGFP5') { $self->test_LREGFP5; }
  
  if ($oligo_id eq 'LRBIOT5') { $self->test_LRBIOT5; }
  
  $self->bsite_subalign_test();
  
  if($seqread->contamination) {
    $hit->loc_status('read_contaminated');
  }

}


sub test_feat_overlap {
  my $hit = shift;
  my $feat = shift;
  
  my $hit_start = $hit->h_cigarseq->start;
  my $hit_end   = $hit->h_cigarseq->end;
  
  my $start = $hit_start;
  if($feat->start > $start) { $start = $feat->start; }
  my $end = $hit_end;
  if($feat->end < $end) { $end = $feat->end; }
  
  my $overlap = $end - $start;
  if($overlap < 0) { $overlap = 0; }
  if($overlap < 30) { $overlap = 0; } #new filter: minimum of 30 bases into genomic
  
  return $overlap;
}


#################################################
#
# individual tests on a per primer basis, 
# provides very fine grained analysis
#
#################################################


sub test_R3F {
  my $self = shift;
  my $hit = $self->alignment;
  
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); } 
  elsif($hit->has_feature('Gateway R3') and
        $hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_R3 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_Z1 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('Gateway R1') and
        $hit->has_feature('B1') and
        $hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_R1R {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_Z2 {
  my $self = shift;
  my $hit = $self->alignment;
  my $design = $hit->engineered_seq->design;
  
  my $required_genomic_region = 'target region';
  if($design->is_deletion){
    $required_genomic_region = '3 arm';
  }
  
  if($hit->q_cigarseq->ori ne '+') {
    $hit->loc_status('ori_fail');
  } elsif (
    $hit->has_feature('Gateway R2') and
    $hit->has_feature('B2') and
    $hit->has_feature($required_genomic_region)
  ){
    $hit->loc_status('ok');
  } 
}

sub test_R2R {
  my $self = shift;
  my $hit = $self->alignment;
  my $design = $hit->engineered_seq->design;
  
  if($hit->q_cigarseq->ori ne '+'){
     $hit->loc_status('ori_fail');
  }
  elsif(
     ($design->is_insertion || $design->is_deletion) &&
     $hit->has_feature('3 arm'))
  {
     $hit->loc_status('ok');
  }
  elsif($hit->has_feature('target region')) {
     $hit->loc_status('ok');
  } 
#  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
#  elsif(($hit->has_feature('loxP') or $hit->has_feature('loxP site'))) { $hit->loc_status('ok'); } 
}

sub test_UNK {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('target region') and
        ($hit->has_feature('loxP') or $hit->has_feature('loxP site'))) { $hit->loc_status('ok'); } 
}

sub test_LF {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_LFR {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('target region')) { $hit->loc_status('ok'); } 
}

sub test_LR {
  my $self = shift;
  my $cre_applied = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') {
    $hit->loc_status('ori_fail');
  } else{
    if(!$cre_applied){
      if($hit->has_feature('target region')) {
        $hit->loc_status('ok');
      }
    }else{
      if(
         (!$hit->has_feature('target region')) &&
         ($hit->has_feature('SV40pA')||$hit->has_feature('SV40 pA')) #This pA site gets hit by the read before the neo
      ){
        $hit->loc_status('ok');
      }
    }
  }
}

sub test_LRR {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_R4R {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('Gateway R4') and
        $hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_SP6 {
  my $self = shift;
  my $hit = $self->alignment;
  #The orientation of this primer is now -, since it runs from the backbone into the 3-arm
  #In this context the primer is used to check the 3-arm
  #Note - the primer is the same sequence as the SP6B primer (just a different context)
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_SP6B {
  my $self = shift;
  my $hit = $self->alignment;
  #The orientation of this primer is now +, since it runs from cassette to 3-arm.
  #In this context the primer is used to check the barcode in a second-allele targeting
  #Note - the primer is the same sequence as the SP6 primer (just a different context)
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_R4 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

############################################

sub test_IFRT {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') {
    $hit->loc_status('ori_fail');
  } elsif ( $hit->has_feature('En2 intron1') or $hit->has_feature('en-2 intron') or $hit->has_feature('SV40 pA') or $hit->has_feature('ECMV IRES')) {
    $hit->loc_status('cassette_fail');
  }elsif( $hit->has_feature('5 arm') ) {
    $hit->loc_status('ok');
  } 
}

sub test_L1 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif(#($hit->has_feature('Frt') or $hit->has_feature('Frt site') or $hit->has_feature('FRT site') or $hit->has_feature('FRT')) and
        #($hit->has_feature('En2 intron1') or $hit->has_feature('en-2 intron')) and
        #$hit->has_feature('B1') and
        $hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_L3 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('B3') and
        $hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_L4 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('B4') and
        $hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

sub test_NF {
  my $self = shift;
  my $hit = $self->alignment;
  my $design = $hit->engineered_seq->design;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif( ( ($design->is_deletion || $design->is_insertion )?  $hit->has_feature('3 arm') : $hit->has_feature('target region') ) #and
        #($hit->has_feature('Frt') or $hit->has_feature('Frt site') or $hit->has_feature('FRT site') or $hit->has_feature('FRT')) and
        #($hit->has_feature('loxP') or $hit->has_feature('loxP site')) and
        #$hit->has_feature('B2')
        ) { $hit->loc_status('ok'); } 
}


sub test_FCHK_gt {
  my $self = shift;
  my $hit = $self->alignment;
#  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); } # for old plates only!
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif(($hit->has_feature('En2_exon2') or hit->has_feature('En2 exon'))and
        $hit->has_feature('T2A')) { $hit->loc_status('ok'); } 
  elsif(!($hit->has_feature('En2_exon2') or hit->has_feature('En2 exon'))
        and !$hit->has_feature('T2A')
        and $hit->has_feature('bgal')) {
    $hit->loc_status('FCHK_gt/st_switch?');
  }
  elsif(($hit->has_feature('En2_exon2') or hit->has_feature('En2 exon'))
        and !$hit->has_feature('T2A')
        and !$hit->has_feature('bgal')) {
    $hit->loc_status('FCHK_gt/st_switch(2)?');
  }
}

sub test_FCHK_st {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('En2_exon2')
        and $hit->has_feature('rat CD4 fragment')
        #and $hit->has_feature('CD4 TM domain')
        ) { $hit->loc_status('ok'); } 
  elsif(!$hit->has_feature('rat CD4 fragment')
        and $hit->has_feature('bgal')) {
    $hit->loc_status('FCHK_gt/st_switch?');
  }
}

sub test_FCHK {#horrid cludge check FCHK reads for correct cassette....
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  else{
    my $seqread = $hit->seqread->sequence->seq;
    my $f = $hit->engineered_seq->cassette_formula;
    my @h = _test_FCHK_hits($seqread);
    if(@h>1){
      $hit->loc_status('ambiguous_cassette');
    }elsif(@h==0){
      $hit->loc_status('no_cassette_match');
    }else{
      my($h)=@h; $h=substr($h,0,3);
      my $c;
      if($f =~ /L1L2_(\w\w\d)_/i){
        $c = lc($1);
      }else{
          die "Synthetic vector ".$hit->engineered_seq->unique_tag." missing l1l2 cassette. Formula: $f\n";
      }
        
      my $t = {
        'Bact_P' => 'gpr',
        'Pgk_P'  => 'gpr',
        'Pgk_PM' => 'gpr'
      }->{$c}; 
      
      $c=$t if $t;
      if($c eq $h){
        $hit->loc_status('ok');
      }else{
        $hit->loc_status("wrong_cassette_$h");
      }
    } 
  }
}

sub _test_FCHK_hits{
    my $seq = shift;
    my $sar = ref $_[0] eq "ARRAY" ? shift : ["i I0 D0 S05%"];#case insensitive, no insertions, no deletions, 1 in 20 mismatch
    use String::Approx 'amatch';
    
    my %chkseq_for_barcode_second_allele = (
      gt0 => "AAACCAAAGAAGAAGAAC"."GCAGATCTCC"."TGTTGCATTGCACAAGAT",
      gt1 => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCGCAGATCTCC"."TGTTGCATTGCACAAGAT",
      gt2 => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCTCC"."TGTTGCATTGCACAAGAT"
    );


#   These are the seqs for cassettes with the Neo next to the T2A - they have the lacZ removed 
    my %chkseq_for_del_lacZ = (
      gt0 => "AAACCAAAGAAGAAGAAC"."GCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCT"."ATTGAACAAGATGGATTGC",
      gt1 => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCGCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCT"."ATTGAACAAGATGGATTGC",
      gt2 => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCT"."ATTGAACAAGATGGATTGC"
    );
    
#   These are the seqs for cassettes with the lacZ next to the T2A (the standard 'old' cassettes)
    my %chkseq=(
     gt0  => "AAACCAAAGAAGAAGAAC"."GCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCTGG".                            "GATCTGGACTCTAGAGGA",
     gt1  => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCGCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCTGG".              "GATCTGGACTCTAGAGGA",
     gt2  => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCTCCGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCTGG".                     "GATCTGGACTCTAGAGGA",
     gtkm => "AAACCAAAGAAGAAGAAC"."GCAGATCATAACTGACTAGGAGGCCACCATGGAGATCTGAGGGCAGAGGAAGTCTTCTAACATGCGGTGACGTGGAGGAGAATCCCGGCCCTGG"."GATCTGGACTCTAGAGGA",
     gtks => "AAACCAAAGAAGAAGAAC"."GCAGATCATAACTGACTAGGAGGCCACCATGGA".                                                             "GATCTGGACTCTAGAGGA",
     st0  => "AAACCAAAGAAGAAGAAC"."GCAGATCT".              "GCGGGCTGCAGGGAGAGT",
     st1  => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCGCAGATCT"."GCGGGCTGCAGGGAGAGT",
     st2  => "AAACCAAAGAAGAAGAAC"."GCAGATCGCAGATCT".       "GCGGGCTGCAGGGAGAGT",
     gpr  => "AAACCAAAGAAGAAGAAC"."CCTAACAAAGAGGACAAGCGGCCTCGCACAGCCTTCACTGCTGAGCAGCTCCAGAGGCTC",
    );
    
    my @h;
    
    # Rather than root around for cassette information to work out which seq to use, try against all: it's impossible to
    # match to both the lacZ and del_lacZ sequences - since we need at most 1/20 mismatch, with no indels.
    while (my($k,$p)= each %chkseq){
      push @h,$k if amatch($p,$sar,$seq); 
    }
    
    while (my($k,$p)= each %chkseq_for_del_lacZ){
      push @h,$k if amatch($p,$sar,$seq); 
    }
    
    while (my($k,$p)= each %chkseq_for_barcode_second_allele){
      push @h,$k if amatch($p,$sar,$seq); 
    }
    
    return @h
}

sub test_IRES {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('ECMV IRES')) { $hit->loc_status('ok'); } 
  else{ $hit->loc_status('fail'); }
}

############################################
# allele specific
############################################

sub test_G5 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('5 arm')) { $hit->loc_status('ok'); } 
}

sub test_G3 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif($hit->has_feature('3 arm')) { $hit->loc_status('ok'); } 
}

############################################


sub bsite_subalign_test {
  my $self = shift;
  my $hit = $self->alignment;
  
  my $feature_name;
  if($hit->seqread->oligo_name eq 'Z1')     { $feature_name = 'B1'; }
  elsif($hit->seqread->oligo_name eq 'Z2')  { $feature_name = 'B2'; }
  elsif($hit->seqread->oligo_name eq 'R3F') { $feature_name = 'B3'; }
  elsif($hit->seqread->oligo_name eq 'R4R') { $feature_name = 'B4'; }
  else {  #nothing to do for the other primers 
    return; 
  }
  
  #printf("==== test_subalign ====\n");
  my $synthvec = $hit->engineered_seq;
  my $bsite_sf = $synthvec->find_seqfeature($feature_name);
  unless(defined($bsite_sf)) { 
    #printf("feature %s not available in synthetic vector\n", $feature_name);
    return;
  }  
  #$synthvec->display_seqfeature($bsite_sf);
  
  #first map the SeqFeature coordinates from the SyntheticVector coordinate space
  #up to the virtual consensus coordinate space
  #seqfeatures are 1 referenced and start..end inclusive (length = end - start + 1)
  #cigarseq coordinates are 0 referenced start to start..end exclusive (length = end - start) 
  
  my $cons_start = $hit->h_cigarseq->coord_seq_2_consensus($bsite_sf->start - 1);
  my $cons_end   = $hit->h_cigarseq->coord_seq_2_consensus($bsite_sf->end);

  unless(defined($cons_start) and defined($cons_end)) { 
    #printf("feature %s not within alignment\n", $feature_name);
    return; 
  }
  #printf("  consensus coordinates %d-%d\n", $cons_start, $cons_end);
  
  my $subalign = $hit->get_subalignment($cons_start, $cons_end);

  #$hit->print_pair_format_alignment(112);

  #$subalign->display_info;
  if($subalign->percent_identity != 100.0) {
    $hit->extra_info('bsite_mut');
    $subalign->print_pair_format_alignment(112);
  }
}


sub fchk_subalign_test {
  my $self = shift;
  my $hit = $self->alignment;
  
  return unless($hit->seqread->oligo_name eq 'FCHK');
  
  #printf("==== fchk_subalign_test ====\n");
  my $synthvec = $hit->engineered_seq;
  my $fchk_region_sf = $synthvec->find_seqfeature('En2_exon2');
  $fchk_region_sf ||= $synthvec->find_seqfeature('En2 exon');
  unless(defined($fchk_region_sf)) { 
    #printf("feature %s not available in synthetic vector\n", $feature_name);
    return;
  }  
  #$synthvec->display_seqfeature($bsite_sf);
  
  #first map the SeqFeature coordinates from the SyntheticVector coordinate space
  #up to the virtual consensus coordinate space
  #seqfeatures are 1 referenced and start..end inclusive (length = end - start + 1)
  #cigarseq coordinates are 0 referenced start to start..end exclusive (length = end - start) 
  
  my $cons_start = $hit->h_cigarseq->coord_seq_2_consensus($fchk_region_sf->start - 1);
  my $cons_end   = $hit->h_cigarseq->coord_seq_2_consensus($fchk_region_sf->end + 5);

  unless(defined($cons_start) and defined($cons_end)) { 
#    $hit->extra_info('too_short');
    $hit->loc_status('FCHK_too_short');
    #printf("feature not within alignment\n");
    return; 
  }
  #printf("  consensus coordinates %d-%d\n", $cons_start, $cons_end);
  
  my $subalign = $hit->get_subalignment($cons_start, $cons_end);  
  #$hit->print_pair_format_alignment(112);

  #$subalign->display_info;
  if($subalign->percent_identity != 100.0) {
    #$hit->extra_info('fchk_mut');
    $hit->loc_status('FCHK_phase_error');
    $subalign->print_pair_format_alignment(112);
  }
}

################################################################
# 4th recombineering checks - for intermediate and post-gateway
################################################################

sub test_FSI {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif(
    $hit->has_feature('PGK')
    || $hit->has_feature('DTA')
  ) { $hit->loc_status('ok'); } 
}

sub test_PGO {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif(
    $hit->has_feature('3 arm')
    ||$hit->has_feature('expected_PGO')
  ) { $hit->loc_status('ok'); } 
}

sub test_BSO {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '+') { $hit->loc_status('ori_fail'); }
  elsif(
    $hit->has_feature('5 arm') #unlikely as it is too far away
    ||$hit->has_feature('expected_BSO')
  ) { $hit->loc_status('ok'); } 
}

sub test_XMI {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') { $hit->loc_status('ori_fail'); }
  elsif(
    $hit->has_feature('Bsd ORF')
  ) { $hit->loc_status('ok'); } 
}

# test for eutracc vector


sub test_LREGFP5 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') {
    $hit->loc_status('ori_fail');
  }elsif($hit->has_feature('5 arm')) {
    $hit->loc_status('ok');
  }
}

sub test_LRBIOT5 {
  my $self = shift;
  my $hit = $self->alignment;
  if($hit->q_cigarseq->ori ne '-') {
    $hit->loc_status('ori_fail');
  }elsif($hit->has_feature('5 arm')) {
    $hit->loc_status('ok');
  }
}

1;

