use utf8;
package HTGTDB::Result::ProjectGeneTrapWell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ProjectGeneTrapWell

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT_GENE_TRAP_WELL>

=cut

__PACKAGE__->table("PROJECT_GENE_TRAP_WELL");

=head1 ACCESSORS

=head2 gene_trap_well_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 project_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 splink_orientation

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "gene_trap_well_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "project_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "splink_orientation",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FmeG1Qs949N/ypIMDcnkCg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
