use utf8;
package Tarmits::Schema::Result::SolrUpdateQueueItem;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Tarmits::Schema::Result::SolrUpdateQueueItem

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

=head1 TABLE: C<solr_update_queue_items>

=cut

__PACKAGE__->table("solr_update_queue_items");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'solr_update_queue_items_id_seq'

=head2 mi_attempt_id

  data_type: 'integer'
  is_nullable: 1

=head2 phenotype_attempt_id

  data_type: 'integer'
  is_nullable: 1

=head2 action

  data_type: 'text'
  is_nullable: 1

=head2 created_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 updated_at

  data_type: 'timestamp'
  is_nullable: 1

=head2 allele_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "solr_update_queue_items_id_seq",
  },
  "mi_attempt_id",
  { data_type => "integer", is_nullable => 1 },
  "phenotype_attempt_id",
  { data_type => "integer", is_nullable => 1 },
  "action",
  { data_type => "text", is_nullable => 1 },
  "created_at",
  { data_type => "timestamp", is_nullable => 1 },
  "updated_at",
  { data_type => "timestamp", is_nullable => 1 },
  "allele_id",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<index_solr_update_queue_items_on_allele_id>

=over 4

=item * L</allele_id>

=back

=cut

__PACKAGE__->add_unique_constraint("index_solr_update_queue_items_on_allele_id", ["allele_id"]);

=head2 C<index_solr_update_queue_items_on_mi_attempt_id>

=over 4

=item * L</mi_attempt_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_solr_update_queue_items_on_mi_attempt_id",
  ["mi_attempt_id"],
);

=head2 C<index_solr_update_queue_items_on_phenotype_attempt_id>

=over 4

=item * L</phenotype_attempt_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "index_solr_update_queue_items_on_phenotype_attempt_id",
  ["phenotype_attempt_id"],
);


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2013-01-16 12:06:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IeTu0e0ddMmX7C1Gya6DXQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
