package HTGTDB::PcPrimerRead;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('pc_primer_read');

#__PACKAGE__->add_columns(
#    qw/
#      pc_primer_read_id
#      well_id
#      primer_name
#      loc_status
#      qcresult_status
#      align_length
#      pct_id
#      edit_user
#      edit_date
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "pc_primer_read_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_pc_primer_read",
    size => [10, 0],
  },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "primer_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);
# End of dbicdump add_columns data

__PACKAGE__->sequence('S_PC_PRIMER_READ');
__PACKAGE__->set_primary_key(qw/pc_primer_read_id/);
__PACKAGE__->add_unique_constraint( name_type => [qw/well_id primer_name/] );
__PACKAGE__->belongs_to( well => 'HTGTDB::Well', 'well_id' );
