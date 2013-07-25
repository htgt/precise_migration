use utf8;
package HTGTDB::Result::EucommGene;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::EucommGene

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<EUCOMM_GENE>

=cut

__PACKAGE__->table("EUCOMM_GENE");

=head1 ACCESSORS

=head2 gene_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_104_1_eucomm_gene'
  size: [10,0]

=head2 gene_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 30

=head2 priority

  data_type: 'char'
  is_nullable: 1
  size: 1

=cut

__PACKAGE__->add_columns(
  "gene_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_104_1_eucomm_gene",
    size => [10, 0],
  },
  "gene_name",
  { data_type => "varchar2", is_nullable => 0, size => 30 },
  "priority",
  { data_type => "char", is_nullable => 1, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_id");

=head1 RELATIONS

=head2 targets

Type: has_many

Related object: L<HTGTDB::Result::Target>

=cut

__PACKAGE__->has_many(
  "targets",
  "HTGTDB::Result::Target",
  { "foreign.gene_id" => "self.gene_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i/dMZ2cXDOERId4Ur+PMXQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
