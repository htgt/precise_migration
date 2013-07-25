package HTGTDB::Chromosome;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('chromosome_dict');
#__PACKAGE__->add_columns(qw/chr_id name/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "chr_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_96_1_chromosome_dict",
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key('chr_id');

return 1;

