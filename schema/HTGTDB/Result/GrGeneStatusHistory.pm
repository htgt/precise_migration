use utf8;
package HTGTDB::Result::GrGeneStatusHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GrGeneStatusHistory

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GR_GENE_STATUS_HISTORY>

=cut

__PACKAGE__->table("GR_GENE_STATUS_HISTORY");

=head1 ACCESSORS

=head2 gr_gene_status_history_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 mgi_gene_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 state

  data_type: 'varchar2'
  is_foreign_key: 1
  is_nullable: 0
  size: 20

=head2 note

  data_type: 'varchar2'
  is_nullable: 1
  size: 200

=head2 updated

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "gr_gene_status_history_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "state",
  { data_type => "varchar2", is_foreign_key => 1, is_nullable => 0, size => 20 },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 200 },
  "updated",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gr_gene_status_history_id>

=back

=cut

__PACKAGE__->set_primary_key("gr_gene_status_history_id");

=head1 RELATIONS

=head2 mgi_gene

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneIdMap>

=cut

__PACKAGE__->belongs_to(
  "mgi_gene",
  "HTGTDB::Result::MgiGeneIdMap",
  { mgi_gene_id => "mgi_gene_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 state

Type: belongs_to

Related object: L<HTGTDB::Result::GrValidState>

=cut

__PACKAGE__->belongs_to(
  "state",
  "HTGTDB::Result::GrValidState",
  { state => "state" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Pig2mQjiDIqK+iJ7gaeibg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
