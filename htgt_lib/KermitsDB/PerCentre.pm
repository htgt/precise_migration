package KermitsDB::PerCentre;

use base "DBIx::Class";
__PACKAGE__->load_components("Core");

__PACKAGE__->table("per_centre");
__PACKAGE__->add_columns(
    "name",         { data_type => "VARCHAR2",         is_nullable => 1, size => 128 },
    "id",           { data_type => "DOUBLE PRECISION", is_nullable => 0, size => 126 },
    "creator_id",   { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "edit_date",    { data_type => "DATE",             is_nullable => 1, size => 75 },
    "edited_by",    { data_type => "VARCHAR2",         is_nullable => 1, size => 128 },
    "check_number", { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "created_date", { data_type => "DATE",             is_nullable => 1, size => 75 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( name => ['name'] );

__PACKAGE__->has_many( events => "KermitsDB::EmiEvent", "centre_id" );

return 1;