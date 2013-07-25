use utf8;
package HTGTDB::Result::CloneLibDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::CloneLibDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<CLONE_LIB_DICT>

=cut

__PACKAGE__->table("CLONE_LIB_DICT");

=head1 ACCESSORS

=head2 clone_lib_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_97_1_clone_lib_dict'
  size: [10,0]

=head2 library

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "clone_lib_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_97_1_clone_lib_dict",
    size => [10, 0],
  },
  "library",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</clone_lib_id>

=back

=cut

__PACKAGE__->set_primary_key("clone_lib_id");

=head1 RELATIONS

=head2 bacs

Type: has_many

Related object: L<HTGTDB::Result::Bac>

=cut

__PACKAGE__->has_many(
  "bacs",
  "HTGTDB::Result::Bac",
  { "foreign.clone_lib_id" => "self.clone_lib_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ng4TNvlwVXFtQJk4JifB3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
