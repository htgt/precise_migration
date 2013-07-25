use utf8;
package HTGTDB::Result::DesignUserComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignUserComment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_USER_COMMENTS>

=cut

__PACKAGE__->table("DESIGN_USER_COMMENTS");

=head1 ACCESSORS

=head2 design_comment_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_design_user_comment'
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 600

=head2 visibility

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

=head2 edited_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 edited_date

  data_type: 'timestamp'
  default_value: systimestamp
  is_nullable: 0

=head2 category_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "design_comment_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_user_comment",
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_comment",
  { data_type => "varchar2", is_nullable => 1, size => 600 },
  "visibility",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "edited_user",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "edited_date",
  {
    data_type     => "timestamp",
    default_value => \"systimestamp",
    is_nullable   => 0,
  },
  "category_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_comment_id>

=back

=cut

__PACKAGE__->set_primary_key("design_comment_id");

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<HTGTDB::Result::DesignUserCommentCategory>

=cut

__PACKAGE__->belongs_to(
  "category",
  "HTGTDB::Result::DesignUserCommentCategory",
  { category_id => "category_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ayrRAniMIGZOnbX9GrrG4A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
