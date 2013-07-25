use utf8;
package HTGTDB::Result::ProjectPubliclyReportedDict;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ProjectPubliclyReportedDict

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT_PUBLICLY_REPORTED_DICT>

=cut

__PACKAGE__->table("PROJECT_PUBLICLY_REPORTED_DICT");

=head1 ACCESSORS

=head2 is_publicly_reported

  data_type: 'numeric'
  is_nullable: 0
  original: {data_type => "number"}
  size: [1,0]

=head2 description

  data_type: 'varchar2'
  is_nullable: 0
  size: 225

=cut

__PACKAGE__->add_columns(
  "is_publicly_reported",
  {
    data_type => "numeric",
    is_nullable => 0,
    original => { data_type => "number" },
    size => [1, 0],
  },
  "description",
  { data_type => "varchar2", is_nullable => 0, size => 225 },
);

=head1 PRIMARY KEY

=over 4

=item * L</is_publicly_reported>

=back

=cut

__PACKAGE__->set_primary_key("is_publicly_reported");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KkWIvzp4u3+gl9T9ed7RNw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
