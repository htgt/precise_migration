package HTGTDB::Feature;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer
David K Jackson <david.jackson@sanger.ac.uk>

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);


__PACKAGE__->table('feature');
__PACKAGE__->sequence('S_105_1_FEATURE');

#__PACKAGE__->add_columns(qw/
#    feature_id 
#    feature_type_id 
#    design_id 
#    chr_id 
#    feature_start 
#    feature_end 
#    allocate_to_instance
#    /);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "feature_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_105_1_feature",
    size => [10, 0],
  },
  "feature_type_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_start",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "feature_end",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "allocate_to_instance",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key(qw/feature_id/);
__PACKAGE__->belongs_to(design=>"HTGTDB::Design",'design_id');
__PACKAGE__->belongs_to(feature_type=>"HTGTDB::FeatureType",'feature_type_id');
__PACKAGE__->belongs_to(chromosome=>"HTGTDB::Chromosome","chr_id");
__PACKAGE__->has_many(feature_data=>"HTGTDB::FeatureData",'feature_id');
__PACKAGE__->has_many(display_features=>"HTGTDB::DisplayFeature",'feature_id');

=head2 is_mrc

Helper function to look up "make reverse complement" feature data.

=cut

sub is_mrc {
  my $f = shift;
  my $rc = $f->feature_data->find({q(feature_data_type.description)=>q(make reverse complement)},{join=>q(feature_data_type)});
  return $rc?$rc->data_item:undef;
}

=head2 get_seq_str

Helper function to look up sequence feature data string.

=cut

sub get_seq_str {
  local $_ = shift;
  return $_->feature_data->find({q(feature_data_type.description)=>q(sequence)},{join=>q(feature_data_type)})->data_item;
}

return 1;

