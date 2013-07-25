use utf8;
package HTGTDB::Result::BuildInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::BuildInfo

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<BUILD_INFO>

=cut

__PACKAGE__->table("BUILD_INFO");

=head1 ACCESSORS

=head2 build_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 golden_path

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 mapmaster

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 core_version

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 run_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 software_ver

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "build_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "golden_path",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "mapmaster",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "core_version",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "run_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "software_ver",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</build_id>

=back

=cut

__PACKAGE__->set_primary_key("build_id");

=head1 RELATIONS

=head2 bacs

Type: has_many

Related object: L<HTGTDB::Result::Bac>

=cut

__PACKAGE__->has_many(
  "bacs",
  "HTGTDB::Result::Bac",
  { "foreign.build_id" => "self.build_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:550waqrkosQz14hN5rN3yw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
