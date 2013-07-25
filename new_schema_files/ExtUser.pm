package HTGTDB::ExtUser;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('ext_user');

__PACKAGE__->sequence('S_EXT_USER');

#__PACKAGE__->add_columns(
#   qw/
#     ext_user_id
#     email_address
#     email_text
#     edited_date
#     edited_user
#   /
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "edited_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "email_address",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "email_text",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "edited_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "ext_user_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_ext_user",
    size => [10, 0],
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('ext_user_id');
__PACKAGE__->many_to_many( mgi_genes => 'gene_user_links', 'mgi_gene' );
__PACKAGE__->has_many(gene_user_links =>'HTGTDB::GeneUser','ext_user_id');

1;
