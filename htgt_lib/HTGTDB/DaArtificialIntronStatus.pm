package HTGTDB::DaArtificialIntronStatus;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table("da_artificial_intron_status");

#__PACKAGE__->add_columns(
#  "artificial_intron_status_id" => { data_type => 'char', size => 50 },
#  "artificial_intron_status_desc",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "artificial_intron_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "artificial_intron_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("artificial_intron_status_id");

__PACKAGE__->has_many( design_annotations => "HTGTDB::DesignAnnotation", 'artificial_intron_status_id' );
__PACKAGE__->has_many( human_annotations => "HTGTDB::DaHumanAnnotation", 'artificial_intron_status_id' );

1;
