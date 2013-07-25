package HTGTDB::GnmGene2GeneBuildGene;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_gene_2_gene_build_gene');
__PACKAGE__->add_columns(qw/
    id
    gene_id 
    gene_build_gene_id 
    edit_date 
    reasoning 
    is_valid
/);

__PACKAGE__->belongs_to(gene => "HTGTDB::GnmGene", 'gene_id');
__PACKAGE__->belongs_to(gene_build_gene => "HTGTDB::GnmGeneBuildGene", 'gene_build_gene_id');

return 1;

