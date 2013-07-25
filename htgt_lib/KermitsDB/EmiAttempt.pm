use strict;
package KermitsDB::EmiAttempt;
use DateTime::Format::Flexible;

use base "DBIx::Class";
__PACKAGE__->load_components( "PK::Auto", "Core" );

__PACKAGE__->table("emi_attempt");
__PACKAGE__->add_columns(
    "id",                            { data_type => "DOUBLE PRECISION", is_nullable => 0, size => 126 },
    "is_active",                     { data_type => "DECIMAL",          is_nullable => 1, size => 1 },
    "event_id",                      { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "actual_mi_date",                { data_type => "DATE",             is_nullable => 1, size => 75 },
    "attempt_number",                { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "num_recipients",                { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "num_blasts",                    { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "created_date",                  { data_type => "DATE",             is_nullable => 1, size => 75 },
    "creator_id",                    { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "edit_date",                     { data_type => "DATE",             is_nullable => 1, size => 75 },
    "edited_by",                     { data_type => "VARCHAR2",         is_nullable => 1, size => 128 },
    "number_born",                   { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "total_chimeras",                { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_male_chimeras",          { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_female_chimeras",        { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "date_chimera_mated",            { data_type => "DATE",             is_nullable => 1, size => 75 },
    "number_chimera_mated",          { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_chimera_mating_success", { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "date_f1_genotype",              { data_type => "DATE",             is_nullable => 1, size => 75 },
    "number_male_100_percent",       { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_male_gt_80_percent",     { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_male_40_to_80_percent",  { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_male_lt_40_percent",     { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "number_with_glt",               { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "comments",                      { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "status_dict_id",                { data_type => "DECIMAL",          is_nullable => 1, size => 38 },
    "num_transferred",               { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "number_with_cct",               { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "total_f1_mice",                 { data_type => "DOUBLE PRECISION", is_nullable => 1, size => 126 },
    "blast_strain",                  { data_type => "VARCHAR2",         is_nullable => 1, size => 4000 },
    "number_f0_matings",
    "f0_matings_with_offspring",
    "f1_germ_line_mice",
    "number_lt_10_percent_glt",
    "number_btw_10_50_percent_glt",
    "number_gt_50_percent_glt",
    "number_100_percent_glt",
    "number_het_offspring",
    "number_live_glt_offspring",
    "is_emma_sticky",
    "test_cross_strain",
    "chimeras_with_glt_from_cct",
    "chimeras_with_glt_from_genotyp",
    "colony_name",
    "europhenome",
    "emma",
    "mmrrc",
    "back_cross_strain",
    "production_centre_mi_id",
    "f1_black",
    "f1_non_black",
    "qc_five_prime_lr_pcr",
    "qc_three_prime_lr_pcr",
    "qc_tv_backbone_assay",
    "qc_loxp_confirmation",
    "qc_loa_qpcr",
    "qc_homozygous_loa_sr_pcr",
    "qc_neo_count_qpcr",
    "qc_mutant_specific_sr_pcr",
    "qc_neo_count_qpcr",
    "qc_lacz_sr_pcr",
    "qc_five_prime_cass_integrity",
    "qc_neo_sr_pcr"
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->sequence("emi_attempt_seq");

__PACKAGE__->belongs_to( event  => "KermitsDB::EmiEvent",      "event_id" );
__PACKAGE__->belongs_to( status => "KermitsDB::EmiStatusDict", "status_dict_id" );

=head1 get_desired_status
Returns a (civil) EmiStatusDict object instead of a raw id.
=cut
sub get_desired_status {
    my $self = shift;
    return $self->result_source->schema->resultset('KermitsDB::EmiStatusDict')->find($self->get_desired_status_id());
}

=head1 get_desired_status_id
Checks breeding stats & strains to see if the MI should be marked either Germline Transmission
confirmed OR Genotype confirmed
=cut
sub get_desired_status_id {
    my $self = shift;
    my $base_status = 1;
    if($self->event->centre_id == 1){
        if(
           ($self->number_het_offspring >= 2) ||
           ($self->chimeras_with_glt_from_genotyp > 0)
        ){
            return 9;
        }else{
            return 3;
        }
    }else{
        if(
           ($self->number_het_offspring > 0) ||
           ($self->chimeras_with_glt_from_genotyp > 0)
        ){
            return 9;
        }elsif(
            ($self->chimeras_with_glt_from_cct> 0) || 
            ($self->number_with_cct > 0)
        ){
            return 6;
        }else{
            return 3;
        }
    }
}

=head1 should_be_made_inactive
Whether this attempt should be in-progress, GLT or Genotype confirmed depends on
whether it's a Sanger MI, and how old it is.
Returns 0 - leave alone or 1 - make inactive.
=cut
sub should_be_made_inactive{
    my $self = shift;
    #First work out how old the attempt is, to see if we should make it inactive.
    my $now = DateTime->now();
    my $mi_date = DateTime::Format::Flexible->parse_datetime( $self->actual_mi_date );
    my $diff = $now->delta_md($mi_date);
    $diff = $diff->delta_months."\n";
    if($diff && ($diff > 9)){
       if(
          ($self->event->centre_id == 1 && ($self->get_desired_status_id != 9))||
          (($self->event->centre_id != 1) && ($self->get_desired_status_id != 9) && ($self->get_desired_status_id != 6))
       ){
            #print "INACTIVATE: ".$self->event->centre_id." : ".$self->get_desired_status_id." : ".$diff."\n";
            return 1;
       }else{
            return 0;
       }
    }else{
        return 0;
    }
}

return 1;
