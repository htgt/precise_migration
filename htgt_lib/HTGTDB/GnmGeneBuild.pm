package HTGTDB::GnmGeneBuild;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_gene_build');

__PACKAGE__->add_columns(qw/
    id 
    assembly_id 
    name
    version
    source
    order_by
    check_number
    edit_date
    creator_id
    edited_by
    created_date
/);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(gene_build_genes => 'HTGTDB::GnmGeneBuildGene', 'id');

return 1;

