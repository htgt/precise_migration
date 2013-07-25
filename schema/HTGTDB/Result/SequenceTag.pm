use utf8;
package HTGTDB::Result::SequenceTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::SequenceTag

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<SEQUENCE_TAG>

=cut

__PACKAGE__->table("SEQUENCE_TAG");

=head1 ACCESSORS

=head2 sequence_name

  data_type: 'varchar2'
  is_nullable: 0
  size: 255

=head2 source_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 accession_id

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 sequence

  accessor: undef
  data_type: 'clob'
  is_nullable: 1

=head2 sequence_type

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 submission_date

  data_type: 'datetime'
  is_nullable: 1
  original: {data_type => "date"}

=head2 vector

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 source

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=head2 seq_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_sequence_tag'
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "sequence_name",
  { data_type => "varchar2", is_nullable => 0, size => 255 },
  "source_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "accession_id",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "sequence",
  { accessor => undef, data_type => "clob", is_nullable => 1 },
  "sequence_type",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "submission_date",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
  "vector",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "source",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
  "seq_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_sequence_tag",
    size => [10, 0],
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</seq_id>

=back

=cut

__PACKAGE__->set_primary_key("seq_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<stg_uk>

=over 4

=item * L</sequence_name>

=back

=cut

__PACKAGE__->add_unique_constraint("stg_uk", ["sequence_name"]);

=head1 RELATIONS

=head2 annotations

Type: has_many

Related object: L<HTGTDB::Result::Annotation>

=cut

__PACKAGE__->has_many(
  "annotations",
  "HTGTDB::Result::Annotation",
  { "foreign.seq_id" => "self.seq_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 source

Type: belongs_to

Related object: L<HTGTDB::Result::Source>

=cut

__PACKAGE__->belongs_to(
  "source",
  "HTGTDB::Result::Source",
  { source_id => "source_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sAynVU+FHb0c1QkxnhmRzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
