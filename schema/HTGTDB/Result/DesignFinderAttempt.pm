use utf8;
package HTGTDB::Result::DesignFinderAttempt;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignFinderAttempt

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_FINDER_ATTEMPT>

=cut

__PACKAGE__->table("DESIGN_FINDER_ATTEMPT");

=head1 ACCESSORS

=head2 design_attempt_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 attempt_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 design_type

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 design_status

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 oligo_complete

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 failure_reason

  data_type: 'varchar2'
  is_nullable: 1
  size: 50

=head2 ensembl_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 ensembl_version

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=cut

__PACKAGE__->add_columns(
  "design_attempt_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "attempt_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "design_type",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "design_status",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "oligo_complete",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "failure_reason",
  { data_type => "varchar2", is_nullable => 1, size => 50 },
  "ensembl_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_version",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_attempt_id>

=back

=cut

__PACKAGE__->set_primary_key("design_attempt_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<design_finder_attempts_uk1>

=over 4

=item * L</ensembl_id>

=item * L</ensembl_version>

=item * L</design_type>

=item * L</attempt_date>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "design_finder_attempts_uk1",
  ["ensembl_id", "ensembl_version", "design_type", "attempt_date"],
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SM6TWLOAOIlJYAPJz9qUXA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
