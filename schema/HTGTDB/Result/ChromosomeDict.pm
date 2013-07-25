use utf8;
package HTGTDB::Result::ChromosomeDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ChromosomeDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<CHROMOSOME_DICT>

=cut

__PACKAGE__->table("CHROMOSOME_DICT");

=head1 ACCESSORS

=head2 chr_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_96_1_chromosome_dict'
  size: [10,0]

=head2 name

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "chr_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_96_1_chromosome_dict",
    size => [10, 0],
  },
  "name",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</chr_id>

=back

=cut

__PACKAGE__->set_primary_key("chr_id");

=head1 RELATIONS

=head2 bacs

Type: has_many

Related object: L<HTGTDB::Result::Bac>

=cut

__PACKAGE__->has_many(
  "bacs",
  "HTGTDB::Result::Bac",
  { "foreign.chr_id" => "self.chr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 chr

Type: belongs_to

Related object: L<HTGTDB::Result::ChromosomeDict>

=cut

__PACKAGE__->belongs_to(
  "chr",
  "HTGTDB::Result::ChromosomeDict",
  { chr_id => "chr_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 chromosome_dict

Type: might_have

Related object: L<HTGTDB::Result::ChromosomeDict>

=cut

__PACKAGE__->might_have(
  "chromosome_dict",
  "HTGTDB::Result::ChromosomeDict",
  { "foreign.chr_id" => "self.chr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 features

Type: has_many

Related object: L<HTGTDB::Result::Feature>

=cut

__PACKAGE__->has_many(
  "features",
  "HTGTDB::Result::Feature",
  { "foreign.chr_id" => "self.chr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 targets

Type: has_many

Related object: L<HTGTDB::Result::Target>

=cut

__PACKAGE__->has_many(
  "targets",
  "HTGTDB::Result::Target",
  { "foreign.chr_id" => "self.chr_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ji9PamYCz6/2+qBZryG3IA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
