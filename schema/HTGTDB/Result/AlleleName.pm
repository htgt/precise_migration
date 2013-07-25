use utf8;
package HTGTDB::Result::AlleleName;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::AlleleName

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ALLELE_NAME>

=cut

__PACKAGE__->table("ALLELE_NAME");

=head1 ACCESSORS

=head2 allele_name_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_allele_name'
  size: 126

=head2 allele_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 mgi_symbol

  data_type: 'varchar2'
  is_nullable: 0
  size: 80

=head2 labcode

  data_type: 'varchar2'
  is_nullable: 0
  size: 40

=head2 iteration

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: 126

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 160

=head2 targeted_trap

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "allele_name_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_allele_name",
    size => 126,
  },
  "allele_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "mgi_symbol",
  { data_type => "varchar2", is_nullable => 0, size => 80 },
  "labcode",
  { data_type => "varchar2", is_nullable => 0, size => 40 },
  "iteration",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => 126,
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 160 },
  "targeted_trap",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</allele_name_id>

=back

=cut

__PACKAGE__->set_primary_key("allele_name_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<allele_name_uk2>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("allele_name_uk2", ["name"]);

=head1 RELATIONS

=head2 allele

Type: belongs_to

Related object: L<HTGTDB::Result::Allele>

=cut

__PACKAGE__->belongs_to(
  "allele",
  "HTGTDB::Result::Allele",
  { allele_id => "allele_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 current_allele

Type: might_have

Related object: L<HTGTDB::Result::Allele>

=cut

__PACKAGE__->might_have(
  "current_allele",
  "HTGTDB::Result::Allele",
  { "foreign.current_allele_name_id" => "self.allele_name_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LnA6XrYLDCxCRJuV3cAA8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
