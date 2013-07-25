use utf8;
package HTGTDB::Result::UpdateMethod;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::UpdateMethod

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<UPDATE_METHOD>

=cut

__PACKAGE__->table("UPDATE_METHOD");

=head1 ACCESSORS

=head2 update_method_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_update_method'
  size: [10,0]

=head2 update_method

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "update_method_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_update_method",
    size => [10, 0],
  },
  "update_method",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</update_method_id>

=back

=cut

__PACKAGE__->set_primary_key("update_method_id");

=head1 RELATIONS

=head2 sources

Type: has_many

Related object: L<HTGTDB::Result::Source>

=cut

__PACKAGE__->has_many(
  "sources",
  "HTGTDB::Result::Source",
  { "foreign.update_method_id" => "self.update_method_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+tShNHchH0LC5+HuEOoCnA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
