package HTGTDB::DisplayExon;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('display_exon');
#__PACKAGE__->add_columns(
#    qw/
#    display_exon_id
#    ensembl_gene_stable_id
#    ensembl_transcript_stable_id
#    ensembl_exon_stable_id
#    chr_name
#    chr_start
#    chr_end                       
#    chr_strand
#    ensembl_version
#    created_date
#    revision
#/
#);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "display_exon_id",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "ensembl_gene_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_transcript_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "ensembl_exon_stable_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "chr_name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "chr_start",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_end",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chr_strand",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "ensembl_version",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
  "created_date",
  {
    data_type   => "datetime",
    is_nullable => 0,
    original    => { data_type => "date" },
  },
  "revision",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [2, 0],
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key(qw/display_exon_id/);

return 1;

