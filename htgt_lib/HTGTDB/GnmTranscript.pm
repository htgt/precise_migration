package HTGTDB::GnmTranscript;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut


use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_transcript');

__PACKAGE__->add_columns(qw/ id locus_id build_gene_id exon_count primary_name /);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(exons => 'HTGTDB::GnmExon', 'transcript_id');

__PACKAGE__->belongs_to(gene_build_gene => 'HTGTDB::GnmGeneBuildGene', 'build_gene_id');

__PACKAGE__->belongs_to(locus => 'HTGTDB::GnmLocus', 'locus_id');

return 1;

