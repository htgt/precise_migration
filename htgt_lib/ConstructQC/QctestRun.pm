package ConstructQC::QctestRun;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/QctestRun.pm,v 1.2 2008-02-14 11:57:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

=head1 NAME

ConstructQC::Qctestrun - A single run of the QC sequencing analysis

=head1 DESCRIPTION

Corresponds to a batch of sequence reads and corresponding constructs.

Also corresponds to at most a single "design" plate and single "clone" plate - but these are just strings. The run may well use data from several 384 well plates. Should perhaps treat the design plate as the external reference we look things up on, and the clone plate as that which we will provide output about. Really the "design" should lead to a list of all the posssible constructs which should be considered when the QctestResult groups of sequences are aligned. This expected cunstructs is 

The run has many QctestResults....

=cut

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("qctest_run");

#__PACKAGE__->sequence("");
__PACKAGE__->add_columns(
    "qctest_run_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "run_date",
    {
        data_type     => "DATE",
        default_value => undef,
        is_nullable   => 1,
        size          => 19
    },
    "program_version",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "comments",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "stage",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    "is_public",
    {
        data_type     => "NUMBER",
        default_value => "0\n",
        is_nullable   => 1,
        size          => 1
    },
    "design_plate",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 64,
    },
    "clone_plate",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },

    #Caching stuff below here (lose this if DBIx::Class proves fast enough):
    "valid_construct_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "valid_design_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "total_construct_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "total_design_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "perfect_pass_design_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "qctest_count",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
);
__PACKAGE__->set_primary_key("qctest_run_id");

__PACKAGE__->has_many( qctestResults => 'ConstructQC::QctestResult', "qctest_run_id" );

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

