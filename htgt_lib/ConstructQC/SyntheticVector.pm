package ConstructQC::SyntheticVector;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/SyntheticVector.pm,v 1.4 2008-04-30 13:08:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("synthetic_vector");
__PACKAGE__->add_columns(
    "engineered_seq_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "design_instance_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "id_vector",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "stage",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "cassette_formula",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "design_plate",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    "design_well",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "genbank_accession",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
);
__PACKAGE__->set_primary_key("engineered_seq_id");

__PACKAGE__->has_one( engineeredSeq => "ConstructQC::EngineeredSeq", 'engineered_seq_id' );

__PACKAGE__->has_many( qctestResultsExpected => 'ConstructQC::QctestResult', "expected_engineered_seq_id" );
__PACKAGE__->has_many( qctestResultsMatched => 'ConstructQC::QctestResult',  "engineered_seq_id" );
__PACKAGE__->has_many( qctestResultsChosen => 'ConstructQC::QctestResult', "is_chosen_for_engseq_in_run" );


=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

