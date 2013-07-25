use utf8;
package HTGTDB::Result::Bin1Zlinze08vgQbgsDegqDg0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Bin1Zlinze08vgQbgsDegqDg0

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<"BIN$1/ZLINZe08vgQBGsDEgqDg==$0">

=cut

__PACKAGE__->table(\"\"BIN\$1/ZLINZe08vgQBGsDEgqDg==\$0\"");

=head1 ACCESSORS

=head2 del_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 20

=cut

__PACKAGE__->add_columns(
  "del_id",
  { data_type => "varchar2", is_nullable => 0, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</del_id>

=back

=cut

__PACKAGE__->set_primary_key("del_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B46LqF8akKTAF8CPfHpryA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
