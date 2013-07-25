use utf8;
package HTGTDB::Result::DesignUserCommentCategory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignUserCommentCategory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_USER_COMMENT_CATEGORIES>

=cut

__PACKAGE__->table("DESIGN_USER_COMMENT_CATEGORIES");

=head1 ACCESSORS

=head2 category_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 category_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 1000

=cut

__PACKAGE__->add_columns(
  "category_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "category_name",
  { data_type => "varchar2", is_nullable => 0, size => 1000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</category_id>

=back

=cut

__PACKAGE__->set_primary_key("category_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_user_comment_categ_uk1>

=over 4

=item * L</category_name>

=back

=cut

__PACKAGE__->add_unique_constraint("design_user_comment_categ_uk1", ["category_name"]);

=head1 RELATIONS

=head2 design_user_comments

Type: has_many

Related object: L<HTGTDB::Result::DesignUserComment>

=cut

__PACKAGE__->has_many(
  "design_user_comments",
  "HTGTDB::Result::DesignUserComment",
  { "foreign.category_id" => "self.category_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cGW4RDoNejKQtpqimKc3GA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
