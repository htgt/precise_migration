package KermitsDB::PerPerson;

use base "DBIx::Class";
__PACKAGE__->load_components("Core");

__PACKAGE__->table("per_person");
__PACKAGE__->add_columns(
    "id",            { data_type => "DECIMAL",  is_nullable => 0, size => 38 },
    "first_name",    { data_type => "VARCHAR2", is_nullable => 1, size => 128 },
    "last_name",     { data_type => "VARCHAR2", is_nullable => 1, size => 128 },
    "password_hash", { data_type => "VARCHAR2", is_nullable => 1, size => 128 },
    "user_name",     { data_type => "VARCHAR2", is_nullable => 1, size => 32 },
    "email",         { data_type => "VARCHAR2", is_nullable => 1, size => 1024 },
    "address",       { data_type => "VARCHAR2", is_nullable => 1, size => 2048 },
    "centre_id",     { data_type => "DECIMAL",  is_nullable => 1, size => 38 },
    "creator_id",    { data_type => "DECIMAL",  is_nullable => 1, size => 38 },
    "created_date",  { data_type => "DATE",     is_nullable => 1, size => 75 },
    "edited_by",     { data_type => "VARCHAR2", is_nullable => 1, size => 128 },
    "edit_date",     { data_type => "DATE",     is_nullable => 1, size => 75 },
    "check_number",  { data_type => "DECIMAL",  is_nullable => 1, size => 38 },
    "active",        { data_type => "DECIMAL",  is_nullable => 1, size => 1 },
    "hidden",        { data_type => "DECIMAL",  is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");

return 1;