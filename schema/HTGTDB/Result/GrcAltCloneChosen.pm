use utf8;
package HTGTDB::Result::GrcAltCloneChosen;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GrcAltCloneChosen

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GRC_ALT_CLONE_CHOSEN>

=cut

__PACKAGE__->table("GRC_ALT_CLONE_CHOSEN");

=head1 ACCESSORS

=head2 grc_alt_clone_chosen_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 gr_gene_status_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 chosen_well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 chosen_clone_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 200

=head2 child_plates

  data_type: 'varchar2'
  is_nullable: 0
  size: 400

=cut

__PACKAGE__->add_columns(
  "grc_alt_clone_chosen_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "gr_gene_status_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "chosen_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "chosen_clone_name",
  { data_type => "varchar2", is_nullable => 0, size => 200 },
  "child_plates",
  { data_type => "varchar2", is_nullable => 0, size => 400 },
);

=head1 PRIMARY KEY

=over 4

=item * L</grc_alt_clone_chosen_id>

=back

=cut

__PACKAGE__->set_primary_key("grc_alt_clone_chosen_id");

=head1 RELATIONS

=head2 chosen_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "chosen_well",
  "HTGTDB::Result::Well",
  { well_id => "chosen_well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 gr_gene_status

Type: belongs_to

Related object: L<HTGTDB::Result::GrGeneStatus>

=cut

__PACKAGE__->belongs_to(
  "gr_gene_status",
  "HTGTDB::Result::GrGeneStatus",
  { gr_gene_status_id => "gr_gene_status_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:14
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nAaC9cts3gHK15RRQOPy3A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
