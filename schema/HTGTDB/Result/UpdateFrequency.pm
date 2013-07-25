use utf8;
package HTGTDB::Result::UpdateFrequency;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::UpdateFrequency

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<UPDATE_FREQUENCY>

=cut

__PACKAGE__->table("UPDATE_FREQUENCY");

=head1 ACCESSORS

=head2 update_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_update_frequency'
  size: [10,0]

=head2 frequency

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "update_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_update_frequency",
    size => [10, 0],
  },
  "frequency",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</update_id>

=back

=cut

__PACKAGE__->set_primary_key("update_id");

=head1 RELATIONS

=head2 sources

Type: has_many

Related object: L<HTGTDB::Result::Source>

=cut

__PACKAGE__->has_many(
  "sources",
  "HTGTDB::Result::Source",
  { "foreign.update_id" => "self.update_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/8uOWKsrYk6kkdbpoXWSCQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
