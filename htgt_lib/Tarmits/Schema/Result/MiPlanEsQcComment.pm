use utf8;
package Tarmits::Schema::Result::MiPlanEsQcComment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::MiPlanEsQcComment

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

=head1 TABLE: C<mi_plan_es_qc_comments>

=cut

__PACKAGE__->table("mi_plan_es_qc_comments");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'mi_plan_es_qc_comments_id_seq'

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "mi_plan_es_qc_comments_id_seq",
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_mi_plan_es_qc_comments_on_name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("index_mi_plan_es_qc_comments_on_name", ["name"]);

=head1 RELATIONS

=head2 mi_plans

Type: has_many

Related object: L<Tarmits::Schema::Result::MiPlan>

=cut

__PACKAGE__->has_many(
  "mi_plans",
  "Tarmits::Schema::Result::MiPlan",
  { "foreign.es_qc_comment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uEO896lqedyDnSHorn1xvg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
