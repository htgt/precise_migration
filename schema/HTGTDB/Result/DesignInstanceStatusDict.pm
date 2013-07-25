use utf8;
package HTGTDB::Result::DesignInstanceStatusDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignInstanceStatusDict - dictionary of design instance statuses

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_INSTANCE_STATUS_DICT>

=cut

__PACKAGE__->table("DESIGN_INSTANCE_STATUS_DICT");

=head1 ACCESSORS

=head2 design_instance_status_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

surrogate key for a design instance status type

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

description of the design instance status type

=cut

__PACKAGE__->add_columns(
  "design_instance_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_instance_status_id>

=back

=cut

__PACKAGE__->set_primary_key("design_instance_status_id");

=head1 RELATIONS

=head2 design_instance_statuses

Type: has_many

Related object: L<HTGTDB::Result::DesignInstanceStatus>

=cut

__PACKAGE__->has_many(
  "design_instance_statuses",
  "HTGTDB::Result::DesignInstanceStatus",
  {
    "foreign.design_instance_status_id" => "self.design_instance_status_id",
  },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:psaGsA244XV1RlqbBWvgDg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
