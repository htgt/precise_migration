use utf8;
package HTGTDB::Result::GeneUser;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GeneUser

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GENE_USER>

=cut

__PACKAGE__->table("GENE_USER");

=head1 ACCESSORS

=head2 gene_user_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_gene_user'
  size: [10,0]

=head2 mgi_gene_id

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 ext_user_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 edited_date

  data_type: 'datetime'
  is_nullable: 0
  original: {data_type => "date"}

=head2 edited_user

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 priority_type

  data_type: 'varchar2'
  default_value: 'user_request'
  is_nullable: 0
  size: 4000

=cut

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

=head1 PRIMARY KEY

=over 4

=item * L</gene_user_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_user_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/hhTppup8XA6trSuW6zKvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
