package ConstructQC::QctestPrimer;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/QctestPrimer.pm,v 1.2 2008-02-14 11:57:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("qctest_primer");
__PACKAGE__->add_columns(
    "qctest_primer_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "qctest_result_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "seq_align_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "primer_status",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "primer_name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "seqread_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 126,
    },
    "is_valid",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 1
    },
);
__PACKAGE__->set_primary_key("qctest_primer_id");

__PACKAGE__->belongs_to( qctestResult => 'ConstructQC::QctestResult', "qctest_result_id" );
__PACKAGE__->belongs_to( seqAlignFeature => 'ConstructQC::SeqAlignFeature', "seq_align_id" );
__PACKAGE__->belongs_to( qcSeqread => 'ConstructQC::QcSeqread', "seqread_id" );

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

