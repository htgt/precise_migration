use utf8;
package HTGTDB::Result::GrAltClone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GrAltClone

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GR_ALT_CLONE>

=cut

__PACKAGE__->table("GR_ALT_CLONE");

=head1 ACCESSORS

=head2 gr_alt_clone_id

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

=head2 acr_well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "gr_alt_clone_id",
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
  "acr_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</gr_alt_clone_id>

=back

=cut

__PACKAGE__->set_primary_key("gr_alt_clone_id");

=head1 RELATIONS

=head2 acr_well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "acr_well",
  "HTGTDB::Result::Well",
  { well_id => "acr_well_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3DFBnIbyJkxb86FdjVd/Dw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
