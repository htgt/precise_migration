use utf8;
package HTGTDB::Result::DesignInstanceStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignInstanceStatus - statuses applied to a design instance

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_INSTANCE_STATUS>

=cut

__PACKAGE__->table("DESIGN_INSTANCE_STATUS");

=head1 ACCESSORS

=head2 design_instance_status_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

unique id for the design instance status type

=head2 design_instance_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

unique id for the design instance

=head2 status_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

date this status was entered

=head2 is_current

  data_type: 'char'
  is_nullable: 1
  size: 1

whether this status is the most current

=head2 id_role

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

role id for the person who recorded the status change

=cut

__PACKAGE__->add_columns(
  "design_instance_status_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_instance_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "status_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "is_current",
  { data_type => "char", is_nullable => 1, size => 1 },
  "id_role",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_instance_status_id>

=item * L</design_instance_id>

=item * L</status_date>

=back

=cut

__PACKAGE__->set_primary_key(
  "design_instance_status_id",
  "design_instance_id",
  "status_date",
);

=head1 RELATIONS

=head2 design_instance_status

Type: belongs_to

Related object: L<HTGTDB::Result::DesignInstanceStatusDict>

=cut

__PACKAGE__->belongs_to(
  "design_instance_status",
  "HTGTDB::Result::DesignInstanceStatusDict",
  { design_instance_status_id => "design_instance_status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YidIv3hyyruLuZ6vcGNb/A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
