use utf8;
package HTGTDB::Result::DesignStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_STATUS>

=cut

__PACKAGE__->table("DESIGN_STATUS");

=head1 ACCESSORS

=head2 design_status_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 design_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 status_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=head2 is_current

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 id_role

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "design_status_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "status_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
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

=item * L</design_status_id>

=item * L</design_id>

=back

=cut

__PACKAGE__->set_primary_key("design_status_id", "design_id");

=head1 RELATIONS

=head2 design

Type: belongs_to

Related object: L<HTGTDB::Result::Design>

=cut

__PACKAGE__->belongs_to(
  "design",
  "HTGTDB::Result::Design",
  { design_id => "design_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_status

Type: belongs_to

Related object: L<HTGTDB::Result::DesignStatusDict>

=cut

__PACKAGE__->belongs_to(
  "design_status",
  "HTGTDB::Result::DesignStatusDict",
  { design_status_id => "design_status_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:X3iIdDT0bRMIM/nGF7BseA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
