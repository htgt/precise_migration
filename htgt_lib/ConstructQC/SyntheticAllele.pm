package ConstructQC::SyntheticAllele;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/SyntheticAllele.pm,v 1.3 2008-02-14 11:57:02 do2 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("synthetic_allele");
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
);
__PACKAGE__->set_primary_key("engineered_seq_id");

__PACKAGE__->has_one( engineeredSeq => "ConstructQC::EngineeredSeq", 'engineered_seq_id' );

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

