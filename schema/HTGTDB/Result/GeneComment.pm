use utf8;
package HTGTDB::Result::GeneComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GeneComment

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GENE_COMMENT>

=cut

__PACKAGE__->table("GENE_COMMENT");

=head1 ACCESSORS

=head2 gene_comment_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_gene_comment'
  size: [10,0]

=head2 gene_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 gene_comment

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 visibility

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

=head2 edited_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 edited_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 mgi_gene_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "gene_comment_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_gene_comment",
    size => [10, 0],
  },
  "gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "gene_comment",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "visibility",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "edited_user",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "edited_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_comment_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_comment_id");

=head1 RELATIONS

=head2 mgi_gene

Type: belongs_to

Related object: L<HTGTDB::Result::MgiGeneIdMap>

=cut

__PACKAGE__->belongs_to(
  "mgi_gene",
  "HTGTDB::Result::MgiGeneIdMap",
  { mgi_gene_id => "mgi_gene_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LmwNuT+e4zS73aTjRsqI9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
