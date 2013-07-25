use utf8;
package HTGTDB::Result::BlastBac;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::BlastBac

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<BLAST_BAC>

=cut

__PACKAGE__->table("BLAST_BAC");

=head1 ACCESSORS

=head2 bac_clone_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 blast_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "bac_clone_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "blast_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 RELATIONS

=head2 blast

Type: belongs_to

Related object: L<HTGTDB::Result::FeatureBlast>

=cut

__PACKAGE__->belongs_to(
  "blast",
  "HTGTDB::Result::FeatureBlast",
  { blast_id => "blast_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ybfFjRGFaQB4EQCCCWvBgA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
