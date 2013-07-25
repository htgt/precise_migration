use utf8;
package Tarmits::Schema::Result::SchemaMigration;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SchemaMigration

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<schema_migrations>

=cut

__PACKAGE__->table("schema_migrations");

=head1 ACCESSORS

=head2 version

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "version",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<unique_schema_migrations>

=over 4

=item * L</version>

=back

=cut

__PACKAGE__->add_unique_constraint("unique_schema_migrations", ["version"]);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5taaOndfRulVvnsPRa9lMQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
