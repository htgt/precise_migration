use utf8;
package HTGTDB::Result::UserQcResult;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::UserQcResult

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<USER_QC_RESULT>

=cut

__PACKAGE__->table("USER_QC_RESULT");

=head1 ACCESSORS

=head2 well_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 five_lrpcr

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 three_lrpcr

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=head2 user_qc_result_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "well_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "five_lrpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "three_lrpcr",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "user_qc_result_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_qc_result_id>

=back

=cut

__PACKAGE__->set_primary_key("user_qc_result_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_qc_result_uk2>

=over 4

=item * L</well_id>

=back

=cut

__PACKAGE__->add_unique_constraint("user_qc_result_uk2", ["well_id"]);

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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6Qp41oyEW/UhJBqbltDMig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
