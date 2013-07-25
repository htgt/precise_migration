package KermitsDB::EmiClone;

use base "DBIx::Class";
__PACKAGE__->load_components( "PK::Auto", "Core" );

__PACKAGE__->table("emi_clone");
__PACKAGE__->add_columns(
    "id",                        { data_type => "DOUBLE PRECISION", is_nullable => 0, size => 126 },
    "clone_name",                { data_type => "VARCHAR2",         is_nullable => 0, size => 128 },
    "created_date",              { data_type => "DATE",             is_nullable => 1, size => 75 },
    "creator_id",                { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "edit_date",                 { data_type => "DATE",             is_nullable => 1, size => 75 },
    "edited_by",                 { data_type => "VARCHAR2",         is_nullable => 1, size => 128 },
    "pipeline_id",               { data_type => "DECIMAL",          is_nullable => 0, size => 38 },
    "gene_symbol",               { data_type => "VARCHAR2",         is_nullable => 1, size => 256 },
    "allele_name",               { data_type => "VARCHAR2",         is_nullable => 1, size => 256 },
    "ensembl_id",                { data_type => "VARCHAR2",         is_nullable => 1, size => 20 },
    "otter_id",                  { data_type => "VARCHAR2",         is_nullable => 1, size => 20 },
    "target_exon",               { data_type => "VARCHAR2",         is_nullable => 1, size => 20 },
    "design_id",                 { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "design_instance_id",        { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "recombineering_bac_strain", { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    
    # DAN HACK
    "es_cell_line_type",         { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "es_cell_line",           { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "es_cell_strain",         { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    
    "genotype_pass_level",       { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->sequence("emi_clone_seq");

__PACKAGE__->add_unique_constraint( clone_name => ['clone_name'] );

__PACKAGE__->belongs_to( pipeline => "KermitsDB::PlnPipeline", "pipeline_id" );
__PACKAGE__->has_many( events => "KermitsDB::EmiEvent", "clone_id" );

return 1;
