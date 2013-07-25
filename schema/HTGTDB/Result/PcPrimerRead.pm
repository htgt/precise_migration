use utf8;
package HTGTDB::Result::PcPrimerRead;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::PcPrimerRead

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PC_PRIMER_READ>

=cut

__PACKAGE__->table("PC_PRIMER_READ");

=head1 ACCESSORS

=head2 pc_primer_read_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_pc_primer_read'
  size: [10,0]

=head2 well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 primer_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 loc_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 qcresult_status

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 align_length

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 pct_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "pc_primer_read_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_pc_primer_read",
    size => [10, 0],
  },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "primer_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</pc_primer_read_id>

=back

=cut

__PACKAGE__->set_primary_key("pc_primer_read_id");

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:59BdhPbCUYBclnqnDq14yA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
