use utf8;
package HTGTDB::Result::GrGeneStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GrGeneStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GR_GENE_STATUS>

=cut

__PACKAGE__->table("GR_GENE_STATUS");

=head1 ACCESSORS

=head2 gr_gene_status_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 mgi_gene_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 state

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 note

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=head2 updated

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gr_gene_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "state",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "updated",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gr_gene_status_id>

=back

=cut

__PACKAGE__->set_primary_key("gr_gene_status_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<sys_c0077559>

=over 4

=item * L</mgi_gene_id>

=back

=cut

__PACKAGE__->add_unique_constraint("sys_c0077559", ["mgi_gene_id"]);

=head1 RELATIONS

=head2 gr_alt_clones

Type: has_many

Related object: L<HTGTDB::Result::GrAltClone>

=cut

__PACKAGE__->has_many(
  "gr_alt_clones",
  "HTGTDB::Result::GrAltClone",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_gateways

Type: has_many

Related object: L<HTGTDB::Result::GrGateway>

=cut

__PACKAGE__->has_many(
  "gr_gateways",
  "HTGTDB::Result::GrGateway",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_redesigns

Type: has_many

Related object: L<HTGTDB::Result::GrRedesign>

=cut

__PACKAGE__->has_many(
  "gr_redesigns",
  "HTGTDB::Result::GrRedesign",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_alt_clone_alternates

Type: has_many

Related object: L<HTGTDB::Result::GrcAltCloneAlternate>

=cut

__PACKAGE__->has_many(
  "grc_alt_clone_alternates",
  "HTGTDB::Result::GrcAltCloneAlternate",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_alt_clones_chosen

Type: has_many

Related object: L<HTGTDB::Result::GrcAltCloneChosen>

=cut

__PACKAGE__->has_many(
  "grc_alt_clones_chosen",
  "HTGTDB::Result::GrcAltCloneChosen",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_gateways

Type: has_many

Related object: L<HTGTDB::Result::GrcGateway>

=cut

__PACKAGE__->has_many(
  "grc_gateways",
  "HTGTDB::Result::GrcGateway",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_redesigns

Type: has_many

Related object: L<HTGTDB::Result::GrcRedesign>

=cut

__PACKAGE__->has_many(
  "grc_redesigns",
  "HTGTDB::Result::GrcRedesign",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_reseqs

Type: has_many

Related object: L<HTGTDB::Result::GrcReseq>

=cut

__PACKAGE__->has_many(
  "grc_reseqs",
  "HTGTDB::Result::GrcReseq",
  { "foreign.gr_gene_status_id" => "self.gr_gene_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mgi_gene

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneIdMap>

=cut

__PACKAGE__->belongs_to(
  "mgi_gene",
  "HTGTDB::Result::MgiGeneIdMap",
  { mgi_gene_id => "mgi_gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 state

Type: belongs_to

Related object: L<HTGTDB::Result::GrValidState>

=cut

__PACKAGE__->belongs_to(
  "state",
  "HTGTDB::Result::GrValidState",
  { state => "state" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gDEH9N/zcnEKJ05KCGh0vQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
