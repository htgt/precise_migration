package HTGTDB::WellData;
use strict;
use warnings;
use HTGT::Constants qw( %CASSETTES %BACKBONES );

=head1 AUTHOR

Darren Oakley
Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('well_data');

#__PACKAGE__->add_columns(
#  "data_value",
#  { data_type => "varchar2", is_nullable => 1, size => 600 },
#  "well_id",
#  {
#    data_type => "numeric",
#    is_foreign_key => 1,
#    is_nullable => 1,
#    original => { data_type => "number" },
#    size => [10, 0],
#  },
#  "well_data_id",
#  {
#    data_type => "numeric",
#    is_auto_increment => 1,
#    is_nullable => 0,
#    original => { data_type => "number" },
#    sequence => "s_well_data",
#    size => [10, 0],
#  },
#  "data_type",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "edit_user",
#  { data_type => "varchar2", is_nullable => 1, size => 100 },
#  "edit_date",
#  {
#    data_type     => "datetime",
#    default_value => \"current_timestamp",
#    is_nullable   => 1,
#    original      => { data_type => "date", default_value => \"sysdate" },
#  },
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "data_value",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "well_data_id",
  {
      #data_type => "numeric",
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_well_data",
    size => [10, 0],
  },
  "data_type",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);
# End of dbicdump add_columns data

#__PACKAGE__->add_columns(
#    qw/
#        well_data_id
#        data_type
#        data_value
#        well_id
#        edit_user
#        edit_date
#        /
#);

__PACKAGE__->set_primary_key(qw/well_data_id/);
__PACKAGE__->add_unique_constraint(
    well_id_data_type => [qw/well_id data_type/] );
__PACKAGE__->sequence('S_WELL_DATA');
__PACKAGE__->belongs_to( well => 'HTGTDB::Well', 'well_id' );

# Utility functions:
our @EXPORT;
push( @EXPORT, qw/get_all_backbones get_all_cassettes/ );

=head2 get_all_backbones

Returns a hash reference of all of the possible plasmid backbones, stored in HTGT::Constants

=cut

sub get_all_backbones {
    my %backbones = %BACKBONES;
    return \%backbones;
}

=head2 get_all_cassettes

Returns a hash reference of all of the possible targeting cassettes, stored in HTGT::Constants

=cut

sub get_all_cassettes {
    my %cassettes = %CASSETTES;
    return \%cassettes;
}

return 1;

