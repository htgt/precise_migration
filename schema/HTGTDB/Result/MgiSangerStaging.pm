use utf8;
package HTGTDB::Result::MgiSangerStaging;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::MgiSangerStaging

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<MGI_SANGER_STAGING>

=cut

__PACKAGE__->table("MGI_SANGER_STAGING");

=head1 ACCESSORS

=head2 mgi_sanger_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_mgi_sanger'
  size: [10,0]

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 marker_symbol

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 marker_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 500

=head2 cm_position

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 chromosome

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 sanger_gene_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 origin

  data_type: 'varchar2'
  is_nullable: 1
  size: 10

=head2 mgi_gene_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 otter_import

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: 126

=cut

__PACKAGE__->add_columns(
  "mgi_sanger_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_mgi_sanger",
    size => [10, 0],
  },
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "marker_symbol",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "marker_name",
  { data_type => "varchar2", is_nullable => 1, size => 500 },
  "cm_position",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "chromosome",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "sanger_gene_id",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "origin",
  { data_type => "varchar2", is_nullable => 1, size => 10 },
  "mgi_gene_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "otter_import",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => 126,
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iFCpWQtDPkYwE6ClywIo2A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
