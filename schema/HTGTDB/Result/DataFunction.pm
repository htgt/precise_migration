use utf8;
package HTGTDB::Result::DataFunction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DataFunction

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DATA_FUNCTION>

=cut

__PACKAGE__->table("DATA_FUNCTION");

=head1 ACCESSORS

=head2 function_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_data_function'
  size: [10,0]

=head2 function_desc

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "function_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_data_function",
    size => [10, 0],
  },
  "function_desc",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</function_id>

=back

=cut

__PACKAGE__->set_primary_key("function_id");

=head1 RELATIONS

=head2 sources

Type: has_many

Related object: L<HTGTDB::Result::Source>

=cut

__PACKAGE__->has_many(
  "sources",
  "HTGTDB::Result::Source",
  { "foreign.function_id" => "self.function_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bU9B9zvlqpDAA09Ho9YgQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
