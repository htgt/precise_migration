package HTGT::Utils::DesignChecker::Oligo;

=head1 NAME

HTGT::Utils::DesignChecker::Oligo

=head1 DESCRIPTION

Collection of design checks relating to the oligos for a design.

=cut

use Moose;
use namespace::autoclean;

use List::MoreUtils qw( uniq );
use Try::Tiny;
use Const::Fast;

with 'HTGT::Utils::DesignCheckRole';

const my @OLIGO_NAMES => qw( G5 U5 U3 D5 D3 G3 );

sub _build_check_type {
    return 'oligo';
}

has assembly_id => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has features => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build_features {
    my $self = shift;

    my $features = try { $self->design->validated_display_features } catch { {} };

    return $features;
}

has strand => (
    is         => 'ro',
    isa        => 'Int',
    lazy_build => 1,
);

sub _build_strand {
    shift->design->info->chr_strand;
}

has design_type => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 _build_checks

Populate the checks array of the parent class

=cut
sub _build_checks {
    my $self = shift;

    return [
        'no_multiple_oligos',
        'expected_oligos',
        'oligo_validity',
        'consistent_chromosome',
        'consistent_strand',
        'expected_order',
        'g5_to_g3_length',
    ];
}

=head2 no_multiple_oligos

Design does not have mulitple oligos of the same type.

=cut
sub no_multiple_oligos {
    my $self = shift;

    my $validated_features = $self->design->search_related(
        features => {
            'feature_data_type.description' => 'validated'
        },
        {
            join => {
                feature_data => 'feature_data_type'
            }
        }
    );

    my $validated_display_features = $validated_features->search_related(
        display_features => {
            assembly_id => $self->assembly_id,
            label       => 'construct'
        },
        {
            prefetch => [
                {
                   feature => 'feature_type'
                },
            ]
        }
    );

    my %display_feature_for;

    my @multiple_oligos;
    while ( my $df = $validated_display_features->next ) {
        my $type = $df->feature->feature_type->description;
        push @multiple_oligos, $type if exists $display_feature_for{ $type }; 
        $display_feature_for{ $type }++;
    }

    if ( @multiple_oligos ) {
        $self->set_status( 'multiple_oligos', [ map{ "Multiple $_ oligos" } @multiple_oligos ] );
        return;
    }

    return 1;
}

=head2 expected_oligos

Design has all the expected oligos for its design type.

=cut
sub expected_oligos {
    my $self = shift;

    my @oligo_names = @OLIGO_NAMES;
    if ( $self->design_type =~ /^Ins/ || $self->design_type =~ /^Del/ ) {
        @oligo_names = grep { $_ ne 'U3' and $_ ne 'D5' } @OLIGO_NAMES;
    }

    my @missing_oligo;
    for my $oligo_name ( @oligo_names ) {
        push @missing_oligo, $oligo_name
            unless exists $self->features->{$oligo_name};
    }

    if ( @missing_oligo ) {
        $self->set_status('missing_oligos', [ map{ "Missing oligo $_" } @missing_oligo ] );
        return;
    }

    return 1;
}

=head2 oligo_validity

Check the validity for the design oligos, end coordinate should be after the start.

=cut
sub oligo_validity {
    my $self = shift;

    my $invalid_oligos = 0;
    my @invalid_oligo_notes;

    # check the end coordinates are after the start coordinates
    for my $oligo_name ( keys %{ $self->features } ) {
        my $oligo = $self->features->{$oligo_name};

        if ( $oligo->feature_end < $oligo->feature_start ) {
            $invalid_oligos = 1;
            push @invalid_oligo_notes, "Oligo $oligo_name has end before start";
        }

    }

    if ( $invalid_oligos ) {
        $self->set_status( 'invalid_oligos', \@invalid_oligo_notes );
        return;
    }
    return 1;
}

=head2 consistent_chromosome

The oligos are all on the same chromosome.

=cut
sub consistent_chromosome {
    my $self = shift;

    my @chromosomes = uniq map { $_->chromosome->name } values %{ $self->features };

    unless ( @chromosomes == 1 ) {
        $self->set_status( 'inconsistent_chromosome',
            [ 'Oligos found on multiple chromosomes ' . join(' ', @chromosomes ) ] );
        return;
    }

    return 1;
}

=head2 consistent_strand

The oligos are all on the same strand.

=cut
sub consistent_strand {
    my $self = shift;

    my @strands = uniq map { $_->feature_strand } values %{ $self->features };

    unless ( @strands == 1 ) {
        $self->log->debug('Multiple strands found for oligos' );
        $self->set_status( 'inconsistent_strand' );
        return;
    }

    return 1;
}

=head2 expected_order

The oligos are in the expected order for the design strand.

=cut
sub expected_order {
    my $self = shift;

    if ( $self->strand == 1 ) {
        if ( $self->features->{G5}->feature_start > $self->features->{G3}->feature_start ) {
            $self->set_status( 'g5_g3_oligos_wrong_order',
                ['G5 oligo after G3 oligo on +ve strand'] );
            return;
        }
    }
    else {
        if ( $self->features->{G3}->feature_start > $self->features->{G5}->feature_start ) {
            $self->set_status( 'g5_g3_oligos_wrong_order',
                ['G3 oligo after G5 oligo on -ve strand'] );
            return;
        }
    }

    my @oligo_names = $self->strand eq 1 ? @OLIGO_NAMES : reverse @OLIGO_NAMES;

    if ( $self->design_type =~ /^Ins/ || $self->design_type =~ /^Del/ ) {
        @oligo_names = grep { $_ ne 'U3' and $_ ne 'D5' } @oligo_names;
    }

    for my $ix ( 0 .. ( @oligo_names - 2 ) ) {
        my $o1 = $oligo_names[$ix];
        my $o2 = $oligo_names[ $ix + 1 ];
        unless ( $self->features->{$o1}->feature_end <= $self->features->{$o2}->feature_start ) {
            $self->set_status( 'unexpected_oligo_order',
                ["Oligos $o1 and $o2 in unexpected order"] );
            return;
        }
    }

    return 1;
}

=head2 g5_to_g3_length

Note the number of bases between the G5 and G3 oligos.

=cut
sub g5_to_g3_length {
    my $self = shift;

    my $length;
    if ( $self->strand == 1 ) {
        $length = $self->features->{G3}->feature_start - $self->features->{G5}->feature_end;
    }
    else {
        $length = $self->features->{G5}->feature_start - $self->features->{G3}->feature_end;
    }

    $self->add_note( 'Number of bases from G5 to G3 oligo is ' . $length );

    return 1;
}

1;

__END__
