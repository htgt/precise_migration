package HTGTDB::GeneComment;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gene_comment');

__PACKAGE__->sequence('S_GENE_COMMENT');

#__PACKAGE__->add_columns(
#   qw/
#     gene_comment_id
#     gene_id
#     mgi_gene_id
#     gene_comment
#     visibility
#     edited_user
#     edited_date
#   /
#);
# Added add_columns from dbicdump for htgt_migration project - DJP-S
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
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('gene_comment_id');
__PACKAGE__->belongs_to(gene=>'HTGTDB::GnmGene',"gene_id");
__PACKAGE__->belongs_to(mgi_gene=>'HTGTDB::MGIGene',"mgi_gene_id");

1;


