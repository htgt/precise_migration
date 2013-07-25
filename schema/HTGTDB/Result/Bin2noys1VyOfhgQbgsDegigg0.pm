use utf8;
package HTGTDB::Result::Bin2noys1VyOfhgQbgsDegigg0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Bin2noys1VyOfhgQbgsDegigg0

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<"BIN$2noys1VyOFHgQBGsDEgigg==$0">

=cut

__PACKAGE__->table(\"\"BIN\$2noys1VyOFHgQBGsDEgigg==\$0\"");

=head1 ACCESSORS

=head2 human_annotation_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 da_test_set_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "human_annotation_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "da_test_set_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</human_annotation_id>

=item * L</da_test_set_id>

=back

=cut

__PACKAGE__->set_primary_key("human_annotation_id", "da_test_set_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3ojC+dbCpg7LCRf+9xhIkA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
