package ConstructQC::SeqAlignFeature;

# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC/SeqAlignFeature.pm,v 1.8 2009-09-09 14:29:30 io1 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle!

use strict;
use warnings;

use base 'DBIx::Class';

use Carp 'croak';
use List::Util 'max';
use List::MoreUtils 'pairwise';
use POSIX 'ceil';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("seq_align_feature");
__PACKAGE__->add_columns(
    "seq_align_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 0,
        size          => 38
    },
    "seqread_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
    "seqread_start",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "seqread_end",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "seqread_ori",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 3,
    },
    "engseq_start",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "engseq_end",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "engseq_ori",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 3,
    },
    "score",
    {
        data_type     => "FLOAT",
        default_value => undef,
        is_nullable   => 1,
        size          => 126
    },
    "evalue",
    {
        data_type     => "FLOAT",
        default_value => undef,
        is_nullable   => 1,
        size          => 126
    },
    "align_length",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "identical_matches",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "percent_identity",
    {
        data_type     => "FLOAT",
        default_value => undef,
        is_nullable   => 1,
        size          => 126
    },
    "cmatch",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 10
    },
    "loc_status",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 32,
    },
    "cigar_line",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "comments",
    {
        data_type     => "VARCHAR2",
        default_value => undef,
        is_nullable   => 1,
        size          => 4000,
    },
    "map_score",
    {
        data_type     => "FLOAT",
        default_value => undef,
        is_nullable   => 1,
        size          => 126
    },
    "engineered_seq_id",
    {
        data_type     => "NUMBER",
        default_value => undef,
        is_nullable   => 1,
        size          => 38
    },
);
__PACKAGE__->set_primary_key("seq_align_id");

__PACKAGE__->add_unique_constraint(
    "seq_align_feature_uk1",
    [
        "cigar_line",    "engseq_ori",
        "engseq_end",    "engseq_start",
        "seqread_ori",   "seqread_end",
        "seqread_start", "engineered_seq_id",
        "seqread_id",
    ],
);

__PACKAGE__->belongs_to( qcSeqread => 'ConstructQC::QcSeqread', "seqread_id" );
__PACKAGE__->belongs_to(
    engineeredSeq => 'ConstructQC::EngineeredSeq',
    "engineered_seq_id"
);

__PACKAGE__->has_many(
    qctestPrimers => 'ConstructQC::QctestPrimer',
    "seq_align_id"
);    #dj3 - is there only one of these?

=head2 observed_features

Retrieve a list of the features observed for this alignment

=cut

sub observed_features {
    my $self = shift;

    unless ( defined( $self->{overlapping_features} ) ) {
        $self->_load_overlapping_features;
    }

    return [ keys %{ $self->{overlapping_features} } ];
}

=head2 _load_overlapping_features

Load the features overlapping the Engineered Sequence except the translations

=cut

sub _load_overlapping_features {
    my $self   = shift;
    my $engseq = $self->engineeredSeq;

    $self->{overlapping_features} = {};

    return unless $engseq; #io1 - do we want to throw an exception here perhaps?

    my $sf_list =
      $engseq->seqfeatures_in_range( $self->engseq_start, $self->engseq_end );

  SEQFEATURE: for my $sf (@$sf_list) {
        my $ac = $sf->annotation;
        if ($ac) {
          ANNOTATION_KEY: for my $key ( $ac->get_all_annotation_keys ) {
                next ANNOTATION_KEY if $key eq 'translation';
                for my $annotation ( $ac->get_Annotations($key) ) {
                    $self->{overlapping_features}->{ $annotation->value } = $sf;
                }
            }
        }
    }
}

=head2 show_alignment

Generate a string representation of an alignment

=cut

sub show_alignment {
    my $self        = shift;
    my $aa_per_line = shift;
    my $seq_read    = $self->qcSeqread;
    my $eng_seq     = $self->engineeredSeq;
    my $label_length =
      max( length( $seq_read->read_name ), length( $eng_seq->name ) ) + 3;

   # the eng_seq is the reference
    my $seq_read_seq = $self->_alignment_string( $seq_read->sequence,
      $self->seqread_start, $self->seqread_end,  $self->seqread_ori );
    my $eng_seq_seq  =
      $self->_alignment_string( $eng_seq->sequence, $self->engseq_start,
        $self->engseq_end, $self->engseq_ori, 1 );

    # generate the match (i.e the "||||  ||") string
    my $alignment_string = do {
        local ( $a, $b );
        my @seq_read_seq = split //, $seq_read_seq;
        my @eng_seq_seq  = split //, $eng_seq_seq;

        join( '',
            pairwise { $a eq $b ? '|' : ' ' } @seq_read_seq, @eng_seq_seq );
    };

    # format the alignment string
    $aa_per_line ||= 80;

    my $offset           = 0;
    my $num_lines        = ceil( length($eng_seq_seq) / $aa_per_line );
    my $formatted_string = '';

    while ( $num_lines > 0 ) {
        $formatted_string .= join(
            ' ',
            sprintf( '%*s %s', $label_length, $seq_read->read_name, $self->seqread_ori ),
            substr( $seq_read_seq, $offset, $aa_per_line )
        ) . "\n";
        $formatted_string .= join( ' ',
            sprintf( '%*s %s', $label_length, '   ', ' ' ),
            substr( $alignment_string, $offset, $aa_per_line ) )
          . "\n";
        $formatted_string .= join(
            ' ',
            sprintf( '%*s %s', $label_length, $eng_seq->name, $self->engseq_ori ),
            substr( $eng_seq_seq, $offset, $aa_per_line )
        ) . "\n";

        $formatted_string .= "\n";
        $offset += $aa_per_line;
        $num_lines--;
    }

    return $formatted_string;
}

sub _alignment_string {
    my ( $self, $sequence, $start, $end, $ori, $vector ) = @_;

    unless ( defined $start && defined $end ) {
        croak 'Both start and end should be defined';
        return;
    }

    # need the reverse compliment of things on the negative strand
    if ( $ori eq '-' ) {
        require Bio::Seq;
        $sequence = Bio::Seq->new( -seq => $sequence )->revcom->seq;
    }

    # we don't need all of the sequence
    $sequence = substr $sequence, $start, $end - $start;

    my $alignment_string = '';
    my $seq_start        = 0;
    my $cigar_string     = $self->cigar_line;
    my $cigar_regex      = qr/\G([MID])(\d*)/;

    # inverse insertions/deletions on the reference sequence
    if ($vector) {
        $cigar_string =~ tr/DI/ID/;
    }

    while ( $cigar_string =~ m/$cigar_regex/g ) {
        my ( $string, $length ) = ( $1, $2 );
        if ( $string eq 'D' ) {
            $alignment_string .= '-' x $length;
        }
        else {
            $alignment_string .= substr $sequence, $seq_start, $length;
            $seq_start += $length;
        }
    }

    return $alignment_string;
}

=for TODO:

For the functions I've (io1) added, I need to do error checking which
means I need access to the context ($c) in these functions

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>
Nelo Onyiah <io1@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

