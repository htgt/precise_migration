use utf8;
package HTGTDB::Result::DesignInstanceFeature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::DesignInstanceFeature

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<DESIGN_INSTANCE_FEATURE>

=cut

__PACKAGE__->table("DESIGN_INSTANCE_FEATURE");

=head1 ACCESSORS

=head2 design_instance_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 created_date

  data_type: 'datetime'
  default_value: current_timestamp
  is_nullable: 0
  original: {data_type => "date",default_value => \"sysdate"}

=head2 feature_id

  data_type: 'numeric'
  is_foreign_key: 1
  is_nullable: 0
  original: {data_type => "number"}
  size: [10,0]

=head2 created_user

  data_type: 'varchar2'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "design_instance_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_date",
  {
    data_type     => "datetime",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { data_type => "date", default_value => \"sysdate" },
  },
  "feature_id",
  {
    data_type => "numeric",
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "created_user",
  { data_type => "varchar2", is_nullable => 1, size => 255 },
);

=head1 RELATIONS

=head2 design_instance

Type: belongs_to

Related object: L<HTGTDB::Result::DesignInstance>

=cut

__PACKAGE__->belongs_to(
  "design_instance",
  "HTGTDB::Result::DesignInstance",
  { design_instance_id => "design_instance_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wSywzo8OnDOFfHqD2OFUFw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
