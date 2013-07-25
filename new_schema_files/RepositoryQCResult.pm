package HTGTDB::RepositoryQCResult;

use strict;
use warnings;

=head1 AUTHOR

Wanjuan Yang (wy1@sanger.ac.uk)

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components( qw/InflateColumn::DateTime PK::Auto Core/ );
__PACKAGE__->table( 'repository_qc_result' );
__PACKAGE__->sequence( 'S_REPOSITORY_QC_RESULT' );
#__PACKAGE__->add_columns(
#  "well_id",
#  {
#    data_type      => "integer",
#    is_foreign_key => 1,
#    is_nullable    => 0,
#    original       => { data_type => "number", size => [38, 0] },
#  },
#  "first_test_start_date",
#  {
#    data_type   => "datetime",
#    is_nullable => 1,
#    original    => { data_type => "date" },
#  },
#  "latest_test_completion_date",
#  {
#    data_type   => "datetime",
#    is_nullable => 1,
#    original    => { data_type => "date" },
#  },
#  "karyotype_low",
#  {
#    data_type   => "double precision",
#    is_nullable => 1,
#    original    => { data_type => "float", size => 126 },
#  },
#  "karyotype_high",
#  {
#    data_type   => "double precision",
#    is_nullable => 1,
#    original    => { data_type => "float", size => 126 },
#  },
#  "copy_number_equals_one",
#  { data_type => "varchar2", is_nullable => 1, size => 4000 },
#  "threep_loxp_srpcr",
#  { data_type => "varchar2", is_nullable => 1, size => 4000 },
#  "fivep_loxp_srpcr",
#  { data_type => "varchar2", is_nullable => 1, size => 4000 },
#  "vector_integrity",
#  { data_type => "varchar2", is_nullable => 1, size => 4000 },
#  "repository_qc_result_id",
#  {
#    data_type => "numeric",
#    is_nullable => 0,
#    original => { data_type => "number" },
#    size => 126,
#  },
#  "loss_of_allele",
#  { data_type => "varchar2", is_nullable => 1, size => 20 },
#  "threep_loxp_taqman",
#  { data_type => "varchar2", is_nullable => 1, size => 20 },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "well_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "first_test_start_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "latest_test_completion_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "karyotype_low",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "karyotype_high",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "copy_number_equals_one",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "threep_loxp_srpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "fivep_loxp_srpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "vector_integrity",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "repository_qc_result_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "loss_of_allele",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "threep_loxp_taqman",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);
# End of dbicdump add_columns data
#__PACKAGE__->add_columns(
#    'repository_qc_result_id',
#    'well_id',
#    'first_test_start_date' => { data_type => 'date' },
#    'latest_test_completion_date' => { data_type => 'date' }, 
#    'karyotype_low',           
#    'karyotype_high',
#    'copy_number_equals_one',
#    'threep_loxp_srpcr',
#    'fivep_loxp_srpcr',
#    'vector_integrity',
#    'loss_of_allele',
#    'threep_loxp_taqman'
#);

__PACKAGE__->set_primary_key( 'repository_qc_result_id' );
__PACKAGE__->belongs_to( well => 'HTGTDB::Well', "well_id" );

1;
