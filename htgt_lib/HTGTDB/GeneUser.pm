package HTGTDB::GeneUser;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gene_user');

__PACKAGE__->sequence('S_GENE_USER');

__PACKAGE__->add_columns(
   qw/
     gene_user_id
     mgi_gene_id
     ext_user_id
     edited_user
     edited_date
     priority_type
   /
);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "gene_user_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_gene_user",
    size => [10, 0],
  },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ext_user_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "edited_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "edited_user",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "priority_type",
  {
    data_type => "varchar2",
    default_value => "user_request",
    is_nullable => 0,
    size => 4000,
  },
);
# End of dbicdump add_columns data

__PACKAGE__->set_primary_key('gene_user_id');
__PACKAGE__->belongs_to(mgi_gene=>'HTGTDB::MGIGene',"mgi_gene_id");
__PACKAGE__->belongs_to(ext_user=>'HTGTDB::ExtUser',"ext_user_id");

1;
