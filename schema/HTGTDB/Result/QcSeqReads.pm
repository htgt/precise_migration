use utf8;
package HTGTDB::Result::QcSeqReads;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcSeqReads

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_SEQ_READS>

=cut

__PACKAGE__->table("QC_SEQ_READS");

=head1 ACCESSORS

=head2 qc_seq_read_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 128

=head2 description

  data_type: 'varchar2'
  default_value: (empty string)
  is_nullable: 0
  size: 200

=head2 seq

  data_type: 'clob'
  is_nullable: 0

=head2 length

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "qc_seq_read_id",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "description",
  { data_type => "varchar2", default_value => "", is_nullable => 0, size => 200 },
  "seq",
  { data_type => "clob", is_nullable => 0 },
  "length",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_seq_read_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_seq_read_id");

=head1 RELATIONS

=head2 qc_run_seqs_read

Type: has_many

Related object: L<HTGTDB::Result::QcRunSeqRead>

=cut

__PACKAGE__->has_many(
  "qc_run_seqs_read",
  "HTGTDB::Result::QcRunSeqRead",
  { "foreign.qc_seq_read_id" => "self.qc_seq_read_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_result_alignments

Type: has_many

Related object: L<HTGTDB::Result::QcTestResultAlignment>

=cut

__PACKAGE__->has_many(
  "qc_test_result_alignments",
  "HTGTDB::Result::QcTestResultAlignment",
  { "foreign.qc_seq_read_id" => "self.qc_seq_read_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_runs

Type: many_to_many

Composing rels: L</qc_run_seqs_read> -> qc_run

=cut

__PACKAGE__->many_to_many("qc_runs", "qc_run_seqs_read", "qc_run");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7g9JIUHPs42eq0VpSx66Cg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
