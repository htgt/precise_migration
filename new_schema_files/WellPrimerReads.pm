package HTGTDB::WellPrimerReads;

use strict;
use warnings;

=head1 AUTHOR

Darren Oakley

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('well_primer_reads');
#__PACKAGE__->add_columns(
#    qw/
#        well_id
#        clone_plate
#        primer_design_instance_id
#        lf_loc_status
#        lf_align_length
#        lf_pct_id
#        lf_qcresult_status
#        lr_loc_status
#        lr_align_length
#        lr_pct_id
#        lr_qcresult_status
#        lrr_loc_status
#        lrr_align_length
#        lrr_pct_id
#        lrr_qcresult_status
#        r1r_loc_status
#        r1r_align_length
#        r1r_pct_id
#        r1r_qcresult_status
#        r2r_loc_status
#        r2r_align_length
#        r2r_pct_id
#        r2r_qcresult_status
#    /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "clone_plate",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "primer_design_instance_id",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lf_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lf_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lr_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lr_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lr_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lrr_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "lrr_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lrr_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lrr_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r1r_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r1r_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r1r_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r1r_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r2r_loc_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "r2r_align_length",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r2r_pct_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "r2r_qcresult_status",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/well_id clone_plate/);

__PACKAGE__->belongs_to( well => 'HTGTDB::Well', 'well_id' );

return 1;

