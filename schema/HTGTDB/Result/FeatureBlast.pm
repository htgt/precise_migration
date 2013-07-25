use utf8;
package HTGTDB::Result::FeatureBlast;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::FeatureBlast

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<FEATURE_BLAST>

=cut

__PACKAGE__->table("FEATURE_BLAST");

=head1 ACCESSORS

=head2 blast_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_106_1_feature_blast'
  size: [10,0]

=head2 feature_id

  data_type: 'numeric'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "blast_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_106_1_feature_blast",
    size => [10, 0],
  },
  "feature_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</blast_id>

=back

=cut

__PACKAGE__->set_primary_key("blast_id");

=head1 RELATIONS

=head2 blast_bacs

Type: has_many

Related object: L<HTGTDB::Result::BlastBac>

=cut

__PACKAGE__->has_many(
  "blast_bacs",
  "HTGTDB::Result::BlastBac",
  { "foreign.blast_id" => "self.blast_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 feature

Type: belongs_to

Related object: L<HTGTDB::Result::Feature>

=cut

__PACKAGE__->belongs_to(
  "feature",
  "HTGTDB::Result::Feature",
  { feature_id => "feature_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);

=head2 hits

Type: has_many

Related object: L<HTGTDB::Result::Hit>

=cut

__PACKAGE__->has_many(
  "hits",
  "HTGTDB::Result::Hit",
  { "foreign.blast_id" => "self.blast_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8LtATFAYaRA7qQvB0Dozlg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
