use utf8;
package HTGTDB::Result::PlateComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::PlateComment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PLATE_COMMENT>

=cut

__PACKAGE__->table("PLATE_COMMENT");

=head1 ACCESSORS

=head2 plate_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 plate_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 created_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 created_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 plate_comment_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_plate_comment'
  size: [10,0]

=head2 edit_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 edit_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "plate_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "plate_comment",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "plate_comment_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_plate_comment",
    size => [10, 0],
  },
  "edit_user",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "edit_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</plate_comment_id>

=back

=cut

__PACKAGE__->set_primary_key("plate_comment_id");

=head1 RELATIONS

=head2 plate

Type: belongs_to

Related object: L<HTGTDB::Result::Plate>

=cut

__PACKAGE__->belongs_to(
  "plate",
  "HTGTDB::Result::Plate",
  { plate_id => "plate_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vN0O2HiuicxwHuc2IzUChg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
