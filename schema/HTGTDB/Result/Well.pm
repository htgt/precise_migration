use utf8;
package HTGTDB::Result::Well;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Well

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<WELL>

=cut

__PACKAGE__->table("WELL");

=head1 ACCESSORS

=head2 plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 well_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_well'
  size: [10,0]

=head2 parent_well_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 qctest_result_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "well_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_well",
    size => [10, 0],
  },
  "parent_well_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</well_id>

=back

=cut

__PACKAGE__->set_primary_key("well_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<well_plate_well_name_c>

=over 4

=item * L</plate_id>

=item * L</well_name>

=back

=cut

__PACKAGE__->add_unique_constraint("well_plate_well_name_c", ["plate_id", "well_name"]);

=head1 RELATIONS

=head2 gr_alt_clones

Type: has_many

Related object: L<HTGTDB::Result::GrAltClone>

=cut

__PACKAGE__->has_many(
  "gr_alt_clones",
  "HTGTDB::Result::GrAltClone",
  { "foreign.acr_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_gateways

Type: has_many

Related object: L<HTGTDB::Result::GrGateway>

=cut

__PACKAGE__->has_many(
  "gr_gateways",
  "HTGTDB::Result::GrGateway",
  { "foreign.gwr_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_redesigns

Type: has_many

Related object: L<HTGTDB::Result::GrRedesign>

=cut

__PACKAGE__->has_many(
  "gr_redesigns",
  "HTGTDB::Result::GrRedesign",
  { "foreign.rdr_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_alt_clone_alternates

Type: has_many

Related object: L<HTGTDB::Result::GrcAltCloneAlternate>

=cut

__PACKAGE__->has_many(
  "grc_alt_clone_alternates",
  "HTGTDB::Result::GrcAltCloneAlternate",
  { "foreign.alt_clone_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_alt_clones_chosen

Type: has_many

Related object: L<HTGTDB::Result::GrcAltCloneChosen>

=cut

__PACKAGE__->has_many(
  "grc_alt_clones_chosen",
  "HTGTDB::Result::GrcAltCloneChosen",
  { "foreign.chosen_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_gateways

Type: has_many

Related object: L<HTGTDB::Result::GrcGateway>

=cut

__PACKAGE__->has_many(
  "grc_gateways",
  "HTGTDB::Result::GrcGateway",
  { "foreign.pcs_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_redesigns

Type: has_many

Related object: L<HTGTDB::Result::GrcRedesign>

=cut

__PACKAGE__->has_many(
  "grc_redesigns",
  "HTGTDB::Result::GrcRedesign",
  { "foreign.design_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 grc_reseqs

Type: has_many

Related object: L<HTGTDB::Result::GrcReseq>

=cut

__PACKAGE__->has_many(
  "grc_reseqs",
  "HTGTDB::Result::GrcReseq",
  { "foreign.targvec_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_designs_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_designs_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.design_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_dnas_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_dnas_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.dna_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_epds_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_epds_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.epd_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_eps_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_eps_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.ep_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_fps_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_fps_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.fp_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_pcs_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_pcs_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.pcs_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 new_well_summary_pgdgrs_well

Type: has_many

Related object: L<HTGTDB::Result::NewWellSummary>

=cut

__PACKAGE__->has_many(
  "new_well_summary_pgdgrs_well",
  "HTGTDB::Result::NewWellSummary",
  { "foreign.pgdgr_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 pc_primers_read

Type: has_many

Related object: L<HTGTDB::Result::PcPrimerRead>

=cut

__PACKAGE__->has_many(
  "pc_primers_read",
  "HTGTDB::Result::PcPrimerRead",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "HTGTDB::Result::Plate",
  { plate_id => "plate_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 repository_qc_result

Type: might_have

Related object: L<HTGTDB::Result::RepositoryQcResult>

=cut

__PACKAGE__->might_have(
  "repository_qc_result",
  "HTGTDB::Result::RepositoryQcResult",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_qc_result

Type: might_have

Related object: L<HTGTDB::Result::UserQcResult>

=cut

__PACKAGE__->might_have(
  "user_qc_result",
  "HTGTDB::Result::UserQcResult",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_datas

Type: has_many

Related object: L<HTGTDB::Result::WellData>

=cut

__PACKAGE__->has_many(
  "well_datas",
  "HTGTDB::Result::WellData",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_design_instance_jump_previous_parents_well

Type: has_many

Related object: L<HTGTDB::Result::WellDesignInstanceJump>

=cut

__PACKAGE__->has_many(
  "well_design_instance_jump_previous_parents_well",
  "HTGTDB::Result::WellDesignInstanceJump",
  { "foreign.previous_parent_well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_design_instance_jumps_well

Type: has_many

Related object: L<HTGTDB::Result::WellDesignInstanceJump>

=cut

__PACKAGE__->has_many(
  "well_design_instance_jumps_well",
  "HTGTDB::Result::WellDesignInstanceJump",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 well_primers_reads

Type: has_many

Related object: L<HTGTDB::Result::WellPrimerReads>

=cut

__PACKAGE__->has_many(
  "well_primers_reads",
  "HTGTDB::Result::WellPrimerReads",
  { "foreign.well_id" => "self.well_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:trjm8AbYrOhur8QdQRGj7w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
