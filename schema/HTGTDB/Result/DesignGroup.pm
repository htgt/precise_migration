use utf8;
package HTGTDB::Result::DesignGroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignGroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_GROUP>

=cut

__PACKAGE__->table("DESIGN_GROUP");

=head1 ACCESSORS

=head2 design_group_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "design_group_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_group_id>

=back

=cut

__PACKAGE__->set_primary_key("design_group_id");

=head1 RELATIONS

=head2 design_design_groups

Type: has_many

Related object: L<HTGTDB::Result::DesignDesignGroup>

=cut

__PACKAGE__->has_many(
  "design_design_groups",
  "HTGTDB::Result::DesignDesignGroup",
  { "foreign.design_group_id" => "self.design_group_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RfFxZqNhpAAKfEm3G/WV2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
