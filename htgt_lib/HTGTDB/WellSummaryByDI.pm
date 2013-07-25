package HTGTDB::WellSummaryByDI;
use strict;

=head1 AUTHOR

David K Jackson <dj3@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('well_summary_by_di');
__PACKAGE__->add_columns(
    qw/
      project_id
      build_gene_id
      gene_id
      design_instance_id
      design_plate_name
      design_well_name
      design_well_id
      bac
      pcs_plate_name
      pcs_well_name
      pcs_well_id
      pc_qctest_result_id
      pc_pass_level
      pcs_distribute
      pgdgr_plate_name
      pgdgr_well_name
      pgdgr_well_id
      pg_qctest_result_id
      pg_pass_level
      cassette
      backbone
      pgdgr_distribute
      ep_plate_name
      ep_well_name
      ep_well_id
      es_cell_line
      colonies_picked
      total_colonies
      epd_plate_name
      epd_well_name
      epd_well_id
      epd_qctest_result_id
      epd_pass_level
      epd_distribute
      allele_name
      targeted_trap
      /
);

__PACKAGE__->set_primary_key(qw(design_well_id pcs_well_id pgdgr_well_id ep_well_id epd_well_id));
__PACKAGE__->belongs_to( project => 'HTGTDB::Project', 'project_id' );
__PACKAGE__->belongs_to( gene => 'HTGTDB::GnmGene', 'gene_id' );
__PACKAGE__->belongs_to( build_gene => 'HTGTDB::GnmGeneBuildGene', 'build_gene_id' );
__PACKAGE__->belongs_to( design_instance => 'HTGTDB::DesignInstance', 'design_instance_id');
__PACKAGE__->belongs_to( design_well => 'HTGTDB::Well', 'design_well_id');
__PACKAGE__->belongs_to( pcs_well => 'HTGTDB::Well', 'pcs_well_id');
__PACKAGE__->belongs_to( pgdgr_well => 'HTGTDB::Well', 'pgdgr_well_id');
__PACKAGE__->belongs_to( epd_well => 'HTGTDB::Well', 'epd_well_id');

__PACKAGE__->add_unique_constraint( unique_epd_well_id => [ qw/epd_well_id/ ] );


return 1;
