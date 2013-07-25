package HTGTDB::DesignTaqmanPlate;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_taqman_plate');

__PACKAGE__->sequence('S_DESIGN_TAQMAN_PLATE');

#__PACKAGE__->add_columns(
#    qw(
#        taqman_plate_id
#        name
#    )
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "taqman_plate_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_taqman_plate",
    size => [8, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('taqman_plate_id');

__PACKAGE__->has_many( taqman_assays => "HTGTDB::DesignTaqmanAssay", 'taqman_plate_id' );

1;

__END__
