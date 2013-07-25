use utf8;
package HTGTDB::Result::DesignTaqmanPlate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignTaqmanPlate

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_TAQMAN_PLATE>

=cut

__PACKAGE__->table("DESIGN_TAQMAN_PLATE");

=head1 ACCESSORS

=head2 taqman_plate_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_design_taqman_plate'
  size: [8,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=cut

__PACKAGE__->add_columns(
  "taqman_plate_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_design_taqman_plate",
    size => [8, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
);

=head1 PRIMARY KEY

=over 4

=item * L</taqman_plate_id>

=back

=cut

__PACKAGE__->set_primary_key("taqman_plate_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_taqman_plate_uk1>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("design_taqman_plate_uk1", ["name"]);

=head1 RELATIONS

=head2 design_taqman_assays

Type: has_many

Related object: L<HTGTDB::Result::DesignTaqmanAssay>

=cut

__PACKAGE__->has_many(
  "design_taqman_assays",
  "HTGTDB::Result::DesignTaqmanAssay",
  { "foreign.taqman_plate_id" => "self.taqman_plate_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xGDk17x57xBZ9fs+SkTV9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
