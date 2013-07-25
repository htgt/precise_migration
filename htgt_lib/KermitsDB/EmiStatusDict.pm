package KermitsDB::EmiStatusDict;

use base "DBIx::Class";
__PACKAGE__->load_components("Core");

__PACKAGE__->table("emi_status_dict");
__PACKAGE__->add_columns(
    "id",          { data_type => "DOUBLE PRECISION", is_nullable => 0, size => 126 },
    "name",        { data_type => "VARCHAR2",         is_nullable => 1, size => 512 },
    "description", { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "order_by",    { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "active",      { data_type => "DECIMAL",          is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint( name => ['name'] );

__PACKAGE__->has_many( attempts => "KermitsDB::EmiAttempt", "status_dict_id" );

return 1;