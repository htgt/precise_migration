use utf8;
package HTGTDB::Result::DesignAudit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignAudit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_AUDIT>

=cut

__PACKAGE__->table("DESIGN_AUDIT");

=head1 ACCESSORS

=head2 design_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 target_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 build_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 design_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=head2 pseudo_plate

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 final_plate

  data_type: 'varchar2'
  is_nullable: 1
  size: 45

=head2 well_loc

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 design_parameter_id

  data_type: 'numeric'
  default_value: 0
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 locus_id

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 start_exon_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 end_exon_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 gene_build_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=head2 random_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 125

=head2 audit_date

  data_type: 'datetime'
  default_value: SYSTIMESTAMP
  is_nullable: 1
  original: {data_type => "date"}

=cut

__PACKAGE__->add_columns(
  "design_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "target_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "build_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_name",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "pseudo_plate",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "final_plate",
  { data_type => "varchar2", is_nullable => 1, size => 45 },
  "well_loc",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "design_parameter_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "locus_id",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "start_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "end_exon_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "gene_build_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
  "random_name",
  { data_type => "varchar2", is_nullable => 1, size => 125 },
  "audit_date",
  {
    data_type     => "datetime",
    default_value => \"SYSTIMESTAMP",
    is_nullable   => 1,
    original      => { data_type => "date" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:t7fhRToUq5W/qlGjQka11Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
