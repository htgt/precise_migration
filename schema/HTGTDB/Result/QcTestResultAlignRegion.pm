use utf8;
package HTGTDB::Result::QcTestResultAlignRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcTestResultAlignRegion

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_TEST_RESULT_ALIGN_REGIONS>

=cut

__PACKAGE__->table("QC_TEST_RESULT_ALIGN_REGIONS");

=head1 ACCESSORS

=head2 qc_test_result_alignment_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 1000

=head2 length

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 match_count

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 query_str

  data_type: 'clob'
  is_nullable: 0

=head2 target_str

  data_type: 'clob'
  is_nullable: 0

=head2 match_str

  data_type: 'clob'
  is_nullable: 0

=head2 pass

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
  "length",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "match_count",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "query_str",
  { data_type => "clob", is_nullable => 0 },
  "target_str",
  { data_type => "clob", is_nullable => 0 },
  "match_str",
  { data_type => "clob", is_nullable => 0 },
  "pass",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_test_result_alignment_id>

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("qc_test_result_alignment_id", "name");

=head1 RELATIONS

=head2 qc_test_result_alignment

Type: belongs_to

Related object: L<HTGTDB::Result::QcTestResultAlignment>

=cut

__PACKAGE__->belongs_to(
  "qc_test_result_alignment",
  "HTGTDB::Result::QcTestResultAlignment",
  { qc_test_result_alignment_id => "qc_test_result_alignment_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mLRkVmf1ES5cQhl+1Fsl3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
