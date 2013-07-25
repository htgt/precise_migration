use utf8;
package HTGTDB::Result::DesignTaqmanAssay;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignTaqmanAssay

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_TAQMAN_ASSAY>

=cut

__PACKAGE__->table("DESIGN_TAQMAN_ASSAY");

=head1 ACCESSORS

=head2 design_taqman_assay_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_design_taqman_assay'
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 assay_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 deleted_region

  data_type: 'varchar2'
  is_nullable: 0
  size: 1

=head2 forward_primer_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 reverse_primer_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 reporter_probe_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 taqman_plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [8,0]

=head2 well_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 edit_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=cut

__PACKAGE__->add_columns(
  "design_taqman_assay_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_taqman_assay",
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "assay_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "deleted_region",
  { data_type => "varchar2", is_nullable => 0, size => 1 },
  "forward_primer_seq",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "reverse_primer_seq",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "reporter_probe_seq",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "taqman_plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [8, 0],
  },
  "well_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "edit_user",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_taqman_assay_id>

=back

=cut

__PACKAGE__->set_primary_key("design_taqman_assay_id");

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

=head2 taqman_plate

Type: belongs_to

Related object: L<HTGTDB::Result::DesignTaqmanPlate>

=cut

__PACKAGE__->belongs_to(
  "taqman_plate",
  "HTGTDB::Result::DesignTaqmanPlate",
  { taqman_plate_id => "taqman_plate_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:36/VhEdJW/MnJ668gyCikw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
