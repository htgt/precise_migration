### TargetedTrap::IVSA::QCTestResultList
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Vivek Iyer (vvi@sanger.ac.uk) 
#
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION

Class to house the retrieval of list-based-information for a particular qc-result.

=head1 AUTHOR

Vivek Iyer (vvi@sanger.ac.uk)

=head1 CONTACT

  Contact vvi@sanger.ac.uk

=cut

package TargetedTrap::IVSA::QCTestResultList;

use strict;


#################################################
# Class methods
#################################################

sub new {
  my ($class, @args) = @_;
  my $self = {};
  bless $self,$class;
  $self->init(@args);
  return $self;
}

#################################################
# Instance methods
#################################################

sub init {
  my $self = shift;
  return $self;
}


sub is_better {
  my $self = shift;
  my $best = shift;
  
  #tests whether $self is a 'better' pairing QCTest than the the previous $best
  
  #any test is better than none
  if(!defined($best)) { return 1; }

  #if both 'fail', a is_expected fail is better than an out of well fail
  if(($self->pass_status =~ /fail/) and ($best->pass_status =~ /fail/)) {
    if($self->is_expected and !($best->is_expected)) { return 1; }
    if($self->sum_score > $best->sum_score) { return 1; }
  }

  #any pass is better than any fail (irrespective of well_loc)
  if(($self->pass_status !~ /fail/) and ($best->pass_status =~ /fail/)) { return 1; }
  
  #if both 'pass' 
  if(($self->pass_status !~ /fail/) and ($best->pass_status !~ /fail/)) {
    #any is_expected pass is better than an out of well pass (irrespective of level)
    if($self->is_expected and !($best->is_expected)) { return 1; }
 
    #if both tests are the same level of is_expected (both true or both false)
    if($self->is_expected eq $best->is_expected) {
      #a lower pass level number is better
      if($self->pass_status lt $best->pass_status) { return 1; }
      
      #if same pass_status, then higher sum_score is better
      if(($self->pass_status eq $best->pass_status) and
         ($self->sum_score > $best->sum_score)) { return 1; }

    } #same is_expected state

  } #both pass
  
  return 0;
}

#######################################################################
# Detailed display sections
#######################################################################

sub csv_output_header {
  my $self = shift;
}


sub csv_output_line {
  my $self = shift;  
}

sub mapRow {
  my $self = shift;
  my $rowHash = shift;
  my $dbh = shift;
  
  return $self;
}


#
# This goes backwards and produces a result for every design-instance
# which has been matched by a chosen construct: we'll get multiples, so then
# we need a 'distributed' construct - which we aren't recording yet, SO
# we will return a 'best' result for each stage in this list.
#
sub fetch_best_result_by_construct{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;

  my $pc_and_allele_pass_order = {
  'passa'=>1,
  'pass1'=>1.5,
  'pass1a'=>2,
  'pass2'=>2.5,
  'pass2.1'=>3,
  'pass2.1a'=>4,
  'pass2.2'=>5,
  'pass2.2a'=>6,
  'pass2.3'=>7,
  'pass2.3a'=>8,
  'pass3'=>9,
  'pass3a'=>10,
  #
  'passb'=>11,
  'pass1b'=>11,
  'pass2.1b'=>12,
  'pass2.2b'=>13,
  'pass2.3b'=>14,
  'pass3b'=>15,
  #
  'pass4'=>15.5,
  'pass4.1'=>16,
  'pass4.1a'=>17,
  'pass4.1b'=>18,
  'pass4.2'=>19,
  'pass4.2a'=>20,
  'pass4.2b'=>21,
  'pass5'=>21.5,
  'pass5.1'=>22,
  'pass5.1a'=>23,
  'pass5.1b'=>24,
  'pass5.2'=>25,
  'pass5.2a'=>26,
  'pass5.2b'=>27,
  'pass5.3'=>28,
  'pass5.3a'=>29,
  'pass5.3b'=>30,
  '3arm_warn'=>31,
  'fail_KAN'=>32,
  'warn_3arm_a'=>33,
  'warn_3arm_b'=>34,
  'fail'=>35
  };

  my $pg_pass_order = {
  'passa'=>1,
  'pass1'=>1,
  'pass1a'=>2,
  'pass2'=>2.5,
  'pass2.1'=>3,
  'pass2.1a'=>4,
  'pass2.2'=>5,
  'pass2.2a'=>6,
  'pass2.3'=>7,
  'pass2.3a'=>8,
  'pass3'=>9,
  'pass3a'=>10,
  #
  'passb'=>11,
  'pass1b'=>12,
  'pass2.1b'=>13,
  'pass2.2b'=>14,
  'pass2.3b'=>15,
  'pass3b'=>16,
  'pass4.1'=>17,
  'pass4.1a'=>18,
  'pass4.2'=>19,
  'pass4.2a'=>19.5,
  #
  'pass4.1b'=>20,
  'pass4.2b'=>21,
  'pass5'=>21.5,
  'pass5.1'=>22,
  'pass5.1a'=>23,
  'pass5.1b'=>24,
  'pass5.2'=>25,
  'pass5.2a'=>26,
  'pass5.2b'=>27,
  'pass5.3'=>28,
  'pass5.3a'=>29,
  'pass5.3b'=>30,
  '3arm_warn'=>31,
  'fail_KAN'=>32,
  'warn_3arm_a'=>33,
  'warn_3arm_b'=>34,
  'fail'=>35
  };

  my $gene_to_project_strings = $self->get_gene_to_project_strings($eucomm_db);

  my $eucomm_sql = 
    qq [
    select distinct
    clone_lib_dict.LIBRARY background,
    design_instance.design_instance_id,
    design_instance.plate,
    design_instance.well,
    design.design_id,
    design.design_name,
    gnm_gene.ID gene_id,
    gnm_gene.primary_name gene_name,
    e_gbg.primary_name ens_gene_build_gene_name,
    gnm_gene_build_gene.primary_name gene_build_gene_name,
    gnm_exon.primary_name exon_name,
    gnm_exon.phase,
    gnm_locus.chr_name,
    gnm_locus.chr_strand,
    gnm_gene.id,
    gene_info.sp,
    gene_info.tm
    from
    design,
    design_instance,
    design_instance_bac,
    bac,
    clone_lib_dict,
    mig.gnm_exon,
    mig.gnm_transcript_2_exon,
    mig.gnm_transcript,
    mig.gnm_gene_build_gene,
    mig.gnm_gene_build_gene e_gbg,
    mig.gnm_locus,
    mig.gnm_gene_2_gene_build_gene,
    mig.gnm_gene,
    gene_info
    where
    design_instance.design_id = design.design_id
    and plate not like 'GR%' 
    and plate != '1000'
    and plate != '2000'
    and design_instance.DESIGN_INSTANCE_ID = design_instance_bac.design_instance_id (+) 
    and design_instance_bac.BAC_CLONE_ID = bac.bac_clone_id (+) 
    and clone_lib_dict.CLONE_LIB_ID (+) = bac.CLONE_LIB_ID
    and design.start_exon_id = gnm_exon.id
    and gnm_exon.locus_id = gnm_locus.id
    and gnm_exon.ID = gnm_transcript_2_exon.exon_id
    and gnm_transcript.ID = gnm_transcript_2_exon.transcript_id
    and gnm_transcript.build_gene_id = gnm_gene_build_gene.id
    and gnm_gene_2_gene_build_gene.gene_build_gene_id = gnm_gene_build_gene.ID
    and gnm_gene_2_gene_build_gene.gene_id = gnm_gene.id
    and e_gbg.ID (+) = gnm_gene.primary_ensembl_build_gene_id
    and gene_info.gene_id (+) = gnm_gene.id
    -- and design_instance.plate = '45'
    -- and design_instance.well = 'D10'
    -- and design_instance.design_instance_id =  102186
    -- and design_instance.design_instance_id =  305
    order by plate,well,design_instance_id
  ];

  if($object_name){
    $eucomm_sql .= 
      qq [ 
        and (gnm_gene.primary_name = ?
        or gnm_exon.primary_name = ? 
        or gnm_gene_build_gene.primary_name = ? 
        or e_gbg.primary_name = ?)
      ];
  }

  my $eucomm_dbh = $eucomm_db->get_connection();
  my $eucomm_sth = $eucomm_dbh->prepare($eucomm_sql);
  my $design_results;

  if($object_name){
    $eucomm_sth->execute($object_name, $object_name, $object_name, $object_name);
  }else{
    $eucomm_sth->execute();
  }

  my $counter = 0;
  while(my $row_hash = $eucomm_sth->fetchrow_hashref){
    $counter++;
    my $di_id = $row_hash->{DESIGN_INSTANCE_ID};
    # only replace the design-instance results with another one IF it means replacing
    # a null ensembl gb id with a non-null one
    my $new_ens_gene_name = $row_hash->{ENS_GENE_BUILD_GENE_NAME};
    
    if(not exists ($design_results->{$di_id}->{DESIGN})){
      $design_results->{$di_id}->{DESIGN} = $row_hash;
    }else{
      my $existing_ens_gene_name = $design_results->{$di_id}->{DESIGN}->{ENS_GENE_BUILD_GENE_NAME};
      if((not defined $existing_ens_gene_name) && (defined $new_ens_gene_name)){
        $design_results->{$di_id}->{DESIGN} = $row_hash;
      }
    }
  }

  # Look for 'chosen' results in pc and pg stages.
  my $pc_pg_qc_sql = qq [
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.chosen_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv1.engineered_seq_id observed_engineered_seq_id,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id = qctest_run.qctest_run_id
    and clone_plate not like 'PG00036_U%'
    and construct_clone.construct_clone_id = qctest_result.construct_clone_id
    and qctest_result.is_chosen_for_engseq_in_run = sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id = sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run = 1
    and qctest_run.stage in ('post_cre','post_gateway')
    -- and sv1.design_plate = '45'
    -- and sv1.design_well = 'D10'
    -- and sv1.design_instance_id = 102186
    -- and sv1.design_instance_id = 305
    order by construct_clone.name
  ];
  
  # This fetches the qctest results, mapping to the 'observed' design-instance for each well.
  my $allele_qc_sql = qq [
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.chosen_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv1.engineered_seq_id observed_engineered_seq_id,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id = qctest_run.qctest_run_id
    and construct_clone.construct_clone_id = qctest_result.construct_clone_id
    and qctest_result.engineered_seq_id = sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id = sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run = 1
    and qctest_run.stage in ('allele')
    -- and sv1.design_plate = '45'
    -- and sv1.design_well = 'D10'
    -- and sv1.design_instance_id = 102186
    -- and sv1.design_instance_id = 305
    order by construct_clone.name
  ];

  my $main_results;

  my $qc_dbh = $qc_db->get_connection();
  my $qc_sth = $qc_dbh->prepare($pc_pg_qc_sql);
  $qc_sth->execute();

  my $counter = 0;
  
  # First gather the pc / pg results against a design-instance
  while(my $row_hash = $qc_sth->fetchrow_hashref){
    
    
    # Read the casette formula in the qctest_result to work out what the l1l2/l3l4
    # contents are. For PG...Z plates this is variable and promoter-driven. Otherwise
    # it's dependent on phase.
    my $short_casette_formula = get_short_casette_formula($row_hash);
    $row_hash->{SHORT_CASETTE_FORMULA} = $short_casette_formula;
    
    my $observed_design_instance_id = $row_hash->{OBSERVED_INSTANCE_ID};
    $main_results->{$row_hash->{QCTEST_RESULT_ID}} = $row_hash;
    my $stage = $row_hash->{STAGE}; 

    my $design_rowhash = $design_results->{$observed_design_instance_id}->{DESIGN};

    # overwrite the pass level with Tony's override, if it exists
    my $chosen_pass_level = $row_hash->{CHOSEN_STATUS};
    if($chosen_pass_level){
      $row_hash->{PASS_STATUS} = $chosen_pass_level;
    }

    print STDERR "PC/PG result: ".
      $row_hash->{CLONE_PLATE}.":".
      $row_hash->{CLONE_WELL}.":".
      $row_hash->{CLONE_NUMBER}." : ".
      $row_hash->{PASS_STATUS}."\n";
    
    if(exists($design_results->{$observed_design_instance_id}->{$stage}->{$short_casette_formula})){
      my $existing_result = $design_results->{$observed_design_instance_id}->{$stage}->{$short_casette_formula};
      my $existing_pass_level = $existing_result->{PASS_STATUS};
      if($stage eq 'post_gateway'){
        if($pg_pass_order->{$existing_pass_level} > $pg_pass_order->{$row_hash->{PASS_STATUS}}){
          $design_results->{$observed_design_instance_id}->{$stage}->{$short_casette_formula} = $row_hash;
    	  }
      }else{
        if(
	        $pc_and_allele_pass_order->{$existing_pass_level} > 
	        $pc_and_allele_pass_order->{$row_hash->{PASS_STATUS}}
     	  ){
          $design_results->{$observed_design_instance_id}->{$stage}->{$short_casette_formula} = $row_hash;
	      }
      }
    }else{
      $design_results->{$observed_design_instance_id}->{$stage}->{$short_casette_formula} = $row_hash;
    }
  }
  
  # Now accumulate the ES cell results
  my $qc_sth = $qc_dbh->prepare($allele_qc_sql);
  $qc_sth->execute();
  while(my $row_hash = $qc_sth->fetchrow_hashref){
    
    # Either comes out as 'pll1l2:pll3l4' or 'prl1l2:prl3l4' depending on which plate we're talking about.
    my $short_casette_formula = get_short_casette_formula($row_hash);
    $row_hash->{SHORT_CASETTE_FORMULA} = $short_casette_formula;
    
    my $expected_design_instance_id = $row_hash->{EXPECTED_INSTANCE_ID};
    $main_results->{$row_hash->{QCTEST_RESULT_ID}} = $row_hash;
    my $stage = $row_hash->{STAGE};

    my $design_rowhash = $design_results->{$expected_design_instance_id}->{DESIGN};
    
    #print STDERR "ES Cell result: ".
    #$row_hash->{CLONE_PLATE}.":".
    #$row_hash->{CLONE_WELL}.":".
    #$row_hash->{CLONE_NUMBER}." : ".
    #$row_hash->{PASS_STATUS}."\n";

    # overwrite the pass level with Tony's override, if it exists
    my $chosen_pass_level = $row_hash->{CHOSEN_STATUS};
    if($chosen_pass_level){
      $row_hash->{PASS_STATUS} = $chosen_pass_level;
    }

    if(exists($design_results->{$expected_design_instance_id}->{$stage}->{$short_casette_formula})){
      my $existing_result = $design_results->{$expected_design_instance_id}->{$stage}->{$short_casette_formula};
      my $existing_pass_level = $existing_result->{PASS_STATUS};
      #print STDERR " Existing result : $existing_pass_level\n";
      if(
        $pc_and_allele_pass_order->{$existing_pass_level} > 
        $pc_and_allele_pass_order->{$row_hash->{PASS_STATUS}}
      ){
        print STDERR "Replacing \n";
        $design_results->{$expected_design_instance_id}->{$stage}->{$short_casette_formula} = $row_hash;
      }
    }else{
      print STDERR "New \n";
      $design_results->{$expected_design_instance_id}->{$stage}->{$short_casette_formula} = $row_hash;
    }
  }
  
  #
  # Now you are left with design-results, and stage-by-stage best pass levels
  # for each design-instance. Now you want to emit these as QCTestResultList objects
  # (one object per qc-test-result).
  #
  my @return_list;
  foreach my $design_instance_id (keys %{$design_results}){
    my $design_row = $design_results->{$design_instance_id}->{DESIGN};
    my $make_empty_design = 1;

    if(exists($design_results->{$design_instance_id}->{post_cre})){
      my @pc_rows = values %{$design_results->{$design_instance_id}->{post_cre}};
      foreach my $pc_row(@pc_rows){
        push @return_list, $self->make_qcresultlist_from_resultsets($pc_row, $design_row, $gene_to_project_strings);
      }
      $make_empty_design = 0;
    }

    if(exists($design_results->{$design_instance_id}->{post_gateway})){
      my @pg_rows = values %{$design_results->{$design_instance_id}->{post_gateway}};
      foreach my $pg_row(@pg_rows){
        push @return_list, $self->make_qcresultlist_from_resultsets($pg_row, $design_row, $gene_to_project_strings);
      }
      $make_empty_design = 0;
    }

    if(exists($design_results->{$design_instance_id}->{allele})){
      my @allele_rows = values %{$design_results->{$design_instance_id}->{allele}};
      foreach my $allele_row (@allele_rows){
        push @return_list, $self->make_qcresultlist_from_resultsets($allele_row, $design_row, $gene_to_project_strings);
      }
      $make_empty_design = 0;
    }

    if($make_empty_design){
      push @return_list, $self->make_qcresultlist_from_resultsets(undef, $design_row, $gene_to_project_strings);
    }
  }

  $qc_db->disconnect();
  $eucomm_db->disconnect();

  return \@return_list;
}

sub get_gene_to_project_strings{
  my $self = shift;
  my $eucomm_db = shift;
  my $arq_sql = qq[
    select gene_id, arq_allele_request_source_dict.name, arq_allele_request_source_dict.ID
    from 
    mig.arq_allele_request, 
    mig.arq_allele_request_source_dict
    where 
    arq_allele_request.REQUEST_SOURCE_DICT_ID = arq_allele_request_source_dict.ID
    order by gene_id, name
  ];
  my $sth = $eucomm_db->get_connection->prepare($arq_sql);
  $sth->execute();

  my $projecthash = {
    5 => 'EUCOMM',
    7 => 'Int EUCOMM',
    8 => 'Ext EUCOMM',
    15 => 'Int EUCOMM:MGP',
    9  => 'KOMP',
    10  => 'Int KOMP',
    11  => 'Ext KOMP',
    16 => 'Ext KOMP:MGP'
  };

  my $genehash;
  my $return_hash;

  while(my $row = $sth->fetchrow_hashref()){
    my $gene_id = $row->{GENE_ID};
    my $sourceid = $row->{ID};
    my $source_string = $projecthash->{$sourceid};
    if(!$source_string or (length($source_string)<=0)){
      $source_string = 'OTHER';
    }
    $genehash->{$gene_id}->{$source_string} = 1;
  }

  foreach my $gene_id (keys %$genehash){
    my $combined_string;
    foreach my $source_string(sort keys %{$genehash->{$gene_id}}){
      if(!$combined_string){
        $combined_string = $source_string;
      }else{
        $combined_string = $combined_string.":".$source_string;
      }
    }
    $return_hash->{$gene_id} = $combined_string;
  }
  return $return_hash;
}

sub fetch_all_public_allele_results{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;
  my $qc_sql = qq[
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id=qctest_run.qctest_run_id
    and construct_clone.construct_clone_id=qctest_result.construct_clone_id
    and qctest_result.engineered_seq_id =sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id=sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run=1
    and qctest_run.stage='allele'
    and qctest_run.is_public=1
    order by construct_clone.name
  ];

  return $self->fetch_all_qctest_results($qc_db, $eucomm_db, $object_name, $qc_sql);
}

sub fetch_all_public_chosen_allele_results{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;
  my $qc_sql = qq[
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id=qctest_run.qctest_run_id
    and construct_clone.construct_clone_id=qctest_result.construct_clone_id
    --and qctest_result.is_chosen_for_engseq_in_run=sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id=sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run=1
    and qctest_run.stage='allele'
    and qctest_run.is_public=1
    order by construct_clone.name
  ];

  return $self->fetch_all_qctest_results($qc_db, $eucomm_db, $object_name, $qc_sql);
}

sub fetch_all_chosen{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;

  my $qc_sql = qq [
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id = qctest_run.qctest_run_id
    and construct_clone.construct_clone_id = qctest_result.construct_clone_id
    and qctest_result.is_chosen_for_engseq_in_run = sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id = sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run = 1
    order by construct_clone.name
  ];

  return $self->fetch_all_qctest_results($qc_db, $eucomm_db, $object_name, $qc_sql);
}

sub fetch_all_best{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;

  my $qc_sql = qq [
    select
    qctest_result.qctest_result_id,
    construct_clone.plate clone_plate,
    construct_clone.well clone_well,
    construct_clone.clone_number,
    qctest_result.pass_status,
    qctest_result.qctest_result_id,
    qctest_result.is_best_for_engseq_in_run,
    qctest_result.is_chosen_for_engseq_in_run,
    sv1.design_plate observed_plate,
    sv1.design_well observed_well,
    sv1.design_instance_id observed_instance_id,
    sv1.cassette_formula observed_casette_formula,
    sv2.design_plate expected_plate,
    sv2.design_well expected_well,
    sv2.design_instance_id expected_instance_id,
    qctest_result.is_valid,
    qctest_run.is_public,
    qctest_run.stage
    from
    qctest_run,
    construct_clone,
    synthetic_vector sv1,
    synthetic_vector sv2,
    qctest_result
    where
    qctest_result.qctest_run_id = qctest_run.qctest_run_id
    and construct_clone.construct_clone_id = qctest_result.construct_clone_id
    and qctest_result.engineered_seq_id = sv1.engineered_seq_id
    and qctest_result.expected_engineered_seq_id = sv2.engineered_seq_id
    and qctest_result.is_best_for_construct_in_run = 1
    and is_best_for_engseq_in_run = 1
    order by construct_clone.name
  ];


  return $self->fetch_all_qctest_results($qc_db, $eucomm_db, $object_name, $qc_sql);
}

sub fetch_all_for_gene{
  my $self = shift;
  my $gene_or_exon_name = shift;
}

sub fetch_all_qctest_results{
  my $self = shift;
  my $qc_db = shift;
  my $eucomm_db = shift;
  my $object_name = shift;
  my $qc_sql = shift;

  my $eucomm_sql = 
    qq [
      select
      design_instance.design_instance_id,
      design_instance.plate,
      design_instance.well,
      design.design_id,
      design.design_name,
      gnm_gene.ID gene_id,
      gnm_gene.primary_name gene_name,
      e_gbg.primary_name ens_gene_build_gene_name,
      gnm_gene_build_gene.primary_name gene_build_gene_name,
      gnm_exon.primary_name exon_name,
      gnm_exon.phase,
      gnm_locus.chr_name,
      gnm_locus.chr_strand,
      gnm_gene.id,
      gene_info.sp,
      gene_info.tm
      from 
      design, 
      design_instance,
      mig.gnm_exon,
      mig.gnm_transcript_2_exon,
      mig.gnm_transcript,
      mig.gnm_gene_build_gene,
      mig.gnm_gene_build_gene e_gbg,
      mig.gnm_locus,
      mig.gnm_gene_2_gene_build_gene,
      mig.gnm_gene,
      gene_info
      where 
      design_instance.design_id = design.design_id
      and design.start_exon_id = gnm_exon.id
      and gnm_exon.locus_id = gnm_locus.id
      and gnm_exon.ID = gnm_transcript_2_exon.exon_id
      and gnm_transcript.ID = gnm_transcript_2_exon.transcript_id
      and gnm_transcript.build_gene_id = gnm_gene_build_gene.id
      and gnm_gene_2_gene_build_gene.gene_build_gene_id = gnm_gene_build_gene.ID
      and gnm_gene_2_gene_build_gene.gene_id = gnm_gene.id
      and e_gbg.ID = gnm_gene.primary_ensembl_build_gene_id
      and gene_info.gene_id (+) = gnm_gene.id
      order by plate,well,design_instance_id
    ];

  if($object_name){
    $eucomm_sql .= 
      qq [ 
        and (gnm_gene.primary_name = ?
        or gnm_exon.primary_name = ? 
        or gnm_gene_build_gene.primary_name = ? 
        or e_gbg.primary_name = ?)
      ];
  }

  my $main_results;
  my $design_results;

  my $qc_dbh = $qc_db->get_connection();

  my $qc_sth = $qc_dbh->prepare($qc_sql);
  $qc_sth->execute();
  my $counter = 0;
  while(my $row_hash = $qc_sth->fetchrow_hashref){
    $main_results->{$row_hash->{QCTEST_RESULT_ID}} = $row_hash;
  }

  my $eucomm_dbh = $eucomm_db->get_connection();
  my $eucomm_sth = $eucomm_dbh->prepare($eucomm_sql);

  if($object_name){
    $eucomm_sth->execute($object_name, $object_name, $object_name, $object_name);
  }else{
    $eucomm_sth->execute();
  }
  $counter = 0;
  while(my $row_hash = $eucomm_sth->fetchrow_hashref){
    $counter++;
    $design_results->{$row_hash->{DESIGN_INSTANCE_ID}} = $row_hash;
  }

  $qc_db->disconnect();
  $eucomm_db->disconnect();

  return $self->map_resultsets_to_object($main_results, $design_results);
}

#
# This is deliberately NOT the mapRow command, though it does the same thing, 
# doing an in-memory join between the results from two queries, from two 
# different databases
#
sub map_resultsets_to_object{
  my $self = shift;
  my $main_results = shift;
  my $design_results = shift;
  my $return_array;


  foreach my $main_result(values %$main_results){
    my $return_object = TargetedTrap::IVSA::QCTestResultList->new();
    #
    #This is critical - we join onto design results by the OBSERVED id (ie the thing actually in the well).
    #
    my $design_instance_id = $main_result->{OBSERVED_INSTANCE_ID};
    my $design_result;
    $design_result = $design_results->{$design_instance_id};
    $return_object->qctest_result_id($main_result->{QCTEST_RESULT_ID});
    $return_object->clone_plate($main_result->{CLONE_PLATE});
    $return_object->clone_well($main_result->{CLONE_WELL});
    $return_object->clone_number($main_result->{CLONE_NUMBER});
    my $clone_name = $return_object->clone_plate."_".$return_object->clone_well."_".$return_object->clone_number;
    $return_object->clone_name($clone_name);

    $return_object->pass_status($main_result->{PASS_STATUS});
    $return_object->is_best_for_engseq_in_run($main_result->{IS_BEST_FOR_ENGSEQ_IN_RUN});
    $return_object->is_chosen_for_engseq_in_run($main_result->{IS_CHOSEN_FOR_ENGSEQ_IN_RUN});
    $return_object->expected_plate($main_result->{EXPECTED_PLATE});
    $return_object->expected_well($main_result->{EXPECTED_WELL});
    $return_object->expected_instance_id($main_result->{EXPECTED_INSTANCE_ID});
    $return_object->found_plate($main_result->{OBSERVED_PLATE});
    $return_object->found_well($main_result->{OBSERVED_WELL});
    $return_object->found_instance_id($main_result->{OBSERVED_INSTANCE_ID});
    $return_object->casette_formula($main_result->{OBSERVED_CASETTE_FORMULA});
    $return_object->is_public($main_result->{IS_VALID});
    $return_object->is_valid($main_result->{IS_PUBLIC});
    $return_object->stage($main_result->{STAGE});
    if(not exists($design_results->{$design_instance_id})){
      print STDERR 
        "There is no design-instance information in eucomm_vector ".
        "for design_instance_id: $design_instance_id\n";
    }else{
      $return_object->gene_id($design_result->{GENE_ID});
      $return_object->design_instance_id($design_result->{DESIGN_INSTANCE_ID});
      $return_object->plate($design_result->{PLATE});
      $return_object->well($design_result->{WELL});
      $return_object->design_name($design_result->{DESIGN_NAME});
      $return_object->design_id($design_result->{DESIGN_ID});
      $return_object->gene_name($design_result->{GENE_NAME});
      $return_object->ens_gene_build_gene_name($design_result->{ENS_GENE_BUILD_GENE_NAME});
      $return_object->exon_name($design_result->{EXON_NAME});
      $return_object->phase($design_result->{PHASE});
      $return_object->gene_build_gene_name($design_result->{GENE_BUILD_GENE_NAME});
      $return_object->phase($design_result->{PHASE});
      $return_object->chr_name($design_result->{CHR_NAME});
      $return_object->chr_strand($design_result->{CHR_STRAND});
      $return_object->sp($design_result->{SP});
      $return_object->tm($design_result->{TM});
    }

    push @{$return_array},$return_object;
  }
  return $return_array;
}

sub make_qcresultlist_from_resultsets{
  my $self = shift;
  my $main_result = shift;
  my $design_result = shift;
  my $project_hash = shift;
  if(!($main_result || $design_result)){
    die "cant create this list object without either/both qc and design result\n";
  }

  my $return_object = TargetedTrap::IVSA::QCTestResultList->new();

  if($main_result){
    $return_object->observed_engineered_seq_id($main_result->{OBSERVED_ENGINEERED_SEQ_ID});
    $return_object->qctest_result_id($main_result->{QCTEST_RESULT_ID});
    $return_object->clone_plate($main_result->{CLONE_PLATE});
    $return_object->clone_well($main_result->{CLONE_WELL});
    $return_object->short_casette_formula($main_result->{SHORT_CASETTE_FORMULA});
    $return_object->clone_number($main_result->{CLONE_NUMBER});
    if($return_object->clone_number){
      my $clone_name = $return_object->clone_plate."_".$return_object->clone_well."_".$return_object->clone_number;
      $return_object->clone_name($clone_name);
    }else{
      my $clone_name = $return_object->clone_plate."_".$return_object->clone_well;
      $return_object->clone_name($clone_name);
    }
    $return_object->pass_status($main_result->{PASS_STATUS});
    $return_object->is_best_for_engseq_in_run($main_result->{IS_BEST_FOR_ENGSEQ_IN_RUN});
    $return_object->is_chosen_for_engseq_in_run($main_result->{IS_CHOSEN_FOR_ENGSEQ_IN_RUN});
    $return_object->expected_plate($main_result->{EXPECTED_PLATE});
    $return_object->expected_well($main_result->{EXPECTED_WELL});
    $return_object->expected_instance_id($main_result->{EXPECTED_INSTANCE_ID});
    $return_object->found_plate($main_result->{OBSERVED_PLATE});
    $return_object->found_well($main_result->{OBSERVED_WELL});
    $return_object->found_instance_id($main_result->{OBSERVED_INSTANCE_ID});
    $return_object->casette_formula($main_result->{OBSERVED_CASETTE_FORMULA});
    $return_object->is_public($main_result->{IS_VALID});
    $return_object->is_valid($main_result->{IS_PUBLIC});
    $return_object->stage($main_result->{STAGE});
  }

  if($design_result){
    $return_object->background($design_result->{BACKGROUND});
    $return_object->gene_id($design_result->{GENE_ID});
    $return_object->design_id($design_result->{DESIGN_ID});
    $return_object->design_instance_id($design_result->{DESIGN_INSTANCE_ID});
    $return_object->plate($design_result->{PLATE});
    $return_object->well($design_result->{WELL});
    $return_object->design_name($design_result->{DESIGN_NAME});
    $return_object->design_id($design_result->{DESIGN_ID});
    $return_object->gene_name($design_result->{GENE_NAME});
    $return_object->ens_gene_build_gene_name($design_result->{ENS_GENE_BUILD_GENE_NAME});
    $return_object->exon_name($design_result->{EXON_NAME});
    $return_object->phase($design_result->{PHASE});
    $return_object->gene_build_gene_name($design_result->{GENE_BUILD_GENE_NAME});
    $return_object->phase($design_result->{PHASE});
    $return_object->chr_name($design_result->{CHR_NAME});
    $return_object->chr_strand($design_result->{CHR_STRAND});
    $return_object->sp($design_result->{SP});
    $return_object->tm($design_result->{TM});
    my $project_string = $project_hash->{$return_object->gene_id};
    $return_object->project($project_string);
  }
  return $return_object;
}

sub description{
  my $self = shift;
  return 
    $self->gene_name.",".
    $self->gene_build_gene_name.",".
    $self->exon_name.",".
    $self->stage.",".
    $self->pass_status.",".
    $self->plate.",".
    $self->well.",".
    $self->clone_plate."_".
    $self->clone_well."_".
    $self->clone_number.",".
    $self->is_best_for_engseq_in_run.",".
    $self->is_chosen_for_engseq_in_run;
}

# I know that if a plate has a 'PG00023_Z' designation, that it must be promoter-containing.
sub get_short_casette_formula{
  my $qc_row = shift;
  my $l1l2 = undef;
  my $l3l4 = "dta:kan";

  # qctest_result.qctest_result_id,
  #  construct_clone.plate clone_plate,
  #  construct_clone.well clone_well,
  #  construct_clone.clone_number,
  #  qctest_result.pass_status,
  #  qctest_result.chosen_status,
  #  qctest_result.qctest_result_id,
  #  qctest_result.is_best_for_engseq_in_run,
  #  qctest_result.is_chosen_for_engseq_in_run,
  #  sv1.design_plate observed_plate,
  #  sv1.design_well observed_well,
  #  sv1.design_instance_id observed_instance_id,
  #  sv1.cassette_formula observed_casette_formula,
  #  sv1.engineered_seq_id observed_engineered_seq_id,
  #  sv2.design_plate expected_plate,
  #  sv2.design_well expected_well,
  #  sv2.design_instance_id expected_instance_id,
  #  qctest_result.is_valid,
  #  qctest_run.is_public,
  #  qctest_run.stage

  if($qc_row->{STAGE} eq 'post_cre'){
    return "PC";
  }
  
  my $clone_plate = $qc_row->{CLONE_PLATE};

  my $long_casette_formula = $qc_row->{OBSERVED_CASETTE_FORMULA};
  if($long_casette_formula =~ /.*l1l2_(\w\w\d),.*/){
    $l1l2=$1;
  }elsif($long_casette_formula =~ /.*l1l2_(\w\w\w),.*/){
    $l1l2=$1;
  }else{
    die "cant interpret casette formula $long_casette_formula\n";
  }
  
  $l3l4 = 'dta:kan';
  
  if($qc_row->{CLONE_PLATE} =~ /[Z,Y,X,W,V]/){


    $l1l2 = '???';
    $l3l4 = '???';

    if(($clone_plate =~ /36/) && ($clone_plate =~ /[YZ]/)){
      $l1l2 = 'L1L2_Pgk_PM';
    }else{
      $l1l2 = 'L1L2_Bact_P';
    }

    if($clone_plate =~ /36/){
      if($clone_plate =~ /Z/){
        $l3l4 = 'L3L4_pD223_DTA_spec';
      }elsif($clone_plate =~ /Y/){
        $l3l4 = 'L4L3_pD223_DTA_-T_spec';
      }elsif($clone_plate =~ /X/){
        $l3l4 = 'L3L4_pD223_DTA_spec';
      }elsif($clone_plate =~ /W/){
        $l3l4 = 'L3L4_pD223_DTA_spec';
      }
    }

    if(
      (($clone_plate =~ /57/) || ($clone_plate =~ /58/) || ($clone_plate =~ /59/))
      && (($clone_plate =~ /Z/) || ($clone_plate =~ /PRPGD/))
    ){
      $l3l4 = 'L3L4_pD223_DTA_spec';
    }elsif(
      ( 
       (($clone_plate =~ /31/) || ($clone_plate =~ /41/) || ($clone_plate =~ /52/)|| ($clone_plate =~ /55/)||($clone_plate =~ /63/))
       && (($clone_plate =~ /Z/)||($clone_plate =~ /PRPGD/))
      )
      || 
      (($clone_plate =~ /45/) && (($clone_plate =~ /Y/)|| ($clone_plate =~ /PRPGD/)))
    ){
      $l3l4 = 'L4L3_pD223_DTA_spec';
    }elsif(
      (($clone_plate =~ /48/) || ($clone_plate =~ /49/))
      && (($clone_plate =~ /Y/)||($clone_plate =~ /Z/) || ($clone_plate =~ /PRPGD/))
    ){
      $l3l4 = 'R3R4_pBR_amp';
    }
  }
  
  if($qc_row->{CLONE_PLATE} =~ /EPD/){
    if(
      ($qc_row->{CLONE_PLATE} =~ /73/) ||
      ($qc_row->{CLONE_PLATE} =~ /74/) ||
      ($qc_row->{CLONE_PLATE} =~ /75/) ||
      ($qc_row->{CLONE_PLATE} =~ /76/) ||
      ($qc_row->{CLONE_PLATE} =~ /77/) ||
      ($qc_row->{CLONE_PLATE} =~ /78/) || 
      ($qc_row->{CLONE_PLATE} =~ /79/) ||
      ($qc_row->{CLONE_PLATE} =~ /81/) ||
      ($qc_row->{CLONE_PLATE} =~ /82/) ||
      ($qc_row->{CLONE_PLATE} =~ /83/) ||
      ($qc_row->{CLONE_PLATE} =~ /84/) ||
      ($qc_row->{CLONE_PLATE} =~ /85/) ||
      ($qc_row->{CLONE_PLATE} =~ /86/) ||
      ($qc_row->{CLONE_PLATE} =~ /88/) ||
      ($qc_row->{CLONE_PLATE} =~ /90/) ||
      ($qc_row->{CLONE_PLATE} =~ /92/)
    ){
      $l1l2 = 'prl1l2';
      $l3l4 = 'prl3l4';
    }else{
      $l1l2 = 'pll1l2';
      $l3l4 = 'pll3l4';
    }
  }
  
  return "${l1l2}:${l3l4}";
}

###
# Get/sets
#
#

sub qctest_result_id {
  my $self = shift;
  $self->{'qctest_result_id'}  = shift if (@_);
  return $self->{'qctest_result_id'};
}
sub clone_name {
  my $self = shift;
  $self->{'clone_name'}  = shift if (@_);
  return $self->{'clone_name'};
}
sub clone_plate {
  my $self = shift;
  $self->{'clone_plate'}  = shift if (@_);
  return $self->{'clone_plate'};
}
sub clone_well {
  my $self = shift;
  $self->{'clone_well'}  = shift if (@_);
  return $self->{'clone_well'};
}
sub plate {
  my $self = shift;
  $self->{'plate'}  = shift if (@_);
  return $self->{'plate'};
}
sub well {
  my $self = shift;
  $self->{'well'}  = shift if (@_);
  return $self->{'well'};
}
sub clone_number {
  my $self = shift;
  $self->{'clone_number'}  = shift if (@_);
  return $self->{'clone_number'};
}
sub pass_status {
  my $self = shift;
  $self->{'pass_status'}  = shift if (@_);
  return $self->{'pass_status'};
}
sub is_best_for_engseq_in_run {
  my $self = shift;
  $self->{'is_best_for_engseq_in_run'}  = shift if (@_);
  return $self->{'is_best_for_engseq_in_run'};
}
sub is_chosen_for_engseq_in_run {
  my $self = shift;
  $self->{'is_chosen_for_engseq_in_run'}  = shift if (@_);
  return $self->{'is_chosen_for_engseq_in_run'};
}
sub expected_plate {
  my $self = shift;
  $self->{'expected_plate'}  = shift if (@_);
  return $self->{'expected_plate'};
}
sub expected_well {
  my $self = shift;
  $self->{'expected_well'}  = shift if (@_);
  return $self->{'expected_well'};
}
sub found_instance_id {
  my $self = shift;
  $self->{'found_instance_id'}  = shift if (@_);
  return $self->{'found_instance_id'};
}
sub expected_instance_id {
  my $self = shift;
  $self->{'expected_instance_id'}  = shift if (@_);
  return $self->{'expected_instance_id'};
}
sub found_plate {
  my $self = shift;
  $self->{'found_plate'}  = shift if (@_);
  return $self->{'found_plate'};
}
sub found_well {
  my $self = shift;
  $self->{'found_well'}  = shift if (@_);
  return $self->{'found_well'};
}
sub is_public {
  my $self = shift;
  $self->{'is_public'}  = shift if (@_);
  return $self->{'is_public'};
}
sub is_valid {
  my $self = shift;
  $self->{'is_valid'}  = shift if (@_);
  return $self->{'is_valid'};
}
sub stage {
  my $self = shift;
  $self->{'stage'}  = shift if (@_);
  return $self->{'stage'};
}
sub casette_formula {
  my $self = shift;
  $self->{'casette_formula'}  = shift if (@_);
  return $self->{'casette_formula'};
}
sub design_instance_id {
  my $self = shift;
  $self->{'design_instance_id'}  = shift if (@_);
  return $self->{'design_instance_id'};
}
sub plate {
  my $self = shift;
  $self->{'plate'}  = shift if (@_);
  return $self->{'plate'};
}
sub well {
  my $self = shift;
  $self->{'well'}  = shift if (@_);
  return $self->{'well'};
}
sub design_id {
  my $self = shift;
  $self->{'design_id'}  = shift if (@_);
  return $self->{'design_id'};
}
sub gene_id {
  my $self = shift;
  $self->{'gene_id'}  = shift if (@_);
  return $self->{'gene_id'};
}
sub gene_name {
  my $self = shift;
  $self->{'gene_name'}  = shift if (@_);
  return $self->{'gene_name'};
}
sub ens_gene_build_gene_name {
  my $self = shift;
  $self->{'ens_gene_build_gene_name'}  = shift if (@_);
  return $self->{'ens_gene_build_gene_name'};
}
sub gene_build_gene_name {
  my $self = shift;
  $self->{'gene_build_gene_name'}  = shift if (@_);
  return $self->{'gene_build_gene_name'};
}
sub exon_name {
  my $self = shift;
  $self->{'exon_name'}  = shift if (@_);
  return $self->{'exon_name'};
}
sub phase {
  my $self = shift;
  $self->{'phase'}  = shift if (@_);
  return $self->{'phase'};
}
sub chr_name {
  my $self = shift;
  $self->{'chr_name'}  = shift if (@_);
  return $self->{'chr_name'};
}
sub chr_strand {
  my $self = shift;
  $self->{'chr_strand'}  = shift if (@_);
  return $self->{'chr_strand'};
}
sub sp {
  my $self = shift;
  $self->{'sp'}  = shift if (@_);
  return $self->{'sp'};
}
sub tm {
  my $self = shift;
  $self->{'tm'}  = shift if (@_);
  return $self->{'tm'};
}
sub design_name {
  my $self = shift;
  $self->{'design_name'}  = shift if (@_);
  return $self->{'design_name'};
}
sub background {
  my $self = shift;
  $self->{'background'}  = shift if (@_);
  return $self->{'background'};
}
sub project{
  my $self = shift;
  $self->{'project'}  = shift if (@_);
  return $self->{'project'};
}
sub observed_engineered_seq_id{
  my $self = shift;
  $self->{'observed_engineered_seq_id'}  = shift if (@_);
  return $self->{'observed_engineered_seq_id'};
}
sub short_casette_formula{
  my $self = shift;
  $self->{'short_casette_formula'}  = shift if (@_);
  return $self->{'short_casette_formula'};
}

1;
