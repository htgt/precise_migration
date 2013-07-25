use utf8;
package HTGTDB::Result::ProjectStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ProjectStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT_STATUS>

=cut

__PACKAGE__->table("PROJECT_STATUS");

=head1 ACCESSORS

=head2 project_status_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 order_by

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [3,0]

=head2 code

  data_type: 'varchar2'
  is_nullable: 0
  size: 10

=head2 stage

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 status_type

  data_type: 'varchar2'
  default_value: 'normal'
  is_nullable: 1
  size: 100

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 is_terminal

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=head2 does_not_compete_for_latest

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [1,0]

=cut

__PACKAGE__->add_columns(
  "project_status_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "order_by",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [3, 0],
  },
  "code",
  { data_type => "varchar2", is_nullable => 0, size => 10 },
  "stage",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "status_type",
  {
    data_type => "varchar2",
    default_value => "normal",
    is_nullable => 1,
    size => 100,
  },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "is_terminal",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "does_not_compete_for_latest",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [1, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_status_id>

=back

=cut

__PACKAGE__->set_primary_key("project_status_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SzYpW8fTWcwcJjUgouun4Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
