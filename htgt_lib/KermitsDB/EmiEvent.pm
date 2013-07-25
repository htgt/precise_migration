package KermitsDB::EmiEvent;

use base "DBIx::Class";
__PACKAGE__->load_components( "PK::Auto", "Core" );

__PACKAGE__->table("emi_event");
__PACKAGE__->add_columns(
    "id",                 { data_type => "DECIMAL",          is_nullable => 0, size => 38 },
    "centre_id",          { data_type => "DECIMAL",          is_nullable => 0, size => 38 },
    "distribution_centre_id",          { data_type => "DECIMAL",          is_nullable => 0, size => 38 },
    "clone_id",           { data_type => "DECIMAL",          is_nullable => 0, size => 38 },
    "is_interested_only", { data_type => "DECIMAL",          is_nullable => 1, size => 1 },
    "proposed_mi_date",   { data_type => "DATE",             is_nullable => 1, size => 75 },
    "creator_id",         { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "created_date",       { data_type => "DATE",             is_nullable => 1, size => 75 },
    "edit_date",          { data_type => "DATE",             is_nullable => 1, size => 75 },
    "edited_by",          { data_type => "VARCHAR2",         is_nullable => 1, size => 128 },
    "comments",           { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "is_failed",          { data_type => "DECIMAL",          is_nullable => 1, size => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->sequence("emi_event_seq");

__PACKAGE__->add_unique_constraint( clone_centre => ['clone_id','centre_id'] );

__PACKAGE__->belongs_to( clone  => "KermitsDB::EmiClone",  "clone_id" );
__PACKAGE__->belongs_to( centre => "KermitsDB::PerCentre", "centre_id" );
__PACKAGE__->belongs_to( distribution_centre => "KermitsDB::PerCentre", "distribution_centre_id" );

__PACKAGE__->has_many( attempts => "KermitsDB::EmiAttempt", "event_id" );

return 1;
