package HTGTDB::GnmGene;

use strict;
use warnings;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_gene');

__PACKAGE__->add_columns(
    qw/
      id
      ncbi_taxon
      is_valid
      primary_name
      primary_vega_build_gene_id
      primary_ensembl_build_gene_id
      primary_name_source
      new_name
      old_name
      in_current_ensembl
      in_current_vega
      /
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->many_to_many( gene_build_genes => 'gene_build_gene_links', 'gene_build_gene' );


__PACKAGE__->has_many( gene_build_gene_links => 'HTGTDB::GnmGene2GeneBuildGene', 'gene_id' );
__PACKAGE__->has_many( gene_names            => 'HTGTDB::GnmGeneName',           'gene_id' );
__PACKAGE__->has_many( gene_info             => 'HTGTDB::GeneInfo',              'gene_id' );
__PACKAGE__->has_many( gene_comments         => 'HTGTDB::GeneComment',           'gene_id' );

=head1 AUTHOR

Dan Klose
Vivek Iyer
Darren Oakley <do2@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

return 1;

