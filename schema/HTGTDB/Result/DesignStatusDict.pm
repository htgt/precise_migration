use utf8;
package HTGTDB::Result::DesignStatusDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignStatusDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_STATUS_DICT>

=cut

__PACKAGE__->table("DESIGN_STATUS_DICT");

=head1 ACCESSORS

=head2 design_status_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_103_1_design_status_dict'
  size: [10,0]

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "design_status_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_103_1_design_status_dict",
    size => [10, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_status_id>

=back

=cut

__PACKAGE__->set_primary_key("design_status_id");

=head1 RELATIONS

=head2 design_statuses

Type: has_many

Related object: L<HTGTDB::Result::DesignStatus>

=cut

__PACKAGE__->has_many(
  "design_statuses",
  "HTGTDB::Result::DesignStatus",
  { "foreign.design_status_id" => "self.design_status_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nLzodc2lGsuEv7x1SBvuGA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
