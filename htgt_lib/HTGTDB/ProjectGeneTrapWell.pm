package HTGTDB::ProjectGeneTrapWell;

use strict;
use warnings;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('project_gene_trap_well');

#__PACKAGE__->add_columns(
#    qw/
#        gene_trap_well_id
#        project_id
#        splink_orientation
#    /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gene_trap_well_id",
  {
    data_type   => "integer",
    is_nullable => 0, # Primary keys are not nullable
    original    => { data_type => "number", size => [38, 0] },
  },
  "project_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "splink_orientation",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( __PACKAGE__->columns );
__PACKAGE__->belongs_to( project        => "HTGTDB::Project", 'project_id' );
__PACKAGE__->belongs_to( gene_trap_well => "HTGTDB::GeneTrapWell", 'gene_trap_well_id' );

return 1;

=head1 AUTHOR

Dan Klose dk3@sanger.ac.uk

=cut
