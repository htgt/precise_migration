### TargetedTrap::IVSA::Web
#
# Copyright 2005 Genome Research Limited (GRL)
#
# Maintained by Lucy Stebbings (las@sanger.ac.uk) 
# Author las
=head1 NAME


=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 CONTACT

  Contact Lucy Stebbings on implemetation/design detail: las@sanger.ac.uk

=head1 APPENDIX


=cut

package TargetedTrap::IVSA::Web;

use strict;
use SqlEngine2;
use Carp;

# test db
use constant QC_LOGIN_T => 'qc_t';
# live db
use constant QC_LOGIN => 'qc';
use constant DESIGN_LOGIN => 'eucomm_vector';

use constant INTWEB => 1; # a switch to tell scripts whether they are on Intweb or not
                          # on external site, set this to 0 instead


#################################################
# Class methods
#################################################


#################################################
# Instance methods
#################################################

sub new
{
    my $class = shift;
    my %args = @_;

    my $self = {};

    $self->{qctest_run_id} = '';
    $self->{design_instance_plate} = ''; # don't use any more
    $self->{design_instance_plates} = {}; # can be more than one design plate associated with a run
    $self->{results} = [];
    $self->{qc_results} = {};
    $self->{design_results} = {};

    $self->{-qc_login} = $args{-qc_login};
    $self->{-design_login} = $args{-design_login};
    
    $self->{se} = new SqlEngine2();
    $self->{dbh} = SqlEngine2::getDbh($self->{-qc_login});

    $self->{se2} = new SqlEngine2();
    $self->{dbh2} = SqlEngine2::getDbh($self->{-design_login});

    bless $self, $class;
    return $self;
}

# getter/setter
sub qctest_run_id {
  my $self = shift;
  my $run = shift if(@_);
  if ($run) {
      $self->{'qctest_run_id'} = $run;
      &clear_results($self);
      &get_construct_list_qc($self);
  }
  return $self->{'qctest_run_id'};
}

# getter/setter
sub design_instance_plate {
  my $self = shift;
  my $plate = shift if(@_);
  if ($plate) {
      $self->{'design_instance_plate'} = $plate;
      $self->{'design_instance_plates'}->{$plate} = 1;
      &get_construct_list_designs($self);
  }
  return $self->{'design_instance_plate'};
}

# getter/setter. takes/returns a hash of plates
sub design_instance_plates {
  my $self = shift;
  my $plates = shift if(@_);
  if ($plates) {
      $self->{'design_instance_plates'} = $plates;
      &get_construct_list_designs($self);
  }
  return $self->{'design_instance_plates'};
}

sub get_construct_list_qc {
    my $self = shift;

#    my $plate;
    my $plates = {};

    $self->{qc_results} = {};

    my ($results) = $self->{se}->getAll('Web::get_construct_list_qc', [$self->{'qctest_run_id'}], $self->{dbh});
    foreach my $row(@$results) {
	my $construct = $row->[0];
	$self->{qc_results}->{$construct}->{construct_well} = $row->[1];
	$self->{qc_results}->{$construct}->{pass_status} = $row->[2];
	$self->{qc_results}->{$construct}->{result_id} = $row->[3];
	$self->{qc_results}->{$construct}->{is_best_for_engseq_in_run} = $row->[4];
	$self->{qc_results}->{$construct}->{is_chosen_for_engseq_in_run} = $row->[5];
	$self->{qc_results}->{$construct}->{distribute_for_engseq} = $row->[6];
	my $primer_is_valid = $row->[8];
	if ($primer_is_valid) { $self->{qc_results}->{$construct}->{primers}->{$row->[7]} = $row->[7]; }
	$self->{qc_results}->{$construct}->{plate} = $row->[9];
	$self->{qc_results}->{$construct}->{well} = $row->[10];
	$self->{qc_results}->{$construct}->{design_instance_id} = $row->[11];
	$self->{qc_results}->{$construct}->{expected_plate} = $row->[12];
	$self->{qc_results}->{$construct}->{expected_well} = $row->[13];
	$self->{qc_results}->{$construct}->{expected_design_instance_id} = $row->[14];
	$self->{qc_results}->{$construct}->{is_valid} = $row->[15];
	$self->{qc_results}->{$construct}->{is_public} = $row->[16];
	$self->{qc_results}->{$construct}->{stage} = $row->[17];
	$self->{qc_results}->{$construct}->{formula} = $row->[18];
	$self->{qc_results}->{$construct}->{chosen_status} = $row->[19];
	$self->{qc_results}->{$construct}->{result_comment} = $row->[20];
# 	unless ($plate) { $plate = $self->{qc_results}->{$construct}->{plate}; }
	my $plate = $self->{qc_results}->{$construct}->{plate};
 	$plates->{$plate} = 1;
    }
    if (scalar(keys %$plates)) { &design_instance_plates($self, $plates); }
  
    return $self;
}

sub get_construct_list_designs {
    my $self = shift;

    $self->{design_results} = {};

    foreach my $plate(keys %{$self->{'design_instance_plates'}}) {

	my ($results) = $self->{se2}->getAll('Web::get_construct_list_designs', [$plate], $self->{dbh2});

	foreach my $row(@$results) {
	    my $design_instance_id = $row->[0];
	    $self->{design_results}->{$design_instance_id}->{well} = $row->[1];
	    $self->{design_results}->{$design_instance_id}->{design_id} = $row->[2];
	    $self->{design_results}->{$design_instance_id}->{design_name} = $row->[3];
	    $self->{design_results}->{$design_instance_id}->{gene} = $row->[4];
	    $self->{design_results}->{$design_instance_id}->{exon} = $row->[5];
	    $self->{design_results}->{$design_instance_id}->{chr} = $row->[6];
	    $self->{design_results}->{$design_instance_id}->{strand} = $row->[7];
	    $self->{design_results}->{$design_instance_id}->{sp} = $row->[8];
	    $self->{design_results}->{$design_instance_id}->{tm} = $row->[9];
	}
    }

    return $self;
}

sub clear_results {
    my $self = shift;
    $self->{results} = [];
}

sub get_construct_list {
    my $self = shift;

    my $counter = 1;
    unless (@{$self->{results}}) {
	foreach my $construct(sort {$a cmp $b} keys %{$self->{qc_results}}) {

	    my $expected_design_instance_id = $self->{qc_results}->{$construct}->{expected_design_instance_id};
	    my $design_instance_id = $self->{qc_results}->{$construct}->{design_instance_id};

	    my @row = ();
	    # [0]
	    push @row, $counter;
	    # [1]
	    push @row, $construct;
	    # [2]
	    push @row, ($self->{qc_results}->{$construct}->{expected_plate} 
			. $self->{qc_results}->{$construct}->{expected_well} 
			. "_"
			. $self->{design_results}->{$expected_design_instance_id}->{design_id});
	    # [3]
	    push @row, ($self->{qc_results}->{$construct}->{plate} 
			. $self->{qc_results}->{$construct}->{well} 
			. "_"
			. $self->{design_results}->{$design_instance_id}->{design_id});
	    # [4]
	    push @row, $self->{design_results}->{$design_instance_id}->{gene};
	    # [5]
	    push @row, $self->{design_results}->{$design_instance_id}->{exon};
	    # [6]
	    push @row, $self->{design_results}->{$design_instance_id}->{chr};
	    # [7]
	    push @row, $self->{design_results}->{$design_instance_id}->{strand};

	    # [8]
	    if (($self->{design_results}->{$design_instance_id}->{sp} == 1) &&
	        ($self->{design_results}->{$design_instance_id}->{tm} == 1)) { push @row, 'SP/TM'; }
	    elsif ($self->{design_results}->{$design_instance_id}->{sp} == 1) { push @row, 'SP'; }
	    elsif ($self->{design_results}->{$design_instance_id}->{tm} == 1) { push @row, 'TM'; }
	    else { push @row, ''; }

	    # [9]
	    if ($self->{qc_results}->{$construct}->{is_best_for_engseq_in_run}) { push @row, $self->{qc_results}->{$construct}->{well}; }
	    else { push @row, ''; }

	    # [10]
	    push @row, $self->{qc_results}->{$construct}->{pass_status};

	    # [11]
	    if ($row[2] eq $row[3]) { push @row, ''; }
	    else { push @row, 'not as expected'; }


	    # [12]
	    if ($self->{qc_results}->{$construct}->{primers}) { 
		my $primers = &order_primers($self->{qc_results}->{$construct}->{primers});
		push @row, (join " ", @$primers); 
	    }
	    else {push @row, ''; }

	    # [13]
	    push @row, $self->{qc_results}->{$construct}->{is_valid};
	    # [14]
	    push @row, $self->{qc_results}->{$construct}->{is_public};
	    # [15]
	    push @row, $self->{qc_results}->{$construct}->{stage};
	    # [16]
	    push @row, $self->{qc_results}->{$construct}->{result_id};
	    # [17]
	    push @row, $self->{qc_results}->{$construct}->{formula};

	    # [18]
	    if ($self->{qc_results}->{$construct}->{is_chosen_for_engseq_in_run}) { push @row, $self->{qc_results}->{$construct}->{is_chosen_for_engseq_in_run}; }
	    else { push @row, ''; }
	    # [19]
	    if ($self->{qc_results}->{$construct}->{distribute_for_engseq}) { push @row, $self->{qc_results}->{$construct}->{distribute_for_engseq}; }
	    else { push @row, ''; }

	    # [20]
	    if ($self->{qc_results}->{$construct}->{result_comment}) {
		push @row, $self->{qc_results}->{$construct}->{result_comment};
	    }
	    else { push @row, ''; }

	    # [21]
	    if ($self->{qc_results}->{$construct}->{chosen_status}) {
		push @row, $self->{qc_results}->{$construct}->{chosen_status};
	    }
	    else { push @row, ''; }

	    # [22]
	    push @row, $self->{qc_results}->{$construct}->{construct_well};

	    push @{$self->{results}}, \@row;

	    $counter++;
	}
    }
    return $self->{results};
}

sub order_primers {
    my $primers = shift;
    my @primers = ();

    if ($primers->{G5}) {push @primers, $primers->{G5}; }
    if ($primers->{GF}) {push @primers, $primers->{GF}; }
    if ($primers->{R3F}) {push @primers, $primers->{R3F}; }
    if ($primers->{R3}) {push @primers, $primers->{R3}; }
    if ($primers->{L3}) {push @primers, $primers->{L3}; }
    if ($primers->{L1}) {push @primers, $primers->{L1}; }
    if ($primers->{R1R}) {push @primers, $primers->{R1R}; }
    if ($primers->{Z1}) {push @primers, $primers->{Z1}; }
    if ($primers->{FCHK}) {push @primers, $primers->{FCHK}; }
    if ($primers->{IRES}) {push @primers, $primers->{IRES}; }
    if ($primers->{NF}) {push @primers, $primers->{NF}; }
    if ($primers->{PNF}) {push @primers, $primers->{PNF}; }
    if ($primers->{UNK}) {push @primers, $primers->{UNK}; }
    if ($primers->{Z2}) {push @primers, $primers->{Z2}; }
    if ($primers->{R2R}) {push @primers, $primers->{R2R}; }
    if ($primers->{LFR}) {push @primers, $primers->{LFR}; }
    if ($primers->{LF}) {push @primers, $primers->{LF}; }
    if ($primers->{LRR}) {push @primers, $primers->{LRR}; }
    if ($primers->{LR}) {push @primers, $primers->{LR}; }
    if ($primers->{SP6}) {push @primers, $primers->{SP6}; }
    if ($primers->{R4}) {push @primers, $primers->{R4}; }
    if ($primers->{L4}) {push @primers, $primers->{L4}; }
    if ($primers->{R4R}) {push @primers, $primers->{R4R}; }
    if ($primers->{G3}) {push @primers, $primers->{G3}; }
    if ($primers->{GR}) {push @primers, $primers->{GR}; }

    return(\@primers);
}

sub update_choices  {
    my $self = shift;
    my $choices = shift;
    my $delete_others = shift;

    return unless ($self->{'qctest_run_id'});

    eval {
	$self->{se}->beginTransaction($self->{dbh});

	foreach my $construct(sort {$a cmp $b} keys %$choices) {
	    my $well = $choices->{$construct};
	    # get the engseq for the well
	    my ($engseq_id) = $self->{se}->getRow('Web::getEngseqIdFromRunWell', [$self->{'qctest_run_id'}, $well], $self->{dbh});
#	    print "$self->{'qctest_run_id'} well $well engseq $engseq_id construct $construct\n";

	    # remove any existing choosens that are set for a particular run and engseq
	    if ($delete_others) { $self->{se}->do('Web::deleteChosenForRunEngseq', [$self->{'qctest_run_id'}, $engseq_id], $self->{dbh}); }

	    if ($well) {
		# set this construct as the chosen one for this engseq and this run
		$self->{se}->do('Web::setChosenForRunConstruct', [$engseq_id, $self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	    else {
                # unset this construct as the chosen one for this engseq and this run
		$self->{se}->do('Web::deleteChosenForRunConstruct', [$self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	}
    };

    # roll it all back
    if ($@) {
	print "errors: $@\n";
	$self->{se}->rollbackTransaction($self->{dbh});
    }
    # or commit
    else {
#	print "all is OK\n";
#	$self->{se}->rollbackTransaction($self->{dbh});
	$self->{se}->commitTransaction($self->{dbh});
    }


}

sub update_chosen_statuses  {
    my $self = shift;
    my $choices = shift;

    return unless ($self->{'qctest_run_id'});

    eval {
	$self->{se}->beginTransaction($self->{dbh});

	foreach my $construct(sort {$a cmp $b} keys %$choices) {
	    my $new_status = $choices->{$construct};
	    # set this construct status
	    if ($new_status) {
		$self->{se}->do('Web::setChosenStatusForRunConstruct', [$new_status, $self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	    else {
		$self->{se}->do('Web::deleteChosenStatusForRunConstruct', [$self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	}
    };
    # roll it all back
    if ($@) {
	print "errors: $@\n";
	$self->{se}->rollbackTransaction($self->{dbh});
    }
    # or commit
    else {
#	print "all is OK\n";
#	$self->{se}->rollbackTransaction($self->{dbh});
	$self->{se}->commitTransaction($self->{dbh});
    }
}

sub update_result_comments  {
    my $self = shift;
    my $comments = shift;

    return unless ($self->{'qctest_run_id'});

    eval {
	$self->{se}->beginTransaction($self->{dbh});

	foreach my $construct(sort {$a cmp $b} keys %$comments) {
	    my $comment = $comments->{$construct};
	    # set this construct status
	    if ($comment) {
		$self->{se}->do('Web::setCommentForRunConstruct', [$comment, $self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	    else {
		$self->{se}->do('Web::deleteCommentForRunConstruct', [$self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	}
    };
    # roll it all back
    if ($@) {
	print "errors: $@\n";
	$self->{se}->rollbackTransaction($self->{dbh});
    }
    # or commit
    else {
#	print "all is OK\n";
#	$self->{se}->rollbackTransaction($self->{dbh});
	$self->{se}->commitTransaction($self->{dbh});
    }
}


sub update_distribute  {
    my $self = shift;
    my $choices = shift;
    my $delete_others = shift;

    return unless ($self->{'qctest_run_id'});

    eval {
	$self->{se}->beginTransaction($self->{dbh});

	foreach my $construct(sort {$a cmp $b} keys %$choices) {
	    my $well = $choices->{$construct};
	    # get the engseq for the well
	    my ($engseq_id) = $self->{se}->getRow('Web::getEngseqIdFromRunWell', [$self->{'qctest_run_id'}, $well], $self->{dbh});
#	    print "well $well engseq $engseq_id construct $construct\n";

	    # remove any existing distribution flags that are set for a particular engseq (not run specific)
	    if ($delete_others) { $self->{se}->do('Web::deleteDistributeForRunEngseq', [$engseq_id], $self->{dbh}); }

	    # set this construct as the one to distribute for this engseq
	    if ($well) {
		$self->{se}->do('Web::setDistributeForRunConstruct', [$engseq_id, $self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	    else {
		$self->{se}->do('Web::deleteDistributeForRunConstruct', [$self->{'qctest_run_id'}, $construct], $self->{dbh});
	    }
	}
    };

    # roll it all back
    if ($@) {
	print "errors: $@\n";
	$self->{se}->rollbackTransaction($self->{dbh});
    }
    # or commit
    else {
#	print "all is OK\n";
#	$self->{se}->rollbackTransaction($self->{dbh});
	$self->{se}->commitTransaction($self->{dbh});
    }


}

sub get_runs {

    my $self = shift;
    my $hash = {};
    my ($data) = $self->{se}->getAll('Web::get_runs', [], $self->{dbh});
    # NB only gives most recent run for each clone! key = clone_plate, value = runid
    foreach (@$data) { 
	my $clone = $_->[1];
	my $id = $_->[0];
	$hash->{$clone} = $id; 
    }
    
    return($hash);
}

sub check_for_changes {

    my $self = shift;
    my ($choices, $comments, $chosen_statuses) = @_;

    # get the current data and see what has changed.
    # only pass the update methods the changed data
    my $current_data = &get_construct_list($self);

    my $set_choices;
    my $set_chosen_statuses;
    my $set_comments;

    foreach my $qctest_result(@$current_data) {
	my $construct = $qctest_result->[1];

	my $is_chosen_current = $qctest_result->[18];
	my $comment_current = $qctest_result->[20];
	my $chosen_status_current = $qctest_result->[21];

	my $is_chosen_new = $choices->{$construct};
	my $comment_new = $comments->{$construct};
	my $chosen_status_new = $chosen_statuses->{$construct};

	if (($is_chosen_current && $is_chosen_new && ($is_chosen_current ne $is_chosen_new)) || 
	    ($is_chosen_current && !($is_chosen_new)) ||
	    (!($is_chosen_current) && $is_chosen_new)) {

	    $set_choices->{$construct} = $is_chosen_new;
	}

	if (($comment_current && $comment_new && ($comment_current ne $comment_new)) ||
	    ($comment_current && !($comment_new)) ||
	    (!($comment_current) && $comment_new)) {

	    $set_comments->{$construct} = $comment_new;
	}

	if (($chosen_status_current && $chosen_status_new && ($chosen_status_current ne $chosen_status_new)) ||
	    ($chosen_status_current && !($chosen_status_new)) ||
	    (!($chosen_status_current) && $chosen_status_new)) {

	    $set_chosen_statuses->{$construct} = $chosen_status_new;
	}
    }
       
    return($set_choices, $set_comments, $set_chosen_statuses);
}

sub check_for_distribute_changes {

    my $self = shift;
    my ($choices) = @_;

    # get the current data and see what has changed.
    # only pass the update methods the changed data
    my $current_data = &get_construct_list($self);

    my $set_choices;

    foreach my $qctest_result(@$current_data) {
	my $construct = $qctest_result->[1];
	my $is_chosen_current = $qctest_result->[19];
	my $is_chosen_new = $choices->{$construct};

	if (($is_chosen_current && $is_chosen_new && ($is_chosen_current ne $is_chosen_new)) || 
	    ($is_chosen_current && !($is_chosen_new)) ||
	    (!($is_chosen_current) && $is_chosen_new)) {

	    $set_choices->{$construct} = $is_chosen_new;
	}
    }
       
    return($set_choices);
}

# this is getting everything picked for a design_instance plate NOT the design plate!! Only OK for simple cases.
# may need to go back to the actual design plate ultimately... see how things go
sub get_distribution_plate {

    my $self = shift;
    my $plate = shift;
    my $stage = shift;

    my $hash = {};

    # returns s.design_well,  c.name,  r.qctest_run_id, s.cassette_formula,  c.id_vector_batch
    my $data = $self->{se}->getAll('Web::get_distribution_plate', [$plate, $stage], $self->{dbh});

    foreach (@$data) { 
	my $design_well = $_->[0];
	my $construct_name = $_->[1];
	my $qctest_run_id = $_->[2];
	my $qctest_result_id = $_->[3];
	my $cassette_formula = $_->[4];
	my $id_vector_batch = $_->[5];

	$hash->{$qctest_result_id} = [$construct_name, $design_well, $qctest_run_id, $cassette_formula, $id_vector_batch]; 
    }
    return($hash);
}


# NB this is actually the design_instance plate not the design plate!!
sub get_design_plate_stage_from_run {

    my $self = shift;

    return unless ($self->{'qctest_run_id'});
    my $qctest_run_id = $self->{'qctest_run_id'};

    # returns array of arrays - [design_plate, stage]
    my $data = $self->{se}->getAll('Web::get_design_plate_stage_from_run', [$qctest_run_id], $self->{dbh});

    return($data);
}


1;

