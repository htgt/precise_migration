package ConstructQC::EngineeredSeq;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/EngineeredSeq.pm,v 1.9 2009-09-02 14:51:41 io1 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

use Bio::Seq;
use Bio::SeqFeature::Generic;
use JSON;
use Try::Tiny;

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("engineered_seq");
__PACKAGE__->add_columns(
    "engineered_seq_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "type",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 0,
        size          => 64,
    },
    "name",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 255,
    },
    "sequence",
    {
        data_type     => "CLOB",
        default_value => undef,
        is_nullable   => 0,
        size          => 2147483647,
    },
    "subclass",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "is_circular",
    {
        data_type     => "NUMBER",
        default_value => 1,
        is_nullable   => 1,
        size          => 1,
    },
    "is_genomic",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 1,
    },
);
__PACKAGE__->set_primary_key("engineered_seq_id");

__PACKAGE__->has_many(
    qctestResultsExpected => 'ConstructQC::QctestResult',
    "expected_engineered_seq_id"
);
__PACKAGE__->has_many(
    qctestResultsMatched => 'ConstructQC::QctestResult',
    "engineered_seq_id"
);
__PACKAGE__->has_many(
    qctestResultsChosen => 'ConstructQC::QctestResult',
    "is_chosen_for_engseq_in_run"
);
__PACKAGE__->has_many(
    qctestResultsMarked => 'ConstructQC::QctestResult',
    "distribute_for_engseq"
);
__PACKAGE__->has_many(
    seqAlignFeatures => 'ConstructQC::SeqAlignFeature',
    "engineered_seq_id"
);
__PACKAGE__->has_many(
    annotationFeatures => 'ConstructQC::AnnotationFeature',
    "engineered_seq_id"
);

__PACKAGE__->might_have(
    syntheticVector => "ConstructQC::SyntheticVector",
    'engineered_seq_id'
);
__PACKAGE__->might_have(
    syntheticAllele => "ConstructQC::SyntheticAllele",
    'engineered_seq_id'
);

=head2 bioseq

Get BioSeq object without using TargetedTrap::IVSA api.

=cut

sub bioseq {
    my $self = shift;

    unless ( defined $self->{_bioseq} ) {
        my $sequence = Bio::Seq->new(
            -seq         => $self->sequence,
            -is_circular => $self->is_circular,
            -id          => $self->name,
        );

        for my $annotation_feature ( $self->annotationFeatures ) {
            my $tag;
            try {
               $tag = from_json( $annotation_feature->tags );
            }
            catch {
                $tag = eval( $annotation_feature->tags );
            };
            
            $sequence->add_SeqFeature(
                Bio::SeqFeature::Generic->new(
                    -start        => $annotation_feature->loc_start,
                    -end          => $annotation_feature->loc_end,
                    -strand       => $annotation_feature->ori,
                    -primary      => $annotation_feature->source_tag,     # ?
                    -source_tag   => $annotation_feature->source_tag,
                    -display_name => $annotation_feature->label,
                    -tag          => $tag,
                )
            );
        }

        $self->{_bioseq} = $sequence;
    }

    return $self->{_bioseq};
}

=head2 seqfeatures_in_range

Retrieve the features overlapping the Synthetic vector location???

=cut

sub seqfeatures_in_range {
    my ( $self, $start, $end ) = @_;
    my @seq_features = ();

    # Not completely sure if this check is complete
    for my $feature ( $self->bioseq->get_all_SeqFeatures ) {
        if ( $feature->start <= $end and $feature->end >= $start ) {
            push @seq_features, $feature;
        }
    }

    return [@seq_features];
}

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>
Nelo Onyiah <io1@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

