package ConstructQC::QcSeqread;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/QcSeqread.pm,v 1.2 2008-02-14 11:57:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("qc_seqread");
__PACKAGE__->add_columns(
    "seqread_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "primer_oligo_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "read_name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 1024,
    },
    "plate_name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 512,
    },
    "clone_num",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 512,
    },
    "iteration",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 8,
    },
    "plate_number",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 512,
    },
    "well",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "sequence",
    {
        data_type     => "CLOB",
        default_value => undef,
        is_nullable   => 1,
        size          => 2147483647,
    },
    "comments",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "read_length",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "quality_length",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "ql",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "qr",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "is_broken",
    {
        data_type     => "NUMBER",
        default_value => "0\n",
        is_nullable   => 1,
        size          => 10
    },
    "contamination",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "construct_clone_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "oligo_name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "plate_iteration",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
);
__PACKAGE__->set_primary_key("seqread_id");

__PACKAGE__->belongs_to( constructClone => 'ConstructQC::ConstructClone', "construct_clone_id" );

__PACKAGE__->has_many( seqAlignFeatures => 'ConstructQC::SeqAlignFeature', "seqread_id" );
__PACKAGE__->has_many( qctestPrimers => 'ConstructQC::QctestPrimer', "seqread_id" );

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

