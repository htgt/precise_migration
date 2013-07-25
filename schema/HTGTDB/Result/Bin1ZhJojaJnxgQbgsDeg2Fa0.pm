use utf8;
package HTGTDB::Result::Bin1ZhJojaJnxgQbgsDeg2Fa0;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::Bin1ZhJojaJnxgQbgsDeg2Fa0

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<"BIN$1/ZhJOjaJNXgQBGsDEg2FA==$0">

=cut

__PACKAGE__->table(\"\"BIN\$1/ZhJOjaJNXgQBGsDEg2FA==\$0\"");

=head1 ACCESSORS

=head2 da_test_set_id

  data_type: 'varchar2'
  is_nullable: 0
  size: 50

=head2 da_test_set_desc

  data_type: 'varchar2'
  is_nullable: 1
  size: 4000

=cut

__PACKAGE__->add_columns(
  "da_test_set_id",
  { data_type => "varchar2", is_nullable => 0, size => 50 },
  "da_test_set_desc",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</da_test_set_id>

=back

=cut

__PACKAGE__->set_primary_key("da_test_set_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:29:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:FaWEGItfWXOiy/+o+QtOBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
