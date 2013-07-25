package HTGTDB::PrimerBandSize;

use strict;
use warnings FATAL => 'all';

use base 'DBIx::Class';

__PACKAGE__->load_components( 'Core' );

__PACKAGE__->table( 'primer_band_size' );

#__PACKAGE__->add_columns( qw( project_id
#                              GF3_R1RN
#                              GF3_LAR2
#                              GF3_LAR3
#                              GF3_LAR5
#                              GF3_LAR7
#                              GF3_LAVI
#                              GF4_R1RN
#                              GF4_LAR2
#                              GF4_LAR3
#                              GF4_LAR5
#                              GF4_LAR7
#                              GF4_LAVI
#                              PNFLR_GR3
#                              PNFLR_GR4
#                              RAF2_GR3
#                              RAF2_GR4
#                              JOEL2_GR3
#                              JOEL2_GR4
#                              FRTL_GR3
#                              FRTL_GR4
#                              FRTL3_GR3
#                              FRTL3_GR4
#                              LF_GR3
#                              LF_GR4
#                        ) );

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "project_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_r1rn",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_lar3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_r1rn",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_lar3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "pnflr_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "pnflr_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "raf2_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "raf2_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "joel2_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "joel2_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "frtl_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "frtl_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_lar2",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_lar5",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_lar7",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf3_lavi",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_lar2",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_lar5",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_lar7",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gf4_lavi",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "frtl3_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "frtl3_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_gr3",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "lf_gr4",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'project_id' );

__PACKAGE__->belongs_to( project => 'HTGTDB::Project', 'project_id' );

1;

__END__
