package HTGTDB::DesignTaqmanAssay;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_taqman_assay');

__PACKAGE__->sequence('S_DESIGN_TAQMAN_ASSAY');

#__PACKAGE__->add_columns(
#    qw(
#        design_taqman_assay_id
#        design_id
#        well_name
#        taqman_plate_id
#        assay_id
#        deleted_region
#        forward_primer_seq
#        reverse_primer_seq
#        reporter_probe_seq
#        edit_user
#        edit_date
#    )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_taqman_assay_id",
  {
#    data_type => "numeric", # not in SQLite
    data_type => "integer",
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
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('design_taqman_assay_id');

__PACKAGE__->belongs_to( design => "HTGTDB::Design", 'design_id' );

__PACKAGE__->belongs_to( taqman_plate => "HTGTDB::DesignTaqmanPlate", 'taqman_plate_id' );


1;

__END__

