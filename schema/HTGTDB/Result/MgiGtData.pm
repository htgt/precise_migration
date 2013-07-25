use utf8;
package HTGTDB::Result::MgiGtData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiGtData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_GT_DATA>

=cut

__PACKAGE__->table("MGI_GT_DATA");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 mgi_gt_count

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 tigm_4_gt_count

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 igtc_gt_count

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "mgi_gt_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "tigm_4_gt_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "igtc_gt_count",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</mgi_accession_id>

=back

=cut

__PACKAGE__->set_primary_key("mgi_accession_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:22
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KIlkuXZQxyR5pQXZUscGlw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
