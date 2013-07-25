package ConstructQC::ConstructClone;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/ConstructClone.pm,v 1.2 2008-02-14 11:57:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("construct_clone");
__PACKAGE__->add_columns(
    "construct_clone_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 512,
    },
    "plate",
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
    "clone_number",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "vector_type",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 128,
    },
    "id_vector_batch",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
);
__PACKAGE__->set_primary_key("construct_clone_id");

__PACKAGE__->has_many( qctestResults => 'ConstructQC::QctestResult', "construct_clone_id" );
__PACKAGE__->has_many( qcSeqreads => 'ConstructQC::QcSeqread', "construct_clone_id" );

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

