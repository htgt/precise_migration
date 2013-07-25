use utf8;
package HTGTDB::Result::Bin321lUbj73OdgQbgsDegVuw0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Bin321lUbj73OdgQbgsDegVuw0

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<"BIN$321lUBj73ODgQBGsDEgVUw==$0">

=cut

__PACKAGE__->table(\"\"BIN\$321lUBj73ODgQBGsDEgVUw==\$0\"");

=head1 ACCESSORS

=head2 final_status_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 final_status_desc

  data_type: 'varchar2'
  is_nullable: 0
  size: 4000

=cut

__PACKAGE__->add_columns(
  "final_status_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "final_status_desc",
  { data_type => "varchar2", is_nullable => 0, size => 4000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</final_status_id>

=back

=cut

__PACKAGE__->set_primary_key("final_status_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i5fiqde0MeFS4Y3ZibrzDw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
