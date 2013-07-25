use utf8;
package HTGTDB::Result::RepositoryQcResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::RepositoryQcResult

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<REPOSITORY_QC_RESULT>

=cut

__PACKAGE__->table("REPOSITORY_QC_RESULT");

=head1 ACCESSORS

=head2 well_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 first_test_start_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 latest_test_completion_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 karyotype_low

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 karyotype_high

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 copy_number_equals_one

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 threep_loxp_srpcr

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 fivep_loxp_srpcr

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 vector_integrity

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 repository_qc_result_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 loss_of_allele

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 threep_loxp_taqman

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "well_id",
  {
    data_type      => "integer",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "number", size => [38, 0] },
  },
  "first_test_start_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "latest_test_completion_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "karyotype_low",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "karyotype_high",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "copy_number_equals_one",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "threep_loxp_srpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "fivep_loxp_srpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "vector_integrity",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "repository_qc_result_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "loss_of_allele",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "threep_loxp_taqman",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</repository_qc_result_id>

=back

=cut

__PACKAGE__->set_primary_key("repository_qc_result_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<repository_qc_result_uk1>

=over 4

=item * L</well_id>

=back

=cut

__PACKAGE__->add_unique_constraint("repository_qc_result_uk1", ["well_id"]);

=head1 RELATIONS

=head2 well

Type: belongs_to

Related object: L<HTGTDB::Result::Well>

=cut

__PACKAGE__->belongs_to(
  "well",
  "HTGTDB::Result::Well",
  { well_id => "well_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PaOGjCQLN93o/j5vVSdRIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
