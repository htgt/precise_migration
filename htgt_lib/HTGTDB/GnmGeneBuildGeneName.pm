package HTGTDB::GnmGeneBuildGeneName;
use strict;
use warnings;

=head1 AUTHOR

Darren Oakley

=cut




use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_gene_build_gene_name');

__PACKAGE__->add_columns(qw/
    id
    gene_build_gene_id
    name
    source
    name_uc
    creator_id
    created_date
    edit_date
    edited_by
    check_number
/);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(gene_build_gene => 'HTGTDB::GnmGeneBuildGene', 'gene_build_gene_id');

return 1;

