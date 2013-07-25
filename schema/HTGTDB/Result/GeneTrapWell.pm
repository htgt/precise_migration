use utf8;
package HTGTDB::Result::GeneTrapWell;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

HTGTDB::Result::GeneTrapWell

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<GENE_TRAP_WELL>

=cut

__PACKAGE__->table("GENE_TRAP_WELL");

=head1 ACCESSORS

=head2 gene_trap_well_id

  data_type: 'integer'
  is_nullable: 0
  original: {data_type => "number",size => [38,0]}

=head2 gene_trap_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 five_prime_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 three_prime_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 five_prime_align_quality

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 three_prime_align_quality

  data_type: 'double precision'
  is_nullable: 1
  original: {data_type => "float",size => 126}

=head2 five_prime_chr

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 three_prime_chr

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 five_prime_start

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 three_prime_start

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 five_prime_end

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 three_prime_end

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 five_prime_strand

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 three_prime_strand

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 frt_found

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=head2 frt_lengths

  data_type: 'varchar2'
  is_nullable: 1
  size: 100

=head2 frtp_seq

  data_type: 'varchar2'
  is_nullable: 1
  size: 1000

=head2 is_paired

  data_type: 'integer'
  is_nullable: 1
  original: {data_type => "number",size => [38,0]}

=head2 original_well_name

  data_type: 'varchar2'
  is_nullable: 1
  size: 30

=head2 fam_test_result

  data_type: 'varchar2'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns(
  "gene_trap_well_id",
  {
    data_type   => "integer",
    is_nullable => 0,
    original    => { data_type => "number", size => [38, 0] },
  },
  "gene_trap_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "five_prime_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "three_prime_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "five_prime_align_quality",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "three_prime_align_quality",
  {
    data_type   => "double precision",
    is_nullable => 1,
    original    => { data_type => "float", size => 126 },
  },
  "five_prime_chr",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "three_prime_chr",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "five_prime_start",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "three_prime_start",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "five_prime_end",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "three_prime_end",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "five_prime_strand",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "three_prime_strand",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "frt_found",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
  "frt_lengths",
  { data_type => "varchar2", is_nullable => 1, size => 100 },
  "frtp_seq",
  { data_type => "varchar2", is_nullable => 1, size => 1000 },
  "is_paired",
  {
    data_type   => "integer",
    is_nullable => 1,
    original    => { data_type => "number", size => [38, 0] },
  },
  "original_well_name",
  { data_type => "varchar2", is_nullable => 1, size => 30 },
  "fam_test_result",
  { data_type => "varchar2", is_nullable => 1, size => 20 },
);

=head1 PRIMARY KEY

=over 4

=item * L</gene_trap_well_id>

=back

=cut

__PACKAGE__->set_primary_key("gene_trap_well_id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-07-22 15:30:13
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:THwNOKMsSTALX+QDrE6zqg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
