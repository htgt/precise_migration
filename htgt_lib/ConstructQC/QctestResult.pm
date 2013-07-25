package ConstructQC::QctestResult;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/QctestResult.pm,v 1.8 2009-03-09 15:57:44 wy1 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("qctest_result");
__PACKAGE__->add_columns(
    "qctest_result_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "qctest_run_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "comments",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "pass_status",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
    "toxin_pass",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 0,
        size          => 255,
    },
    "sum_score",
    {
        data_type     => "FLOAT",
        default_value => undef,
        is_nullable   => 1,
        size          => 126
    },
    "is_best_for_engseq_in_run",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "is_best_for_construct_in_run",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "is_chosen_for_engseq_in_run",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "engineered_seq_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "construct_clone_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "expected_engineered_seq_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "is_valid",
    {
        data_type     => "NUMBER",
        default_value => "0\n",
        is_nullable   => 1,
        size          => 1
    },
    "is_perfect",
    {
        data_type     => "NUMBER",
        default_value => "0\n",
        is_nullable   => 1,
        size          => 1
    },
    "distribute_for_engseq",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "chosen_status",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "result_comment",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 2000,
    },
);

__PACKAGE__->set_primary_key("qctest_result_id");

__PACKAGE__->belongs_to( qctestRun => 'ConstructQC::QctestRun', "qctest_run_id" );
__PACKAGE__->belongs_to( constructClone => 'ConstructQC::ConstructClone', "construct_clone_id" );
__PACKAGE__->belongs_to( expectedEngineeredSeq => 'ConstructQC::EngineeredSeq', "expected_engineered_seq_id" );
__PACKAGE__->belongs_to( matchedEngineeredSeq => 'ConstructQC::EngineeredSeq', "engineered_seq_id" );
#for marking manually the best in run
__PACKAGE__->belongs_to( chosenEngineeredSeq => 'ConstructQC::EngineeredSeq', "is_chosen_for_engseq_in_run" );
#for marking manually the best (for distribution) over runs (should ditch this)
__PACKAGE__->belongs_to( markedEngineeredSeq => 'ConstructQC::EngineeredSeq', "distribute_for_engseq" );
__PACKAGE__->belongs_to( distributedEngineeredSeq => 'ConstructQC::EngineeredSeq', "distribute_for_engseq" );#alias

__PACKAGE__->has_many( qctestPrimers => 'ConstructQC::QctestPrimer', "qctest_result_id" );

# Shortcut to the SyntheticVectors...
__PACKAGE__->belongs_to( expectedSyntheticVector => 'ConstructQC::SyntheticVector', "expected_engineered_seq_id" );
__PACKAGE__->belongs_to( matchedSyntheticVector => 'ConstructQC::SyntheticVector', "engineered_seq_id" );
__PACKAGE__->belongs_to( chosenSyntheticVector => 'ConstructQC::SyntheticVector', "is_chosen_for_engseq_in_run" );


=head2 bioseq

Get BioSeq object using TargetedTrap::IVSA api and annotate on alignments.

=cut

use TargetedTrap::DBSQL::Database;
sub bioseq {
  my ($this)=@_;
  my $qc_db=TargetedTrap::DBSQL::Database->new();
  $qc_db->{DB_CONNECTION} = $this->result_source()->storage()->dbh();
  my $seq = $this->matchedEngineeredSeq()->bioseq();
  my $af_rs = $this->qctestPrimers()->related_resultset('seqAlignFeature');
  while (my $af = $af_rs->next()){
     my $type =  $af->qcSeqread->oligo_name; 
     $seq->add_SeqFeature(new Bio::SeqFeature::Generic(
      -start  => $af->engseq_start,
      -end => $af->engseq_end,
      -strand =>  $af->seqread_ori eq $af->engseq_ori ? '+' : '-', 
      -primary_tag => q(seq_align),
      -display_name => "$type seq alignment",
      -tag => {note=>$type,type=>$type},
    ) );
  }
  return $seq;
}

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

