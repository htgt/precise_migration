use utf8;
package HTGTDB::Result::DesignParameter;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignParameter

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_PARAMETER>

=cut

__PACKAGE__->table("DESIGN_PARAMETER");

=head1 ACCESSORS

=head2 design_parameter_id

  data_type: 'numeric'
  is_auto_increment: 1
  is_nullable: 0
  original: {data_type => "number"}
  sequence: 's_112_design_parameter'
  size: [10,0]

=head2 parameter_name

  data_type: 'varchar2'
  default_value: (empty string)
  is_nullable: 0
  size: 45

=head2 parameter_value

  data_type: 'clob'
  is_nullable: 1

=head2 created

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 1
  original: {data_type => "date",default_value => \"sysdate"}

=cut

__PACKAGE__->add_columns(
  "design_parameter_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_112_design_parameter",
    size => [10, 0],
  },
  "parameter_name",
  { data_type => "varchar2", default_value => "", is_nullable => 0, size => 45 },
  "parameter_value",
  { data_type => "clob", is_nullable => 1 },
  "created",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</design_parameter_id>

=back

=cut

__PACKAGE__->set_primary_key("design_parameter_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vXRRoGGlECL67VQvZnYJow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
