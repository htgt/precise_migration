package HTGTDB::AlleleName;
use strict;
use warnings;

=head1 AUTHOR

David K. Jackson

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('Allele_Name');
#__PACKAGE__->add_columns(
#    qw/
#       allele_name_id
#       allele_id
#       mgi_symbol
#       labcode
#       iteration
#       name
#       targeted_trap
#      /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "allele_name_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_allele_name",
    size => 126,
  },
  "allele_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_symbol",
  { data_type => "varchar2", is_nullable => 0, size => 80 },
  "labcode",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "iteration",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 160 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/allele_name_id/);
__PACKAGE__->add_unique_constraint( allelename_name => [qw/name/] );
__PACKAGE__->sequence('S_ALLELE_NAME');

__PACKAGE__->belongs_to( allele => 'HTGTDB::Allele', 'allele_id' );

sub current_allele_name {
  my ($this)=@_;
  return $this->allele->current_allele_name;
}


return 1;

