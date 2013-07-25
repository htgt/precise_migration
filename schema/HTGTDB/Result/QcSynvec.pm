use utf8;
package HTGTDB::Result::QcSynvec;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::QcSynvec

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<QC_SYNVECS>

=cut

__PACKAGE__->table("QC_SYNVECS");

=head1 ACCESSORS

=head2 qc_synvec_id

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 cassette

  data_type: 'varchar2'
  is_nullable: 0
  size: 128

=head2 backbone

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 apply_flp

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 apply_cre

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 genbank

  data_type: 'clob'
  is_nullable: 0

=head2 vector_stage

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 apply_dre

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "qc_synvec_id",
  { data_type => "char", is_nullable => 0, size => 40 },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "cassette",
  { data_type => "varchar2", is_nullable => 0, size => 128 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "apply_flp",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "apply_cre",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "genbank",
  { data_type => "clob", is_nullable => 0 },
  "vector_stage",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "apply_dre",
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

=item * L</qc_synvec_id>

=back

=cut

__PACKAGE__->set_primary_key("qc_synvec_id");

=head1 RELATIONS

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 qc_test_results

Type: has_many

Related object: L<HTGTDB::Result::QcTestResult>

=cut

__PACKAGE__->has_many(
  "qc_test_results",
  "HTGTDB::Result::QcTestResult",
  { "foreign.qc_synvec_id" => "self.qc_synvec_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CXjwccVZ5y03Bl90vlWwWQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
