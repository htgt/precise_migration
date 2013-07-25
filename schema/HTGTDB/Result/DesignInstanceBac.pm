use utf8;
package HTGTDB::Result::DesignInstanceBac;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignInstanceBac

=head1 DESCRIPTION

Which BAC clone will be used to construct a vector from a design in this design instance

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_INSTANCE_BAC>

=cut

__PACKAGE__->table("DESIGN_INSTANCE_BAC");

=head1 ACCESSORS

=head2 design_instance_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

unique id for the design instance

=head2 bac_clone_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

unique id for the BAC clone

=head2 bac_plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=cut

__PACKAGE__->add_columns(
  "design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_clone_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "bac_plate",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_instance_id>

=item * L</bac_clone_id>

=back

=cut

__PACKAGE__->set_primary_key("design_instance_id", "bac_clone_id");

=head1 RELATIONS

=head2 bac_clone

Type: belongs_to

Related object: L<HTGTDB::Result::Bac>

=cut

__PACKAGE__->belongs_to(
  "bac_clone",
  "HTGTDB::Result::Bac",
  { bac_clone_id => "bac_clone_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 design_instance

Type: belongs_to

Related object: L<HTGTDB::Result::DesignInstance>

=cut

__PACKAGE__->belongs_to(
  "design_instance",
  "HTGTDB::Result::DesignInstance",
  { design_instance_id => "design_instance_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pTZlXsGu7Ex74o0eFDGzvQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
