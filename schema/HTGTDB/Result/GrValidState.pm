use utf8;
package HTGTDB::Result::GrValidState;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GrValidState

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GR_VALID_STATE>

=cut

__PACKAGE__->table("GR_VALID_STATE");

=head1 ACCESSORS

=head2 state

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=head2 description

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=cut

__PACKAGE__->add_columns(
  "state",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "description",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
);

=head1 PRIMARY KEY

=over 4

=item * L</state>

=back

=cut

__PACKAGE__->set_primary_key("state");

=head1 RELATIONS

=head2 gr_gene_status_histories

Type: has_many

Related object: L<HTGTDB::Result::GrGeneStatusHistory>

=cut

__PACKAGE__->has_many(
  "gr_gene_status_histories",
  "HTGTDB::Result::GrGeneStatusHistory",
  { "foreign.state" => "self.state" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 gr_gene_statuses

Type: has_many

Related object: L<HTGTDB::Result::GrGeneStatus>

=cut

__PACKAGE__->has_many(
  "gr_gene_statuses",
  "HTGTDB::Result::GrGeneStatus",
  { "foreign.state" => "self.state" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:pGhTUZan41aLbT6yACS0bQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
