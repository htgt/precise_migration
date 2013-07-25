use utf8;
package HTGTDB::Result::AvailableEsClones2;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::AvailableEsClones2

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<AVAILABLE_ES_CLONES_2>

=cut

__PACKAGE__->table("AVAILABLE_ES_CLONES_2");

=head1 ACCESSORS

=head2 epd_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 24

=head2 design_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 is_eucomm

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 is_komp_csd

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "epd_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 24 },
  "design_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "is_eucomm",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "is_komp_csd",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:weX+Sn7lxjn3Y8Cbe+Ia8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
