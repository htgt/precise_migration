package HTGTDB::NewWellSummary;

# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgtdb/trunk/lib/HTGTDB/GRGeneStatus.pm $
# $LastChangedRevision: 1392 $
# $LastChangedDate: 2010-03-29 17:34:18 +0100 (Mon, 29 Mar 2010) $
# $LastChangedBy: rm7 $

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(InflateColumn::DateTime Core));

__PACKAGE__->table('new_well_summary');

#__PACKAGE__->add_columns(
#    primary_key_for_dbix_class => { is_auto_increment => 1 },
#    qw(
#        mgi_gene_id
#        project_id
#        design_instance_id
#        design_plate_name
#        design_well_name
#        design_well_id
#        bac
#        pcs_plate_name
#        pcs_well_name
#        pcs_well_id
#        pc_qctest_result_id
#        pc_pass_level
#        pcs_distribute
#        pgdgr_plate_name
#        pgdgr_well_name
#        pgdgr_well_id
#        pg_qctest_result_id
#        pg_pass_level
#        cassette
#        backbone
#        pgdgr_distribute
#        pgdgr_clone_name
#        dna_plate_name
#        dna_well_name
#        dna_well_id
#        dna_qctest_result_id
#        dna_pass_level
#        dna_distribute
#        dna_status
#        ep_plate_name
#        ep_well_name
#        ep_well_id
#        es_cell_line
#        colonies_picked
#        total_colonies
#        epd_plate_name
#        epd_well_name
#        epd_well_id
#        epd_qctest_result_id
#        epd_pass_level
#        epd_distribute
#        epd_five_arm_pass_level
#        epd_three_arm_pass_level
#        epd_loxp_pass_level
#        targeted_trap
#        allele_name
#        fp_plate_name
#        fp_well_name
#        fp_well_id
#  ),
#    map { $_ . '_created_date' => { data_type => 'date' } }
#        qw( design_plate pcs_plate pgdgr_plate dna_plate ep_plate epd_plate fp_plate )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "project_id",
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
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "design_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "design_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "design_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pcs_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pcs_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "pc_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pc_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pcs_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "pgdgr_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "pgdgr_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pg_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "pg_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_clone_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "cassette",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "backbone",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "pgdgr_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "dna_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "dna_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "dna_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "dna_status",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "ep_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "ep_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "ep_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "es_cell_line",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "colonies_picked",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "total_colonies",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "epd_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "epd_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_qctest_result_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "epd_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_distribute",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "allele_name",
  { data_type => "varchar2", is_nullable => 1, size => 160 },
  "fp_plate_name",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "fp_plate_created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "fp_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "fp_well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "epd_five_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_three_arm_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "epd_loxp_pass_level",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "primary_key_for_dbix_class",
  {
      #data_type => "numeric",
    data_type => "integer",
    is_nullable => 0, # Primary key is not nullable
    original => { data_type => "number" },
    size => [10, 0],
    is_auto_increment => 1,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->add_unique_constraint(
    [   qw(design_well_id pcs_well_id pgdgr_well_id dna_well_id ep_well_id epd_well_id fp_well_id)
    ]
);

__PACKAGE__->set_primary_key( 'primary_key_for_dbix_class' );

__PACKAGE__->belongs_to( mgi_gene => 'HTGTDB::MGIGene', 'mgi_gene_id' );

__PACKAGE__->belongs_to( project => 'HTGTDB::Project', 'project_id' );

__PACKAGE__->belongs_to(
    design_instance => 'HTGTDB::DesignInstance',
    'design_instance_id'
);

__PACKAGE__->belongs_to(
    design_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.design_well_id' }
);

__PACKAGE__->belongs_to(
    pcs_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.pcs_well_id' }
);

__PACKAGE__->belongs_to(
    pgdgr_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.pgdgr_well_id' }
);

__PACKAGE__->belongs_to(
    dna_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.dna_well_id' }
);

__PACKAGE__->belongs_to(
    ep_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.ep_well_id' }
);

__PACKAGE__->belongs_to(
    epd_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.epd_well_id' }
);

__PACKAGE__->belongs_to(
    fp_well => 'HTGTDB::Well',
    { 'foreign.well_id' => 'self.fp_well_id' }
);

1;

__END__
