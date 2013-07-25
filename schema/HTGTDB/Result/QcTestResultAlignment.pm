use utf8;
package HTGTDB::Result::QcTestResultAlignment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcTestResultAlignment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_TEST_RESULT_ALIGNMENTS>

=cut

__PACKAGE__->table("QC_TEST_RESULT_ALIGNMENTS");

=head1 ACCESSORS

=head2 qc_seq_read_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 128

=head2 primer_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 query_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 query_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 query_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 target_start

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_end

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_strand

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 score

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 pass

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 op_str

  data_type: 'varchar2'
  is_nullable: 0
  size: 1024

=head2 cigar

  data_type: 'varchar2'
  is_nullable: 0
  size: 2048

=head2 features

  data_type: 'varchar2'
  default_value: (empty string)
  is_nullable: 0
  size: 2048

=head2 qc_test_result_alignment_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "qc_seq_read_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 128 },
  "primer_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "query_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "target_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "score",
  {
    data_type => "numeric",
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
  "op_str",
  { data_type => "varchar2", is_nullable => 0, size => 1024 },
  "cigar",
  { data_type => "varchar2", is_nullable => 0, size => 2048 },
  "features",
  {
    data_type => "varchar2",
    default_value => "",
    is_nullable => 0,
    size => 2048,
  },
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_test_result_alignment_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_test_result_alignment_id");

=head1 RELATIONS

=head2 qc_seq_read

Type: belongs_to

Related object: L<HTGTDB::Result::QcSeqReads>

=cut

__PACKAGE__->belongs_to(
  "qc_seq_read",
  "HTGTDB::Result::QcSeqReads",
  { qc_seq_read_id => "qc_seq_read_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_test_result_align_regions

Type: has_many

Related object: L<HTGTDB::Result::QcTestResultAlignRegion>

=cut

__PACKAGE__->has_many(
  "qc_test_result_align_regions",
  "HTGTDB::Result::QcTestResultAlignRegion",
  {
    "foreign.qc_test_result_alignment_id" => "self.qc_test_result_alignment_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_result_alignment_maps

Type: has_many

Related object: L<HTGTDB::Result::QcTestResultAlignmentMap>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignment_maps",
  "HTGTDB::Result::QcTestResultAlignmentMap",
  {
    "foreign.qc_test_result_alignment_id" => "self.qc_test_result_alignment_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_results

Type: many_to_many

Composing rels: L</qc_test_result_alignment_maps> -> qc_test_result

=cut

__PACKAGE__->many_to_many(
  "qc_test_results",
  "qc_test_result_alignment_maps",
  "qc_test_result",
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pr0Ts4Ezje3N029OtqNSWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
