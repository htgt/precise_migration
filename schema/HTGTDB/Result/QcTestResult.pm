use utf8;
package HTGTDB::Result::QcTestResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcTestResult

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_TEST_RESULTS>

=cut

__PACKAGE__->table("QC_TEST_RESULTS");

=head1 ACCESSORS

=head2 qc_test_result_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 'qc_test_results_seq'
  size: [10,0]

=head2 qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 qc_synvec_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 well_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 128

=head2 score

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 pass

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 plate_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "qc_test_result_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "qc_test_results_seq",
    size => [10, 0],
  },
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "qc_synvec_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "well_name",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "score",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pass",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "plate_name",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_test_result_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_test_result_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<qc_test_results_uk1>

=over 4

=item * L</qc_run_id>

=item * L</qc_synvec_id>

=item * L</well_name>

=item * L</plate_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "qc_test_results_uk1",
  ["qc_run_id", "qc_synvec_id", "well_name", "plate_name"],
);

=head1 RELATIONS

=head2 qc_run

Type: belongs_to

Related object: L<HTGTDB::Result::QcRun>

=cut

__PACKAGE__->belongs_to(
  "qc_run",
  "HTGTDB::Result::QcRun",
  { qc_run_id => "qc_run_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_synvec

Type: belongs_to

Related object: L<HTGTDB::Result::QcSynvec>

=cut

__PACKAGE__->belongs_to(
  "qc_synvec",
  "HTGTDB::Result::QcSynvec",
  { qc_synvec_id => "qc_synvec_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_test_result_alignment_maps

Type: has_many

Related object: L<HTGTDB::Result::QcTestResultAlignmentMap>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignment_maps",
  "HTGTDB::Result::QcTestResultAlignmentMap",
  { "foreign.qc_test_result_id" => "self.qc_test_result_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_result_alignments

Type: many_to_many

Composing rels: L</qc_test_result_alignment_maps> -> qc_test_result_alignment

=cut

__PACKAGE__->many_to_many(
  "qc_test_result_alignments",
  "qc_test_result_alignment_maps",
  "qc_test_result_alignment",
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uUGHB/wARO55tOnmpeyh2w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
