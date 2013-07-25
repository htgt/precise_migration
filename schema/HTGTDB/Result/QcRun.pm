use utf8;
package HTGTDB::Result::QcRun;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcRun

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_RUNS>

=cut

__PACKAGE__->table("QC_RUNS");

=head1 ACCESSORS

=head2 qc_run_id

  data_type: 'char'
  is_nullable: 0
  size: 36

=head2 qc_run_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 0

=head2 sequencing_project

  data_type: 'varchar2'
  is_nullable: 0
  size: 512

=head2 profile

  data_type: 'varchar2'
  is_nullable: 0
  size: 128

=head2 template_plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 software_version

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 plate_map

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=cut

__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_nullable => 0, size => 36 },
  "qc_run_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 0,
  },
  "sequencing_project",
  { data_type => "varchar2", is_nullable => 0, size => 512 },
  "profile",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "template_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "software_version",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "plate_map",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_run_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_run_id");

=head1 RELATIONS

=head2 qc_run_seqs_read

Type: has_many

Related object: L<HTGTDB::Result::QcRunSeqRead>

=cut

__PACKAGE__->has_many(
  "qc_run_seqs_read",
  "HTGTDB::Result::QcRunSeqRead",
  { "foreign.qc_run_id" => "self.qc_run_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_sequencing_project_maps

Type: has_many

Related object: L<HTGTDB::Result::QcSequencingProjectMap>

=cut

__PACKAGE__->has_many(
  "qc_sequencing_project_maps",
  "HTGTDB::Result::QcSequencingProjectMap",
  { "foreign.qc_run_id" => "self.qc_run_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 qc_test_results

Type: has_many

Related object: L<HTGTDB::Result::QcTestResult>

=cut

__PACKAGE__->has_many(
  "qc_test_results",
  "HTGTDB::Result::QcTestResult",
  { "foreign.qc_run_id" => "self.qc_run_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 template_plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "template_plate",
  "HTGTDB::Result::Plate",
  { plate_id => "template_plate_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_seqs_read

Type: many_to_many

Composing rels: L</qc_run_seqs_read> -> qc_seq_read

=cut

__PACKAGE__->many_to_many("qc_seqs_read", "qc_run_seqs_read", "qc_seq_read");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bYO4Os8f4t7TRjC8PP99HQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
