use utf8;
package HTGTDB::Result::CachedRegeneronStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::CachedRegeneronStatus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<CACHED_REGENERON_STATUS>

=cut

__PACKAGE__->table("CACHED_REGENERON_STATUS");

=head1 ACCESSORS

=head2 mgi_accession_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 100

=head2 status

  data_type: 'varchar2'
  default_value: '(none)'
  is_nullable: 0
  size: 200

=head2 last_updated

  data_type: 'timestamp'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "mgi_accession_id",
  { data_type => "varchar2", is_nullable => 0, size => 100 },
  "status",
  {
    data_type => "varchar2",
    default_value => "(none)",
    is_nullable => 0,
    size => 200,
  },
  "last_updated",
  { data_type => "timestamp", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mgi_accession_id>

=back

=cut

__PACKAGE__->set_primary_key("mgi_accession_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9gojC3wQMWz95QLp4VFhwQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
