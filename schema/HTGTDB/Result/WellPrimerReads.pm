use utf8;
package HTGTDB::Result::WellPrimerReads;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::WellPrimerReads

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL_PRIMER_READS>

=cut

__PACKAGE__->table("WELL_PRIMER_READS");

=head1 ACCESSORS

=head2 well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 clone_plate

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 primer_design_instance_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lf_loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lf_align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lf_pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lf_qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lr_loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lr_align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lr_pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lr_qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lrr_loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 lrr_align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lrr_pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 lrr_qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 r1r_loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 r1r_align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 r1r_pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 r1r_qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 r2r_loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 r2r_align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 r2r_pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 r2r_qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "clone_plate",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "primer_design_instance_id",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lf_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lf_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lr_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lr_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lrr_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lrr_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lrr_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lrr_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r1r_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r1r_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r1r_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r1r_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r2r_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r2r_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r2r_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r2r_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=item * L</clone_plate>

=back

=cut

__PACKAGE__->set_primary_key("well_id", "clone_plate");

=head1 RELATIONS

=head2 well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "HTGTDB::Result::Well",
  { well_id => "well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Kmoja7HLoSL4I+YnkvNzFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
