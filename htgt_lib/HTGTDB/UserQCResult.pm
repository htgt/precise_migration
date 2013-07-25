package HTGTDB::UserQCResult;

use strict;
use warnings;

=head1 AUTHOR

Wanjuan Yang ( wy1@sanger.ac.uk )

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('user_qc_result');
__PACKAGE__->sequence('S_USER_QC_RESULT');
#__PACKAGE__->add_columns(
#    'user_qc_result_id',
#    'well_id',
#    'five_lrpcr',
#    'three_lrpcr'
#			 );

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
  "five_lrpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "three_lrpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "user_qc_result_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data#

__PACKAGE__->set_primary_key('user_qc_result_id');
__PACKAGE__->belongs_to( well => 'HTGTDB::Well', 'well_id');

1;


