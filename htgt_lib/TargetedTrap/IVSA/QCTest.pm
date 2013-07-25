### TargetedTrap::IVSA::QCTest
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

package TargetedTrap::IVSA::QCTest;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::QCTestRun;
use TargetedTrap::IVSA::QCTestResult;
use TargetedTrap::IVSA::QCTestPrimer;
use TargetedTrap::IVSA::Design;
use TargetedTrap::IVSA::ConstructClone;

use TargetedTrap::DBObject;
our @ISA = qw(TargetedTrap::DBObject);

#################################################
# This is hard coded primers, 
# The script check_vector_mapping_v3, from v3.2.39 , doesn't use this method
 
sub get_calc_primers {
  my $class = shift;
  my $qctest_result = shift; 

  my $primers = [];
  if($qctest_result->post_gateway) {
    $primers = [
        #'L3',    # for oldish stuff
        'R3',   # new
        'L1',  # dont use for some of the earliest plates...
        'FCHK',
        'IRES',
        'NF',
        'PNF',
        #'UNK', #old
        #'LF',  #old
        #'LFR', #old
        'LR',
        'LRR',
        #'L4'    # for oldish stuff
        'R4',   # new
        'SP6',   # new
        'PGO',
        'FSI',
        'XMI',
        'BSO',
        ];
  } 
  elsif($qctest_result->allele) {
    $primers = [
        #'GF'
        'G5',
        'R1R', 
        'R2R',
        'LF',
        'LR',
        'LRR',
        'G3'
        #'GR',

############# got to deal with the gene specific primers ######################

        ];
  } else {
    $primers = [
        'R3F',
        #'R3',  #old
        #'R1R', #old
        'Z1',
        'Z2',
        #'R2R', #old
        #'UNK', #old
        #'LF',  #old
        #'LFR', #old
        'LRR',
        'LR',
        #'R4', #old
        'R4R',
        'PGO',
        'FSI',
        'XMI',
        'BSO',
        ];
  }
  #$class->{'att_primers'}= ['R3F', 'Z1', 'Z2', 'R4R'];
  return $primers;
}

#######################################################################

sub all_hits {
  my $class = shift;
  my $qctest_result = shift; 
  my $primer = shift; #optional primer filter

  my $clone = $qctest_result->construct;
  my $eng_seq = $qctest_result->engineered_seq;

  my @hits;
  foreach my $seqread (@{$clone->seqreads}) {
    next if(defined($primer) and ($primer ne $seqread->oligo_name));
    foreach my $hit (@{$seqread->hits}) {
      next unless(defined($hit->engineered_seq));
      next unless($eng_seq eq $hit->engineered_seq); #using the internal object pointer    
      push @hits, $hit;
    }
  }
  return \@hits;
}

sub best_hit {
  my $class = shift;
  my $qctest_result = shift; 
  my $primer = shift; #optional primer filter

  my $clone    = $qctest_result->construct;
  my $eng_seq  = $qctest_result->engineered_seq;
  my $minscore = $qctest_result->qctest_run->minscore;
  
  my $best_hit = undef;
  foreach my $hit (@{$class->all_hits($qctest_result, $primer)}) {
    if(!defined($best_hit)) { 
      #any hit is better than none
      $best_hit = $hit; 
    }
    if($hit->map_score >= $minscore) {
      #if 'strong' hits exist then pick strongest
      if($best_hit->map_score < $minscore) { 
        #any 'strong' hit is better than any 'weak'
        $best_hit = $hit; 
      }
      #hmm maybe this should be an elsif.  map_score and cmatch should 
      #run in parallel, but this logic may not behave as we think.
      if($hit->cmatch > $best_hit->cmatch) {
        #otherwise maximize the cmatch score        
        $best_hit = $hit;
      }
    }
    if($best_hit->map_score < $minscore) {
      #if the best hit so far is 'weak' then use special logic
      if(($best_hit->loc_status ne 'ok') and ($hit->loc_status eq 'ok')) {
        #location correct hits are 'better' than location incorrect hits
        $best_hit = $hit; 
      }
      if(($best_hit->loc_status eq $hit->loc_status) and ($hit->cmatch > $best_hit->cmatch)) { 
        #for hits with the same location_status, higher cmatch is 'better'
        $best_hit = $hit;
      }
    }
  }
  return $best_hit;    
}


sub best_valid_hit {
  my $class = shift;
  my $qctest_result = shift; 
  my $primer = shift; #optional primer filter
  
  my $best_hit = undef;
  foreach my $hit (@{$class->all_hits($qctest_result, $primer)}) {
    next unless($hit->loc_status eq 'ok'); #must have correct location
    next unless($qctest_result->allele or $hit->seqread->seq_length >= 100 or $hit->seqread->oligo_name eq 'FCHK'); #must have a minimum QL/QR readlength of 100 bases unless this is allele/EPD QC, or a FCHK test
    next unless($hit->map_score >= $qctest_result->qctest_run->minscore); #must have minimum map_score
    if(!defined($best_hit)) { $best_hit = $hit; }
    if($hit->cmatch > $best_hit->cmatch) { $best_hit = $hit;}
  }
  return $best_hit;    
}


#######################################################################

sub calc {
  my $class = shift;
  my $qctest_result = shift; 
  
  return if($qctest_result->{'calc_ok'});
  
  $qctest_result->{'primer_test_array'} = [];
  $qctest_result->{'calc_ok'} = 1;
  my $KAN_in_LR = undef;
  my $sum_score = 0;    
  
  # get the primers from $qctest_result->construct rather than get_calc_primers, by wy1 March 3, 09
  my $available_primers = $qctest_result->construct->known_primers();
  
 # foreach my $primer (@{$class->get_calc_primers($qctest_result)}) {
   
  foreach my $primer (@{$available_primers}) {
    my $valid_hit = $class->best_valid_hit($qctest_result, $primer);
    my $other_hit = $class->best_hit($qctest_result, $primer);
    my $seqread   = $qctest_result->construct->best_seqread_for_primer($primer);

    my $summary = new TargetedTrap::IVSA::QCTestPrimer;
    $summary->is_valid(0);
    $summary->primer($primer);
    $summary->qctest($qctest_result);
    
    if($valid_hit) {
      $sum_score += $valid_hit->cmatch;
      my $status = 'valid';
      $status = 'weak_read' if $valid_hit->seqread->seq_length < 100 ;
      if($valid_hit->extra_info) { $status .= sprintf("(%s)", $valid_hit->extra_info); } 
      $summary->status($status);
      $summary->alignment($valid_hit);
      $summary->is_valid(1);  #default is set to (0) so this is the only place we need to set it. 
    } elsif($other_hit) {
      my $status = '';
      $summary->alignment($other_hit);
      if($other_hit->loc_status eq 'ok') {
        if($other_hit->seqread->seq_length < 100) {
          $status = 'weak_read';
        } else {
          $status = 'weak_hit';
        }
        if($other_hit->extra_info) { $status .= sprintf("(%s)", $other_hit->extra_info); } 
        $summary->status($status);
      } else {
        my $status = $other_hit->loc_status;
        if($other_hit->extra_info) { $status .= sprintf("(%s)", $other_hit->extra_info); } 
        $summary->status($status);
      }
    } elsif($seqread) {
      $summary->status('no_hits');
      $summary->seqread($seqread);
    } else {
      $summary->status('no_reads'); 
    }
    push @{$qctest_result->{'primer_test_array'}}, $summary;
    
    if(defined($seqread) and ($primer eq 'LR') and ($seqread->contamination)) { 
      $KAN_in_LR = 1; 
      $summary->status('hit_in_KAN');
      $summary->is_valid(0); #need to override any previous state
    }
  }
  $qctest_result->{'sum_score'} = $sum_score;

  #redo logic to use the internal 'primer_summary' as the data
  if($qctest_result->post_gateway) {
#    $class->calc_postgate_passfail_only($qctest_result); # missing many primers (early plates 4,5,6 - L3,L4,NF, no LR and LRR)
#    $class->calc_postgate_passfail_only7_11($qctest_result); # missing many primers (early plates 7,8,10,11 - L3,L4,NF,LR and LRR)
#    $class->calc_postgate_passfail_1($qctest_result); # L3/4, no L1 primer (earlyish plates 7, 8, 11 - no good)
#    $class->calc_postgate_passfail_1a($qctest_result); # L3/4, no L1 primer, UNK in place of LR and LRR (early plates 4, 5)
#    $class->calc_postgate_passfail_2($qctest_result); # L3/4 
#    $class->calc_postgate_passfail_3($qctest_result); # R3/4 plate 19 onwards
    $class->calc_postgate_passfail_4($qctest_result); # dj3 cludge for promoters
  } elsif($qctest_result->allele) {
    if ($qctest_result->tponly){
      $class->calc_allele_tponly_passfail($qctest_result); # calc 3 arm pass/fail on LRR hitting target region....
    }elsif ($qctest_result->fponly){
       $class->calc_allele_fponly_passfail($qctest_result); # calc 5 arm pass/fail on R1R hitting target region....
    }elsif ($qctest_result->tronly){
      $class->calc_allele_tronly_passfail($qctest_result); # calc TR target region pass/fail on R2R hitting target region....
    }else{
      #$class->calc_allele_passfail($qctest_result); # R3/4 plate 19 onwards
      $class->calc_allele_passfail_3prime($qctest_result); # calc Qc based on 3' primers only
    }
  } else {
    $class->calc_postcre_passfail_v3($qctest_result);
#    $class->calc_postcre_passfail_v3_old_plates($qctest_result); # for plates 4,5 and 6 which have no LR primer
#    $class->calc_postcre_passfail($qctest_result);
  }
  
  ##########
  # add extra test for non allele
  # if non allele, & if there is toxin feature in synthetic vector, then do calc_toxin_passfail 
  if ( !$qctest_result->allele ) {
     # check if there is toxin feature  
     if ( $qctest_result->engineered_seq->find_seqfeature('expected_PGO') || $qctest_result->engineered_seq->find_seqfeature('expected_FSI') 
          || $qctest_result->engineered_seq->find_seqfeature('expected_BSO') || $qctest_result->engineered_seq->find_seqfeature('expected_XMI') 
         ) {
        $class->calc_toxin_passfail($qctest_result);
     }else {
        $qctest_result->toxin_pass('n/a');
     }
  }

  
  ##########


  #override pass/fail if KAN present
  if($KAN_in_LR) {
    $qctest_result->pass_status('fail_KAN');
  }
}


sub calc_postcre_passfail_v3 {
  #March 9, 2007: Patrick and Jessica [with Bill's blessing] new descriptive logic
  my $class = shift;
  my $qctest_result = shift; 

  my $design = $qctest_result->engineered_seq->design;
 
  my $R3F  = $class->best_valid_hit($qctest_result, 'R3F');
  my $Z1   = $class->best_valid_hit($qctest_result, 'Z1');
  my $Z2   = $class->best_valid_hit($qctest_result, 'Z2');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $R4R  = $class->best_valid_hit($qctest_result, 'R4R');

  my $pass = 'fail';

  if($R3F and $Z1 and $Z2 and $LR and $LRR and $R4R) { #perfect
    $pass = 'pass1';
  } elsif(($R3F and $LR and $LRR and $R4R) and ($Z1 or $Z2)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($Z1 and $Z2 and $LR and $LRR) and ($R3F or $R4R)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($R3F and $Z1 and $Z2 and $R4R) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($R3F or $R4R) and ($Z1 or $Z2)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($R3F or $R4R) and ($Z1 or $Z2)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($R3F or $R4R) and ($Z1 or $Z2)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  }elsif( ($Z1 or $Z2) and $LR ){ 
      $pass = 'pass4.3';
  } elsif(($LR and $LRR and $R3F and $R4R) and (!defined($Z1) and !defined($Z2))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $Z1 and $Z2) and (!defined($R3F) and !defined($R4R))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($R3F and $R4R and $Z1 and $Z2) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and $Z2 and $R4R and !defined($Z1) and !defined($R3F))) {
    $pass = '5arm_warn';
  } elsif(($R3F and $Z1 and $Z2 and !defined($LR) and !defined($LRR) and !defined($R4R))) {
    $pass = '3arm_warn';
  } elsif($design->is_deletion and ($Z1 and $Z2)){
    $pass = 'pass4.3';
  }
  
  $qctest_result->pass_status($pass);
  if($pass ne 'fail') { $qctest_result->is_valid(1); }
  if($pass eq 'pass1') { $qctest_result->is_perfect(1); }

  return $pass  
}

sub calc_postcre_passfail_v3_old_plates {
  #March 9, 2007: Patrick and Jessica [with Bill's blessing] new descriptive logic
  # modified from the real v3 method by allowing LFR in place of LR 
  # - necessary for plates 4, 5 and 6 (PC00001, PC00002, PC00003) where the LR primer wasn't used

  my $class = shift;
  my $qctest_result = shift; 

  my $R3F  = $class->best_valid_hit($qctest_result, 'R3F');
  my $Z1   = $class->best_valid_hit($qctest_result, 'Z1');
  my $Z2   = $class->best_valid_hit($qctest_result, 'Z2');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $R4R  = $class->best_valid_hit($qctest_result, 'R4R');

  my $pass = 'fail';

  if($R3F and $Z1 and $Z2 and ($LR or $LFR) and $LRR and $R4R) { #perfect
    $pass = 'pass1';
  } elsif(($R3F and ($LR or $LFR) and $LRR and $R4R) and ($Z1 or $Z2)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($Z1 and $Z2 and ($LR or $LFR) and $LRR) and ($R3F or $R4R)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($R3F and $Z1 and $Z2 and $R4R) and (($LR or $LFR) or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif((($LR or $LFR) and $LRR) and ($R3F or $R4R) and ($Z1 or $Z2)) { #2 broken primers
    $pass = 'pass3';
  } elsif((($LR or $LFR) and !defined($LRR)) and ($R3F or $R4R) and ($Z1 or $Z2)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined(($LR or $LFR)) and $LRR) and ($R3F or $R4R) and ($Z1 or $Z2)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif((($LR or $LFR) and $LRR and $R3F and $R4R) and (!defined($Z1) and !defined($Z2))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif ((($LR or $LFR) and $LRR and $Z1 and $Z2) and (!defined($R3F) and !defined($R4R))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($R3F and $R4R and $Z1 and $Z2) and (!defined(($LR or $LFR)) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif((($LR or $LFR) and $LRR and $Z2 and $R4R and !defined($Z1) and !defined($R3F))) {
    $pass = '5arm_warn';
  } elsif(($R3F and $Z1 and $Z2 and !defined(($LR or $LFR)) and !defined($LRR) and !defined($R4R))) {
    $pass = '3arm_warn';
  }
  
  $qctest_result->pass_status($pass);
  if($pass ne 'fail') { $qctest_result->is_valid(1); }
  if($pass eq 'pass1') { $qctest_result->is_perfect(1); }

  return $pass  
}

sub calc_postcre_passfail {
  #does this clone<=>design pairing pass the postcre pass/fail analysis
  my $class = shift;
  my $qctest_result = shift; 
  
  my $pass = 'fail';
  
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $R4   = $class->best_valid_hit($qctest_result, 'R4');
  my $R4R  = $class->best_valid_hit($qctest_result, 'R4R');
  my $R3   = $class->best_valid_hit($qctest_result, 'R3');
  my $R3F  = $class->best_valid_hit($qctest_result, 'R3F');
  my $R1R  = $class->best_valid_hit($qctest_result, 'R1R');
  my $Z1   = $class->best_valid_hit($qctest_result, 'Z1');
  my $R2R  = $class->best_valid_hit($qctest_result, 'R2R');
  my $Z2   = $class->best_valid_hit($qctest_result, 'Z2');

  my $site_pass_count = 0;
  if($R3F or $R3) { $site_pass_count++; }
  if($R1R or $Z1) { $site_pass_count++; }
  if($Z2 or $R2R) { $site_pass_count++; }
  if($R4 or $R4R) { $site_pass_count++; }


  if(($LFR or $LRR or $LR) and
     ($R3F or $R3 or $R4 or $R4R) and
     ($R1R or $Z1 or $Z2 or $R2R)) { $pass = 'pass3'; }

  if(($LFR or $LRR or $LR) and ($site_pass_count>=3)) { $pass = 'pass2'; }

  if(($LRR) and ($LFR or $LR) and ($site_pass_count>=4)) { $pass = 'pass1'; }

  $qctest_result->pass_status($pass);
  if($pass ne 'fail') { $qctest_result->is_valid(1); }
  if($pass eq 'pass1') { $qctest_result->is_perfect(1); }

  return $pass  
}


sub calc_postgate_passfail_only7_11 {
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR   = $class->best_valid_hit($qctest_result, 'LRR');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if(($L3 || $L4) and ($NF || $LRR) and ($LR || $LRR)) { # perfect
#  if($L3 and $NF and $L4) { # perfect
    $pass = 'pass';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass;  
}

sub calc_postgate_passfail_only {
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($L3 and $NF and $L4) { # perfect
#  if($L3 and $NF and $L4) { # perfect
    $pass = 'pass';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass;  
}

sub calc_postgate_passfail {
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($L3 and $L1 and $NF and $LR and $LRR and $L4) { #perfect
    $pass = 'pass1';
  } elsif(($L3 and $LR and $LRR and $L4) and ($L1 or $NF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($L1 and $NF and $LR and $LRR) and ($L3 or $L4)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($L3 and $L1 and $NF and $L4) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR and $LRR and $L3 and $L4) and (!defined($L1) and !defined($NF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $L1 and $NF) and (!defined($L3) and !defined($L4))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($L3 and $L4 and $L1 and $NF) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and $NF and $L4 and !defined($L1) and !defined($L3))) {
    $pass = 'warn_5arm_';
  } elsif(($L3 and $L1 and $NF and !defined($LR) and !defined($LRR) and !defined($L4))) {
    $pass = 'warn_3arm_';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1a') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}



sub calc_postgate_passfail_1 { # no L1 (plates 7_A, 7_B, 8)
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($L3 and $NF and $LR and $LRR and $L4) { #perfect
    $pass = 'pass1';
  } elsif(($L3 and $LR and $LRR and $L4) and ($L1 or $NF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($NF and $LR and $LRR) and ($L3 or $L4)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($L3 and $NF and $L4) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR and $LRR and $L3 and $L4) and (!defined($L1) and !defined($NF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $NF) and (!defined($L3) and !defined($L4))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($L3 and $L4 and $NF) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and $NF and $L4 and !defined($L1) and !defined($L3))) {
    $pass = 'warn_5arm_';
  } elsif(($L3 and $NF and !defined($LR) and !defined($LRR) and !defined($L4))) {
    $pass = 'warn_3arm_';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1a') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_postgate_passfail_1a { # , no L1, UNK in place of LRR (plates 4, 5)
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($L3 and $NF and $LR and $UNK and $L4) { #perfect
    $pass = 'pass1';
  } elsif(($L3 and $LR and $UNK and $L4) and ($L1 or $NF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($NF and $LR and $UNK) and ($L3 or $L4)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($L3 and $NF and $L4) and ($LR or $UNK)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $UNK) and ($L3 or $L4) and ($L1 or $NF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($UNK)) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $UNK) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR and $UNK and $L3 and $L4) and (!defined($L1) and !defined($NF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $UNK and $NF) and (!defined($L3) and !defined($L4))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($L3 and $L4 and $NF) and (!defined($LR) and !defined($UNK))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $UNK and $NF and $L4 and !defined($L1) and !defined($L3))) {
    $pass = 'warn_5arm_';
  } elsif(($L3 and $NF and !defined($LR) and !defined($UNK) and !defined($L4))) {
    $pass = 'warn_3arm_';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1a') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_postgate_passfail_2 {
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $L3   = $class->best_valid_hit($qctest_result, 'L3');
  my $L4   = $class->best_valid_hit($qctest_result, 'L4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($L3 and $L1 and $NF and $LR and $LRR and $L4) { #perfect
    $pass = 'pass1';
  } elsif(($L3 and $LR and $LRR and $L4) and ($L1 or $NF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($L1 and $NF and $LR and $LRR) and ($L3 or $L4)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($L3 and $L1 and $NF and $L4) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($L3 or $L4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR and $LRR and $L3 and $L4) and (!defined($L1) and !defined($NF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $L1 and $NF) and (!defined($L3) and !defined($L4))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($L3 and $L4 and $L1 and $NF) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and $NF and $L4 and !defined($L1) and !defined($L3))) {
    $pass = 'warn_5arm_';
  } elsif(($L3 and $L1 and $NF and !defined($LR) and !defined($LRR) and !defined($L4))) {
    $pass = 'warn_3arm_';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1a') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_postgate_passfail_3 {
  my $class = shift;
  my $qctest_result = shift; 
  
  #my $clone = $class->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $R3   = $class->best_valid_hit($qctest_result, 'R3');
  my $R4   = $class->best_valid_hit($qctest_result, 'R4');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($R3 and $L1 and $NF and $LR and $LRR and $R4) { #perfect
    $pass = 'pass1';
  } elsif(($R3 and $LR and $LRR and $R4) and ($L1 or $NF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($L1 and $NF and $LR and $LRR) and ($R3 or $R4)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($R3 and $L1 and $NF and $R4) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($R3 or $R4) and ($L1 or $NF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($R3 or $R4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($R3 or $R4) and ($L1 or $NF)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR and $LRR and $R3 and $R4) and (!defined($L1) and !defined($NF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $L1 and $NF) and (!defined($R3) and !defined($R4))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($R3 and $R4 and $L1 and $NF) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and $NF and $R4 and !defined($L1) and !defined($R3))) {
    $pass = 'warn_5arm_';
  } elsif(($R3 and $L1 and $NF and !defined($LR) and !defined($LRR) and !defined($R4))) {
    $pass = 'warn_3arm_';
  }
    
  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1a') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_postgate_passfail_4 {
  my $class = shift;
  my $qctest_result = shift; 
  
  my $design = $qctest_result->engineered_seq->design;
  my $clone = $qctest_result->construct;  #ConstructClone object
  #my $eng_seq = $class->engineered_seq;    #Design object
   
  #printf("postgate_clone_passfail : maps %s : Design %s %s %s clone_%d\n",
  #      $clone->well,
  #      $eng_seq->well,
  #      $eng_seq->gene_name,
  #      $eng_seq->exon_name,
  #      $clone->clone_num);
    
  my $pass = 'fail';
  
  my $L1   = $class->best_valid_hit($qctest_result, 'L1');
  my $R3   = $class->best_valid_hit($qctest_result, 'R3');
  my $R4   = $class->best_valid_hit($qctest_result, 'R4');
  my $SP6  = $class->best_valid_hit($qctest_result, 'SP6');
  my $NF   = $class->best_valid_hit($qctest_result, 'NF');
  my $PNF  = $class->best_valid_hit($qctest_result, 'PNF');
  my $UNK  = $class->best_valid_hit($qctest_result, 'UNK');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $IFRT = $class->best_valid_hit($qctest_result, 'IFRT');
  
  if ($design->is_deletion){
     $LR = 1;
  } 

  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $LFR  = $class->best_valid_hit($qctest_result, 'LFR');
  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');
  unless($FCHK){#defined but 0 if FCHK read present, has sequence, but failing test
    $FCHK=0 if scalar(grep{$_->oligo_name eq 'FCHK' }@{$clone->seqreads});
  }
  my $IRES = $class->best_valid_hit($qctest_result, 'IRES');

  if($R3 and $L1 and ($PNF or $NF) and $LR and $LRR and ($R4 or $SP6)) { #perfect
    $pass = 'pass1';
  } elsif(($R3 and $LR and $LRR and ($R4 or $SP6)) and ($L1 or $NF or $PNF)) { #1 broken primer
    $pass = 'pass2.1';
  } elsif(($L1 and ($PNF or $NF) and $LR and $LRR) and ($R3 or $R4 or $SP6)) { #1 broken primer
    $pass = 'pass2.2';
  } elsif(($R3 and $L1 and ($PNF or $NF) and ($R4 or $SP6)) and ($LR or $LRR)) { #1 broken primer
    $pass = 'pass2.3';
  } elsif(($LR and $LRR) and ($R3 or $R4 or $SP6) and ($L1 or $NF or $PNF)) { #2 broken primers
    $pass = 'pass3';
  } elsif(($LR and !defined($LRR)) and ($R3 or $R4 or $SP6) and ($L1 or $NF or $PNF or $IFRT)) { #3 broken primers, but biologically sound
    $pass = 'pass4.1';
  } elsif((!defined($LR) and $LRR) and ($R3 or $R4 or $SP6) and ($L1 or $NF or $PNF or $IFRT)) { #3 broken primers, but biologically sound
    $pass = 'pass4.2';
  } elsif(($LR) and ($L1 or $PNF or $IFRT)) { #2 primers - one verifies the loxP site and the other the cassette 
    $pass = 'pass4.3';
  } elsif(($LR and $LRR and $R3 and ($R4 or $SP6)) and (!defined($L1) and !defined($NF) and !defined($PNF))) { #2 broken primers but bad
    $pass = 'pass5.1';
  } elsif (($LR and $LRR and $L1 and ($PNF or $NF)) and (!defined($R3) and !defined($R4) and !defined($SP6))) { #2 broken primers but bad
    $pass = 'pass5.2';
  } elsif(($R3 and ($R4 or $SP6) and $L1 and ($PNF or $NF)) and (!defined($LR) and !defined($LRR))) { #2 broken primers but bad
    $pass = 'pass5.3';
  } elsif(($LR and $LRR and ($PNF or $NF) and ($R4 or $SP6) and !defined($L1) and !defined($R3))) {
    $pass = 'warn_5arm_';
  } elsif(($R3 and $L1 and ($PNF or $NF) and !defined($LR) and !defined($LRR) and !defined($R4) and !defined($SP6))) {
    $pass = 'warn_3arm_';
  }

  if($pass ne 'fail') { 
    if($FCHK) { $pass .= 'a'; }
    elsif(defined($FCHK)) { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass=~/^pass1a?$/) { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

##################################
# new added test for toxin, by wy1

sub calc_toxin_passfail {
  my $class = shift;
  my $qctest_result = shift;

  my $toxin_pass;
  my $test = 0;

  # test if these primers are tested or not , similar to FCHK check
  my $clone = $qctest_result->construct;  
  # get seqreads
  my $seqreads = $clone->seqreads;

  #foreach my $seqread (@$seqreads) {
    
    #if ( ( ($seqread->oligo_name eq 'FSI') && ($seqread->oligo_name eq 'BSO')) 
    #   || ( ($seqread->oligo_name eq 'PGO') && ($seqread->oligo_name eq 'XMI') ) ) {
    #   $test = 1;        
    #}
    # put it into hash
    

  #}
 
  my %oligos = map{ $_->oligo_name =>1 }@$seqreads;

  $test = ( $oligos{'FSI'} && $oligos{'BSO'} ) || ( $oligos{'PGO'} && $oligos{'XMI'} );

  if ($test == 1) {
    my $FSI = $class->best_valid_hit($qctest_result, 'FSI');
    my $PGO = $class->best_valid_hit($qctest_result, 'PGO');
    my $BSO = $class->best_valid_hit($qctest_result, 'BSO');
    my $XMI = $class->best_valid_hit($qctest_result, 'XMI');  
    # 
    if (($FSI && $BSO) || ($PGO && $XMI)) {
      $toxin_pass = 'pass';
    }else {
      $toxin_pass = 'fail';
    } 
  }else {
      $toxin_pass = 'untested';
  }

  # set toxin pass level
  $qctest_result->toxin_pass($toxin_pass);
  return $toxin_pass;
} 

##################################

sub calc_allele_passfail {
  my $class = shift;
  my $qctest_result = shift; 

  my $pass = 'fail';
  
  my $G3   = $class->best_valid_hit($qctest_result, 'G3');
  my $R1R  = $class->best_valid_hit($qctest_result, 'R1R');
  my $R2R  = $class->best_valid_hit($qctest_result, 'R2R');
  my $LF   = $class->best_valid_hit($qctest_result, 'LF');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $G5   = $class->best_valid_hit($qctest_result, 'G5');

#  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($G5 and $R1R and $G3 and ($LF or $LR) and $LRR and $R2R) { # perfect
    $pass = 'pass1';
  } elsif(($G5 or $R1R) and ($G3 or $R2R) and ($LF or $LR or $LRR)) { # all regions there even if one of each pair of reads fails
    $pass = 'pass2';
  } elsif(($G3 or $R2R) and ($LF or $LR or $LRR)) { # no 5 arm
    $pass = 'pass3';
  } elsif(($G5 or $R1R) and ($R2R or $G3)) { # no middle
    $pass = 'pass4';
  } elsif($G5 and $R1R) { # no middle or 3 arm
    $pass = 'pass5';
  } 

  if($pass ne 'fail') { 
#    if($FCHK) { $pass .= 'a'; }
#    else { $pass .= 'b'; }
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_allele_passfail_3prime {
  my $class = shift;
  my $qctest_result = shift; 

  my $pass = 'fail';
  
  my $G3   = $class->best_valid_hit($qctest_result, 'G3');
  my $R1R  = $class->best_valid_hit($qctest_result, 'R1R');
  my $R2R  = $class->best_valid_hit($qctest_result, 'R2R');
  my $LF   = $class->best_valid_hit($qctest_result, 'LF');
  my $LR   = $class->best_valid_hit($qctest_result, 'LR');
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');
  my $G5   = $class->best_valid_hit($qctest_result, 'G5');

#  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($G3 and ($LF or $LR or $LRR) and $R2R) { # perfect
    $pass = 'pass1';
  } elsif(($G3 or $R2R) and ($LF or $LR or $LRR)) { 
    $pass = 'pass2';
  } elsif(0) { 
    $pass = 'pass3';
  } elsif($R2R or $G3) { 
    $pass = 'pass4';
  } elsif($LF or $LR or $LRR) { # no middle or 3 arm
    $pass = 'pass5';
  } 

  if($pass =~/^pass[123]/) { 
    $qctest_result->is_valid(1); 
  }
  if($pass eq 'pass1') { $qctest_result->is_perfect(1); }
  $qctest_result->pass_status($pass);
  return $pass  
}


sub calc_allele_tronly_passfail {
  my $class = shift;
  my $qctest_result = shift; 

  my $pass = 'fail';
  
  my $R2R  = $class->best_valid_hit($qctest_result, 'R2R');
  my $LFR = $class->best_valid_hit($qctest_result, 'LFR');

#  my $FCHK = $class->best_valid_hit($qctest_result, 'FCHK');

  if($R2R or $LFR) { # perfect
    $pass = 'pass';
    $qctest_result->is_valid(1); 
    $qctest_result->is_perfect(1); 
  } 

  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_allele_tponly_passfail {
  my $class = shift;
  my $qctest_result = shift; 

  my $pass = 'fail';
  
  my $LRR  = $class->best_valid_hit($qctest_result, 'LRR');

  if($LRR) { # perfect
    $pass = 'pass';
    $qctest_result->is_valid(1); 
    $qctest_result->is_perfect(1); 
  } 

  $qctest_result->pass_status($pass);
  return $pass  
}

sub calc_allele_fponly_passfail {
  my $class = shift;
  my $qctest_result = shift; 

  my $pass = 'fail';
  
  my $R1R  = $class->best_valid_hit($qctest_result, 'R1R');
  my $IFRT = $class->best_valid_hit($qctest_result, 'IFRT');

  if($R1R or $IFRT) { # perfect
    $pass = 'pass';
    $qctest_result->is_valid(1); 
    $qctest_result->is_perfect(1); 
  } 

  $qctest_result->pass_status($pass);
  return $pass  
}




1;

