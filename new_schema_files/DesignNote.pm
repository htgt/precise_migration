package HTGTDB::DesignNote;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut


use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('design_note');
__PACKAGE__->sequence('S_100_1_DESIGN_NOTE');
#__PACKAGE__->add_columns(qw/design_note_id design_id design_note_type_id note created/);

# Added add_columns from dbicdump for htgt_migration project - DJP-S
__PACKAGE__->add_columns(
  "design_note_id",
  {
    data_type => "numeric",
    is_auto_increment => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    sequence => "s_100_1_design_note",
    size => [10, 0],
  },
  "design_note_type_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "design_id",
  {
    data_type => "numeric",
    default_value => 0,
    is_foreign_key => 1,
    is_nullable => 0,
    original => { data_type => "number" },
    size => [10, 0],
  },
  "note",
  { data_type => "varchar2", is_nullable => 1, size => 4000 },
  "created",
  {
    data_type   => "datetime",
    is_nullable => 1,
    original    => { data_type => "date" },
  },
);
# End of dbicdump add_columns data
__PACKAGE__->set_primary_key('design_note_id');
__PACKAGE__->belongs_to(design_note_type=>"HTGTDB::DesignNoteTypeDict", 'design_note_type_id');
__PACKAGE__->belongs_to(design =>"HTGTDB::Design", 'design_id');

return 1;

