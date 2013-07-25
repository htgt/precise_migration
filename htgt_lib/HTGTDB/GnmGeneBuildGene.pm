package HTGTDB::GnmGeneBuildGene;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut




use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_gene_build_gene');

__PACKAGE__->add_columns(qw/
    id 
    build_id 
    locus_id 
    is_finished 
    unique_exon_count 
    transcript_count 
    total_exon_count 
    primary_name
/);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(gene_gene_build_links => 'HTGTDB::GnmGene2GeneBuildGene', 'gene_build_gene_id');
__PACKAGE__->many_to_many(genes => 'gene_gene_build_links', 'gene');

__PACKAGE__->has_many(transcripts => 'HTGTDB::GnmTranscript', 'build_gene_id');
__PACKAGE__->has_many(gene_build_gene_names => 'HTGTDB::GnmGeneBuildGeneName', 'gene_build_gene_id');

__PACKAGE__->belongs_to(locus => 'HTGTDB::GnmLocus', 'locus_id');
__PACKAGE__->belongs_to(gene_build => 'HTGTDB::GnmGeneBuild', 'build_id');

return 1;

