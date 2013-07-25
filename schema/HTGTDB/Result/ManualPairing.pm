use utf8;
package HTGTDB::Result::ManualPairing;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ManualPairing

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MANUAL_PAIRING>

=cut

__PACKAGE__->table("MANUAL_PAIRING");

=head1 ACCESSORS

=head2 manual_pairing_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_manual_pairing'
  size: [10,0]

=head2 gb_gene1_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 gb_gene2_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 comments

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 source

  data_type: 'varchar2'
  is_nullable: 1
  size: 128

=head2 curate_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "manual_pairing_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_manual_pairing",
    size => [10, 0],
  },
  "gb_gene1_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "gb_gene2_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "comments",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "source",
  { data_type => "varchar2", is_nullable => 1, size => 128 },
  "curate_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yNtgNwk7tRuom51ompMJOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
