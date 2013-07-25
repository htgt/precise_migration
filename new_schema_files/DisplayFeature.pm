package HTGTDB::DisplayFeature;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
David K. Jackson <david.jackson@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('display_feature');
__PACKAGE__->sequence('S_DISPLAY_FEATURE');

#__PACKAGE__->add_columns(qw/
#			 assembly_id
#			 display_feature_id
#			 gene_build_id 
#			 feature_id
#			 display_feature_type 
#			 display_feature_group 
#			 chr_id 
#			 feature_start
#			 feature_end
#			 feature_strand
#			 created_date
#			 created_user
#			 label
#			 /);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "display_feature_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_display_feature",
    size => [10, 0],
  },
  "gene_build_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "display_feature_type",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "display_feature_group",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "chr_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "created_user",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "label",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "assembly_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('display_feature_id');
__PACKAGE__->belongs_to(feature=>"HTGTDB::Feature",'feature_id');
__PACKAGE__->belongs_to(chromosome=>"HTGTDB::Chromosome",'chr_id');

return 1;

