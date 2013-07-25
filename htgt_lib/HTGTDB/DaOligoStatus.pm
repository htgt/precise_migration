package HTGTDB::DaOligoStatus;
use strict;
use warnings;

use base 'DBIx::Class';
__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table("da_oligo_status");

#__PACKAGE__->add_columns(
#  "oligo_status_id"  => { data_type => 'char', size => 50 },
#  "oligo_status_desc",
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "oligo_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "oligo_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key("oligo_status_id");

__PACKAGE__->has_many( design_annotations => "HTGTDB::DesignAnnotation", 'oligo_status_id' );
__PACKAGE__->has_many( human_annotations => "HTGTDB::DaHumanAnnotation", 'oligo_status_id' );

1;
