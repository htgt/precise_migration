package KermitsDB::PlnPipeline;

use base "DBIx::Class";
__PACKAGE__->load_components("Core");

__PACKAGE__->table("pln_pipeline");
__PACKAGE__->add_columns(
    "id",           { data_type => "DECIMAL",  is_nullable => 0, size => 38 },   
    "name",         { data_type => "VARCHAR2", is_nullable => 1, size => 4000 },
    "description",  { data_type => "VARCHAR2", is_nullable => 1, size => 4000 }, 
    "creator_id",   { data_type => "DECIMAL",  is_nullable => 1, size => 38 },
    "created_date", { data_type => "DATE",     is_nullable => 1, size => 75 },   
    "edited_by",    { data_type => "VARCHAR2", is_nullable => 1, size => 4000 },
    "edit_date",    { data_type => "DATE",     is_nullable => 1, size => 75 },   
    "check_number", { data_type => "DECIMAL",  is_nullable => 1, size => 38 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( name => ['name'] );

__PACKAGE__->has_many( clones => "KermitsDB::EmiClone", "pipeline_id" );

return 1;