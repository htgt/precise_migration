use utf8;
package HTGTDB::Result::ProjectAlleleRequest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::ProjectAlleleRequest

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<PROJECT_ALLELE_REQUEST>

=cut

__PACKAGE__->table("PROJECT_ALLELE_REQUEST");

=head1 ACCESSORS

=head2 allele_request_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=head2 project_id

  data_type: 'numeric'
  is_nullable: 1
  original: {data_type => "number"}
  size: [10,0]

=cut

__PACKAGE__->add_columns(
  "allele_request_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "project_id",
  {
    data_type => "numeric",
    is_nullable => 1,
    original => { data_type => "number" },
    size => [10, 0],
  },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tJ34mbxcPgK9eQyXI0da/g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
