package HTGTDB::DesignFinderAttempt;

use strict;
use warnings FATAL => 'all';

use base qw/DBIx::Class/;

__PACKAGE__->load_components( qw/InflateColumn::DateTime PK::Auto Core/ );

__PACKAGE__->table( 'design_finder_attempt' );

__PACKAGE__->sequence( 'DESIGN_ATTEMPTS_SEQUENCE' );

#__PACKAGE__->add_columns(
#      'design_attempt_id',
#      'attempt_date' => { data_type => 'date' },
#      'design_type',
#      'design_status',
#      'oligo_complete',
#      'failure_reason',
#      'ensembl_id',
#      'ensembl_version',
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_attempt_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "attempt_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "design_type",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "design_status",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "oligo_complete",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "failure_reason",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "ensembl_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_version",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key( 'design_attempt_id' );

__PACKAGE__->add_unique_constraint ( gene_ensver_type_date => [qw/ensembl_id ensembl_version design_type attempt_date/] );


1;
