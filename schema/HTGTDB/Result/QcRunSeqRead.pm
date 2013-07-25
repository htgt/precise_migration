use utf8;
package HTGTDB::Result::QcRunSeqRead;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcRunSeqRead

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_RUN_SEQ_READ>

=cut

__PACKAGE__->table("QC_RUN_SEQ_READ");

=head1 ACCESSORS

=head2 qc_run_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 36

=head2 qc_seq_read_id

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "qc_run_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 36 },
  "qc_seq_read_id",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</qc_run_id>

=item * L</qc_seq_read_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_run_id", "qc_seq_read_id");

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9zhQcn/jiGAzy/oxToivzQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
