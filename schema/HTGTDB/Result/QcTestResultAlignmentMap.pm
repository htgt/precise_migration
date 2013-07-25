use utf8;
package HTGTDB::Result::QcTestResultAlignmentMap;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcTestResultAlignmentMap

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_TEST_RESULT_ALIGNMENT_MAP>

=cut

__PACKAGE__->table("QC_TEST_RESULT_ALIGNMENT_MAP");

=head1 ACCESSORS

=head2 qc_test_result_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 qc_test_result_alignment_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "qc_test_result_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "qc_test_result_alignment_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_test_result_id>

=item * L</qc_test_result_alignment_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_test_result_id", "qc_test_result_alignment_id");

=head1 RELATIONS

=head2 qc_test_result

Type: belongs_to

Related object: L<HTGTDB::Result::QcTestResult>

=cut

__PACKAGE__->belongs_to(
  "qc_test_result",
  "HTGTDB::Result::QcTestResult",
  { qc_test_result_id => "qc_test_result_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fb3EvhThuSrrjL6lSRZeXw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
