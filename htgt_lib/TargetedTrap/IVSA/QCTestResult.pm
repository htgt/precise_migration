### TargetedTrap::IVSA::QCTestResult
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Try David Jackson (david.jackson@sanger.ac.uk) 
# No longer maintained by Jessica Severin (jessica@sanger.ac.uk) 
# No longer maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author las
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact team87 informatics on implemetation/design detail: vecinfor@sanger.ac.uk

=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _

=cut

package TargetedTrap::IVSA::QCTestResult;

use strict;
use Bio::Seq;
use Bio::SeqIO;
use Data::Dumper;

use DBD::Oracle qw(:ora_types);
#use Bio::EnsEMBL::Utils::Exception qw( throw warning );

use TargetedTrap::IVSA::QCTestRun;
use TargetedTrap::IVSA::QCTestPrimer;
use TargetedTrap::IVSA::Design;
use TargetedTrap::IVSA::ConstructClone;

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
  
  $self->{'comments'} = undef;
  $self->{'design'} = undef;
  $self->{'construct'} = undef;
  $self->{'post_gateway'} = 0;
  $self->{'allele'} = 0;
  $self->{'tronly'} = 0;
  $self->{'tponly'} = 0;
  $self->{'fponly'} = 0;
  $self->{'primers'} = [];
  $self->{'primer_test_array'} = [];
  $self->{'calc_ok'} = 0;
  $self->{'sum_score'} = undef;
  $self->{'best_clone'} = undef;
  $self->{'pass_status'} = undef;
  $self->{'is_best_for_engseq_in_run'} = 0;
  $self->{'is_best_for_construct_in_run'} = 0;
  $self->{'is_chosen_for_engseq_in_run'} = 0;
  $self->{'distribute_for_engseq'} = 0;
  $self->{'is_valid'} = 0;
  $self->{'is_perfect'} = 0;

  $self->init_calc;
  $self->set_primers;

  # add extra attribute
  $self->{'toxin_pass'} = undef;
  
  return $self;
}

sub init_calc {
  my $self = shift;
  $self->{'sum_score'} = undef;
  $self->{'best_clone'} = undef;
  $self->{'primer_test_array'} = [];
}

#################################################
sub comments {
  my $self = shift;
  $self->{'comments'} = shift if(@_);
  return $self->{'comments'};
}
sub sum_score {
  my $self = shift;
  $self->{'sum_score'} = shift if(@_);
  return $self->{'sum_score'};
}
sub pass_status {
  my $self = shift;
  $self->{'pass_status'} = shift if(@_);
  return $self->{'pass_status'};
}

sub toxin_pass {
  my $self = shift;
  $self->{'toxin_pass'} = shift if(@_);
  return $self->{'toxin_pass'}; 
}

sub is_valid {
  my $self = shift;
  $self->{'is_valid'} = shift if(@_);
  return $self->{'is_valid'};
}
sub is_perfect {
  my $self = shift;
  $self->{'is_perfect'} = shift if(@_);
  return $self->{'is_perfect'};
}

sub is_expected {
  my $self = shift;
  if(defined($self->engineered_seq) and 
     defined($self->expected_engineered_seq) and
     ($self->expected_engineered_seq->unique_tag eq $self->engineered_seq->unique_tag))
  { return 'is_expected'; }
  else { return ''; }
}

sub is_best_for_engseq_in_run {
  my $self = shift;
  $self->{'is_best_for_engseq_in_run'} = shift if(@_);
  return $self->{'is_best_for_engseq_in_run'};
}
sub is_best_for_construct_in_run {
  my $self = shift;
  $self->{'is_best_for_construct_in_run'} = shift if(@_);
  return $self->{'is_best_for_construct_in_run'};
}
sub is_chosen_for_engseq_in_run {
  my $self = shift;
  $self->{'is_chosen_for_engseq_in_run'} = shift if(@_);
  return $self->{'is_chosen_for_engseq_in_run'};
}

sub distribute_for_engseq {
  my $self = shift;
  $self->{'distribute_for_engseq'} = shift if(@_);
  return $self->{'distribute_for_engseq'};
}

sub post_gateway {
  my $self = shift;
  if(@_) {
    $self->{'post_gateway'} = shift;
    $self->set_primers;
  }
  return $self->{'post_gateway'};
}

sub allele {
  my $self = shift;
  if(@_) {
    $self->{'allele'} = shift;
    $self->set_primers;
  }
  return $self->{'allele'};
}

sub tronly {
  my $self = shift;
  if(@_) {
    $self->{'tronly'} = shift;
    $self->set_primers;
  }
  return $self->{'tronly'};
}

sub tponly {
  my $self = shift;
  if(@_) {
    $self->{'tponly'} = shift;
    $self->set_primers;
  }
  return $self->{'tponly'};
}

sub fponly {
  my $self = shift;
  if(@_) {
    $self->{'fponly'} =  shift;
    $self->set_primers;
  }
  return $self->{'fponly'};
}

#################################################
sub set_primers {
  my $self = shift;

  if($self->post_gateway) {
    $self->{'primers'} = [
        'L3',
        'L1',
        'FCHK',  #need to eventually make into a proper test turn back on
	'IRES', #for new L1L2 promoter cassette
        'NF',
	'PNF', #for new L1L2 promoter cassette - maybe new for all
        #'UNK',
        #'LF',
        #'LFR',
        'LR',
        'LRR',
        'L4'
        ];
  }
  elsif($self->allele) {
    $self->{'primers'} = [
        'L3',
        'L1',
        'FCHK',  #need to eventually make into a proper test turn back on
        'NF',
        #'UNK',
        'LF',
        #'LFR',
        'LR',
        'LRR',
        'L4'
        ];
  } else {
    $self->{'primers'} = [
        'R3F',
        #'R3',
        #'R1R',
        'Z1',
        'Z2',
        #'R2R',
        #'UNK',
        #'LF',
        #'LFR',
        'LRR',
        'LR',
        #'R4',
        'R4R'
        ];
  }
  $self->{'att_primers'}= ['R3F', 'Z1', 'Z2', 'R4R'];
}

#################################################

sub engineered_seq {
  my $self = shift;
  if(@_) {
    my $eng_seq = shift;
    unless(defined($eng_seq) && $eng_seq->isa('TargetedTrap::IVSA::EngineeredSeq')) {
      throw('engineered_seq param must be a TargetedTrap::IVSA::EngineeredSeq');
    }
    $self->{'engineered_seq'} = $eng_seq;
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
    }
  }
  return $self->{'engineered_seq'};
}


sub expected_engineered_seq {
  my $self = shift;
  if(@_) {
    my $eng_seq = shift;
    if(defined($eng_seq) && !($eng_seq->isa('TargetedTrap::IVSA::EngineeredSeq'))) {
      print ("expected_engineered_seq param must be a TargetedTrap::IVSA::EngineeredSeq\nNot a" . $eng_seq);
    }
    $self->{'expected_engineered_seq'} = $eng_seq;
  }
  
  #lazy load from database if possible
  if(!defined($self->{'expected_engineered_seq'}) and 
     defined($self->database) and 
     defined($self->{'expected_engineered_seq_id'}))
  {
    #lazy load from database if possible
    my $eng_seq = TargetedTrap::IVSA::EngineeredSeq->fetch_by_id($self->database, $self->{'expected_engineered_seq_id'});
    if(defined($eng_seq)) {
      $self->{'expected_engineered_seq'} = $eng_seq;
    }
  }
  return $self->{'expected_engineered_seq'};
}


sub construct {
  my $self = shift;
  if(@_) {
    my $construct = shift;
    unless(defined($construct) && $construct->isa('TargetedTrap::IVSA::ConstructClone')) {
      throw('construct param must be a TargetedTrap::IVSA::ConstructClone');
    }
    $self->{'construct'} = $construct;
    $self->expected_engineered_seq($construct->expected_engineered_seq);
  }
  
  #lazy load from database if possible
  if(!defined($self->{'construct'}) and 
     defined($self->database) and 
     defined($self->{'construct_clone_id'})) 
  {
    #lazy load from database if possible
    my $clone = TargetedTrap::IVSA::ConstructClone->fetch_by_id(
         $self->database, $self->{'construct_clone_id'});
    if(defined($clone)) {
      $self->{'construct'} = $clone;
    }
  }
  return $self->{'construct'};
}


sub qctest_run {
  my $self = shift;
  if(@_) {
    my $testrun = shift;
    unless(defined($testrun) && $testrun->isa('TargetedTrap::IVSA::QCTestRun')) {
      throw('qctest_run param must be a TargetedTrap::IVSA::QCTestRun');
    }
    $self->{'qctest_run'} = $testrun;
  }

  #lazy load from database if possible
  if(!defined($self->{'qctest_run'}) and 
     defined($self->database) and 
     defined($self->{'qctest_run_id'})) 
  {
    #lazy load from database if possible
    my $testrun = TargetedTrap::IVSA::QCTestRun->fetch_by_id(
         $self->database, $self->{'qctest_run_id'});
    if(defined($testrun)) {
      $self->{'qctest_run'} = $testrun;
    }
  }

  return $self->{'qctest_run'};
}

#################################################

sub display_info {
  my $self = shift;
  printf("%s\n", $self->description); 
}

sub description {
  my $self = shift;
  my $synthvec = $self->engineered_seq;
  my $str = sprintf("qctest(%s) EngSeq(%s) %s : Clone %s : %d %s %s : %s", 
    $self->id,
    $synthvec->id,
    $synthvec->name,
    $self->construct->clone_tag,
    $self->sum_score, 
    $self->pass_status, 
    $self->is_expected, 
    $self->valid_primers
    );
  return $str;
}

sub valid_primers {
  my $self = shift;
  my $str = '';
  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    if($qctest_primer->is_valid) {
      $str .= $qctest_primer->primer . ' ';
    }
  }
  return $str;
}


#######################################################################

sub is_better {
  my $self = shift;
  my $best = shift;

  print $self->pass_status . " test\n";
  #tests whether $self is a 'better' pairing QCTest than the the previous $best
  
  #any test is better than none
  if(!defined($best)) { return 1; }

  print "  " . $best->pass_status . " current best\n";
  #tests whether $self is a 'better' pairing QCTest than the the previous $best

  #if both 'fail', a 'is_expected' fail is better than an out of well fail
  if(($self->pass_status =~ /fail/) and ($best->pass_status =~ /fail/)) {
      print "both failed\n";
    if(($self->is_expected) and !($best->is_expected)) { return 1; }
    if($self->sum_score > $best->sum_score) { return 1; }
  }

  #any pass/warn is better than any fail (irrespective of well_loc)
  if(($self->pass_status !~ /fail/) and ($best->pass_status =~ /fail/)) { return 1; }
  
  
  #if both 'pass' 
  if(($self->pass_status !~ /fail/) and ($best->pass_status !~ /fail/)) {

    #any is_expected level 1 or 2 pass is better than an out of well pass
    if($self->is_expected and ($self->pass_status =~ /pass[12]/) and !($best->is_expected)) { return 1; }
    if($best->is_expected and ($best->pass_status =~ /pass[12]/) and !($self->is_expected)) { return 0; }
 
    #any pass is better than any warn (or something else) irrespective of well_loc
    if(($self->pass_status =~ /pass/) and ($best->pass_status !~ /pass/)) { return 1; }
    if(($self->pass_status !~ /pass/) and ($best->pass_status =~ /pass/)) { return 0; }

    #a lower pass level number is better irrespective of well location
    if($self->pass_status lt $best->pass_status) { return 1; }
      
    #if same pass_status, then higher sum_score is better irrespective of well location
    if(($self->pass_status eq $best->pass_status) and
       ($self->sum_score > $best->sum_score)) { return 1; }

  } #both pass
  
  return 0;
}

#######################################################################
# Detailed display sections
#######################################################################

sub show_clone_2_design_summary {
  my $self = shift;
  my $show_align = shift;
  
  my $clone = $self->construct;        #ConstructClone object
  my $engseq = $self->engineered_seq;  #EngineeredSeq object
      
  printf("qctest[%s] Clone %s <=> EngSeq %s : sum:%7.2f : %s %s : %s\n", 
      $self->id,
      $clone->clone_tag,
      $engseq->name,
      $self->sum_score,
      $self->pass_status,
      $self->is_expected,
      $self->valid_primers
      );

  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
        
    my $status  = $qctest_primer->status;
    my $hit     = $qctest_primer->alignment;
    my $seqread = $qctest_primer->seqread;
    
    if(defined($hit)) {
      if($hit->extra_info) { $status .= sprintf("(%s)", $hit->extra_info); } 

      printf(" %5s %9s rlen=%d alen=%d cmatch=%d mscore=%1.2f ident=%1.2f (%d-%d %s1) to (%d-%d %s1)", 
              $qctest_primer->primer, 
              $status, 
              $hit->seqread->seq_length,
              $hit->align_length,
              $hit->cmatch, 
              $hit->map_score,
              $hit->percent_identity,
              $hit->h_cigarseq->start, 
              $hit->h_cigarseq->end,
              $hit->h_cigarseq->ori,
              $hit->q_cigarseq->start, 
              $hit->q_cigarseq->end,
              $hit->q_cigarseq->ori
              ); 
      unless($qctest_primer->is_valid) {
        printf(" feats[%s]", $hit->observed_features);
      }
      printf("\n");
      if($show_align) { $hit->print_pair_format_alignment; }
    } elsif($status eq 'no_hits') { 
      printf(" %5s %9s %d\n", 
              $qctest_primer->primer,
              $status,
              $seqread->seq_length
              ); 
    } else {
      printf(" %5s %9s\n", $qctest_primer->primer, $status); 
    }
  }
  print("\n"); #empty line
}


sub csv_output_header {
  my $self = shift;
  
  my $outline = sprintf("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s",  
        'clone', 'obs_design', 'gene', 'exon', 'exon_strand', 
        'obs/exp_design', 'pass/fail', 'best_for_design', 'chosen_for_design', 'distribute_for_design');
        
  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    $outline .= sprintf(",%s_status", $qctest_primer->primer);
  }
  $outline .= ',sum_score';
  
  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    my $primer = $qctest_primer->primer;
    $outline .= sprintf(",%s_readlen",$primer);
    $outline .= sprintf(",%s_alignlen",$primer);
    $outline .= sprintf(",%s_mscore",$primer);
    $outline .= sprintf(",%s_ident", $primer);
    $outline .= sprintf(",%s_hstart", $primer);
    $outline .= sprintf(",%s_hend", $primer);
    $outline .= sprintf(",%s_ori", $primer);
  }

  #ATT site analysis only for PostCre plates
  #if(!$self->post_gateway) {
  #  foreach my $primer (@{$self->{'att_primers'}}) {
  #    $outline .= sprintf(", %s_B_test", $primer);    
  #    $outline .= sprintf(", %s_R_test", $primer);    
  #  }

  #  foreach my $primer (@{$self->{'att_primers'}}) {    
  #    $outline .= sprintf(", %s_B_iden", $primer);    
  #    $outline .= sprintf(", %s_B_iden%%", $primer);    
  #    $outline .= sprintf(", %s_B_score", $primer);     
  #    $outline .= sprintf(", %s_R_iden", $primer);     
  #    $outline .= sprintf(", %s_R_iden%%", $primer);     
  #    $outline .= sprintf(", %s_R_score", $primer);     
  #  }
  #}
  
  return $outline;
}


sub csv_output_line {
  my $self = shift;  
  my $design_db = shift;  
  my $qc_db = shift;  

  my $clone  = $self->construct;
  my $eng_seq = $self->engineered_seq;
  my $design = $self->engineered_seq->design;
  my $expected_design;
  if ($self->expected_engineered_seq) {
      $expected_design = $self->expected_engineered_seq->design;
  }
  
  my $outline .= sprintf("%s_%s_%s,%s_%s,%s,%s,%s,%s,%s", 
                    $clone->plate, $clone->well, $clone->clone_num,
                    $design->plate, $design->well,
                    $design->gene_name,
                    $design->exon_name,
                    $design->genomic_region->strand,
                    $self->is_expected,
                    $self->pass_status);

  if($self->is_best_for_engseq_in_run) {
    $outline .= sprintf(",%s", $design->well);
  } else { 
    $outline .= sprintf(",");
  }

  # this is the engseq_id of the design this is chosen
  # check the expected and the seen engineered seq id to see which one matches
  # use this to get the right well
  if($self->is_chosen_for_engseq_in_run) {
      if ($self->{'is_chosen_for_engseq_in_run'} == $self->{'engineered_seq_id'}) {
	  $outline .= sprintf(",%s", $design->well);
      }
      elsif ($self->{'is_chosen_for_engseq_in_run'} == $self->{'expected_engineered_seq_id'}) {
	  $outline .= sprintf(",%s", $expected_design->well);
      }
      else {
	  # this must be chosen for an unexpected design
	  # get the design well corresponding to this engseq_id
	  my $synthvec = TargetedTrap::IVSA::SyntheticConstruct->fetch_by_id($qc_db, $self->{'is_chosen_for_engseq_in_run'});
	  $synthvec->fetch_design($design_db);
	  $outline .= sprintf(",%s", $synthvec->design->well);
      }
  } else { 
    $outline .= sprintf(",");
  }


  # this is the engseq_id of the design this is chosen for distribution
  # check the expected and the seen engineered seq id to see which one matches
  # use this to get the right well
  if($self->distribute_for_engseq) {
      if ($self->{'distribute_for_engseq'} == $self->{'engineered_seq_id'}) {
	  $outline .= sprintf(",%s", $design->well);
      }
      elsif ($self->{'distribute_for_engseq'} == $self->{'expected_engineered_seq_id'}) {
	  $outline .= sprintf(",%s", $expected_design->well);
      }
      else {
	  # this must be chosen for an unexpected design
	  # get the design well corresponding to this engseq_id
	  my $synthvec = TargetedTrap::IVSA::SyntheticConstruct->fetch_by_id($qc_db, $self->{'distribute_for_engseq'});
	  $synthvec->fetch_design($design_db);
	  $outline .= sprintf(",%s", $synthvec->design->well);
      }
  } else { 
    $outline .= sprintf(",");
  }


  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    $outline .= sprintf(",%s", $qctest_primer->status); 
  }

  $outline .= sprintf(",%1.2f", $self->sum_score);

  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    my $primer  = $qctest_primer->primer;
    my $status  = $qctest_primer->status;
    my $hit     = $qctest_primer->alignment;
    my $seqread = $qctest_primer->seqread;

    #$outline .= sprintf(", %s_status, %s_readlen, %s_score, %s_hstart, %s_hend", $primer, $primer, $primer, $primer, $primer);

    if($hit) {
      $outline .= sprintf(",%d,%d,%1.2f,%1.2f,%d,%d,%s", 
              $hit->seqread->seq_length,
              $hit->align_length,
              $hit->map_score,
              $hit->percent_identity,
              $hit->h_cigarseq->start, 
              $hit->h_cigarseq->end,
              $hit->q_cigarseq->ori); 
    } elsif($seqread) {
      $outline .= sprintf(",%d,%d,%1.2f,%1.2f,%d,%d,%s", 
                $seqread->seq_length, 0, 0.0, 0.0, 0, 0, ''); 
    } else {
      $outline .= sprintf(",%d,%d,%1.2f,%1.2f,%d,%d,%s", 0, 0, 0.0, 0.0, 0, 0, ''); 
    }
  }
  return $outline;
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
  
  $self->primary_id($rowHash->{'QCTEST_RESULT_ID'});
  $self->comments($rowHash->{'COMMENTS'});
  $self->sum_score($rowHash->{'SUM_SCORE'});
  $self->pass_status($rowHash->{'PASS_STATUS'});
  $self->is_valid($rowHash->{'IS_VALID'});
  $self->is_perfect($rowHash->{'IS_PERFECT'});

  #for lazy loading
  $self->{'engineered_seq_id'} = $rowHash->{'ENGINEERED_SEQ_ID'};
  $self->{'expected_engineered_seq_id'} = $rowHash->{'EXPECTED_ENGINEERED_SEQ_ID'};
  $self->{'construct_clone_id'} = $rowHash->{'CONSTRUCT_CLONE_ID'};
  $self->{'qctest_run_id'} = $rowHash->{'QCTEST_RUN_ID'};
  $self->{'is_chosen_for_engseq_in_run'} = $rowHash->{'IS_CHOSEN_FOR_ENGSEQ_IN_RUN'};
  $self->{'distribute_for_engseq'} = $rowHash->{'DISTRIBUTE_FOR_ENGSEQ'};

  
  $self->_fetch_primer_tests($dbh);

  #ok this is a bit dodgy but it works.  I need to lazy load
  #the engineered_seq and/or construct in order to properly
  #set the 'best' linkages
  if($rowHash->{'IS_BEST_FOR_ENGSEQ_IN_RUN'}) {
    $self->engineered_seq->best_qctest($self);
  }
  if($rowHash->{'IS_BEST_FOR_CONSTRUCT_IN_RUN'}) {
    $self->construct->best_qctest($self);
  }
    return $self;
}

sub _fetch_primer_tests {
  my $self = shift;
  my $dbh = shift;
  
  my $primer_tests = TargetedTrap::IVSA::QCTestPrimer->fetch_all_by_qctest_id($self->database, $self->id);
  foreach my $qctest_primer (@$primer_tests) {
    $qctest_primer->qctest($self);
  }
  $self->{'primer_test_array'} = $primer_tests;
  $self->{'calc_ok'} = 1;
}


##### public class methods for fetching by utilizing DBObject framework methods #####

sub fetch_by_id {
  my $class = shift;
  my $db = shift;
  my $id = shift;
  
  my $sql = "SELECT * FROM qctest_result WHERE qctest_result_id = ?";
  return $class->fetch_single($db, $sql, $id);
}

sub fetch_all_bestconstruct_by_runid {
  my $class = shift;
  my $db = shift;
  my $run_id = shift;
  
  my $sql = "SELECT * FROM qctest_result WHERE qctest_run_id = ? AND IS_BEST_FOR_CONSTRUCT_IN_RUN=1";
  return $class->fetch_multiple($db, $sql, $run_id);
}

#this one does not work in the current V3 system
sub fetch_all_by_run_and_design_id {
  my $class = shift;
  my $db = shift;
  my $run_id = shift;
  my $design_id = shift;
  
  my $sql = "SELECT * FROM qctest_result WHERE qctest_run_id = ? AND design_inst_id=?";
  return $class->fetch_multiple($db, $sql, $run_id, $design_id);
}

sub fetch_all_by_run {
  my $class = shift;
  my $db = shift;
  my $run_id = shift;

  my $sql = "SELECT * FROM qctest_result where qctest_run_id = ?";
  return $class->fetch_multiple($db, $sql, $run_id);
}


sub fetch_best_by_design_instance_id_and_stage {
  my $class = shift;
  my $db = shift;
  my $design_instance_id = shift;
  my $stage = shift;
  
  my $sql = "SELECT t.* FROM qctest_result t
             JOIN qctest_run r on(t.qctest_run_id = r.qctest_run_id)
             JOIN synthetic_vector v on(t.ENGINEERED_SEQ_ID = v.ENGINEERED_SEQ_ID)
             WHERE is_best_for_engseq_in_run=1 
             AND r.is_public=1
             AND r.stage = ?
             AND v.design_instance_id=?";
  return $class->fetch_single($db, $sql, $stage, $design_instance_id);
}

sub fetch_chosen_by_design_instance_id_and_stage {
  my $class = shift;
  my $db = shift;
  my $design_instance_id = shift;
  my $stage = shift;
  
  my $sql = "SELECT t.* FROM qctest_result t
             JOIN qctest_run r on(t.qctest_run_id = r.qctest_run_id)
             JOIN synthetic_vector v on(t.ENGINEERED_SEQ_ID = v.ENGINEERED_SEQ_ID)
             WHERE is_chosen_for_engseq_in_run is not null 
             AND r.is_public=1
             AND r.stage = ?
             AND v.design_instance_id=?";
  return $class->fetch_single($db, $sql, $stage, $design_instance_id);
}

##### DBObject store method #####

sub store {
  my $self = shift;
  my $db = shift;
  if($db) { $self->database($db); }
    
  my $dbID = $self->next_sequence_id('seq_qctest_result');
  $self->primary_id($dbID);
  
  my $dbh = $self->database->get_connection;  
  my $sql = "INSERT INTO QCTEST_RESULT (
                QCTEST_RESULT_ID,
                QCTEST_RUN_ID,
                CONSTRUCT_CLONE_ID,
                ENGINEERED_SEQ_ID,
                COMMENTS,
                PASS_STATUS,
                SUM_SCORE,
                IS_BEST_FOR_ENGSEQ_IN_RUN,
                IS_BEST_FOR_CONSTRUCT_IN_RUN,
                IS_CHOSEN_FOR_ENGSEQ_IN_RUN,
                DISTRIBUTE_FOR_ENGSEQ,
                EXPECTED_ENGINEERED_SEQ_ID,
                IS_VALID,
                IS_PERFECT,
                TOXIN_PASS
             ) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $dbID);
  $sth->bind_param(2, $self->qctest_run->id);
  $sth->bind_param(3, $self->construct->id);
  $sth->bind_param(4, $self->engineered_seq->id);
  $sth->bind_param(5, $self->comments);
  $sth->bind_param(6, $self->pass_status);
  $sth->bind_param(7, $self->sum_score);
  $sth->bind_param(8, $self->is_best_for_engseq_in_run);
  $sth->bind_param(9, $self->is_best_for_construct_in_run);
  $sth->bind_param(10, $self->is_chosen_for_engseq_in_run);
  $sth->bind_param(11, $self->distribute_for_engseq);
  if($self->expected_engineered_seq) {
    $sth->bind_param(12, $self->expected_engineered_seq->id);
  } else {
    $sth->bind_param(12, undef);
  }
  $sth->bind_param(13, $self->is_valid);
  $sth->bind_param(14, $self->is_perfect);
  $sth->bind_param(15, $self->toxin_pass);
  $sth->execute();
  $sth->finish;
      
  foreach my $qctest_primer (@{$self->{'primer_test_array'}}) {
    $qctest_primer->store($self->database);
  }  
  return $self;
}


sub update_best_for_design_in_run {
  my $self = shift;
  
  #first reset all tests for this design in this run
  my $dbh = $self->database->get_connection;  
  my $sql = "UPDATE QCTEST_RESULT set is_best_for_engseq_in_run=0
             where DESIGN_INST_ID=? and QCTEST_RUN_ID=?";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->engineered_seq->id);
  $sth->bind_param(2, $self->qctest_run->id);
  $sth->execute();
  $sth->finish;

  #then flip this test to be the 'best'
  $sql = "UPDATE QCTEST_RESULT set is_best_for_engseq_in_run=1
          where QCTEST_RESULT_ID=?";
  $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->id);
  $sth->execute();
  $sth->finish;
      
  return $self;
}


# this isn't working, dont use it
sub update_chosen_for_design_in_run {
  my $self = shift;
  
  #first reset all tests for this design in this run
  my $dbh = $self->database->get_connection;  
  my $sql = "UPDATE QCTEST_RESULT set is_chosen_for_engseq_in_run=0
             where DESIGN_INST_ID=? and QCTEST_RUN_ID=?";
  my $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->engineered_seq->id);
  $sth->bind_param(2, $self->qctest_run->id);
  $sth->execute();
  $sth->finish;

  #then flip this test to be the 'best'
  $sql = "UPDATE QCTEST_RESULT set is_chosen_for_engseq_in_run=?
          where QCTEST_RESULT_ID=?";
  $sth = $dbh->prepare($sql);
  $sth->bind_param(1, $self->id);
  $sth->bind_param(2, $self->id);
  $sth->execute();
  $sth->finish;
      
  return $self;
}

1;

