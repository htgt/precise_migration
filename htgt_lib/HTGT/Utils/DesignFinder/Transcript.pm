package HTGT::Utils::DesignFinder::Transcript;

use Moose;
use namespace::autoclean;
use HTGT::Utils::DesignFinder::Helpers qw( exon_3p_utr_length butfirst butlast );
use HTGT::Utils::DesignFinder::Constants qw( $NMD_SPLICE_LIMIT
                                             $MIN_VALID_INTRON_LENGTH
                                       );
use List::MoreUtils qw( all firstval );

extends qw( Moose::Object Bio::EnsEMBL::Transcript );
with qw( MooseX::Log::Log4perl HTGT::Utils::DesignFinder::Stringify HTGT::Role::EnsEMBL );

sub new {
    my $class = shift;
    my $transcript = shift;

    unless ( ref( $transcript ) ) {
        $transcript = $class->transcript_adaptor->fetch_by_stable_id( $transcript )
            || confess "Failed to retrieve transcript $transcript from EnsEMBL";
    }    

    $class->meta->new_object( __INSTANCE__ => bless( $transcript, $class ), @_ );
}

has is_valid_coding_transcript => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

has [ qw( is_nmd has_valid_splicing has_valid_intron_length has_valid_start ) ] => (
    is         => 'ro',
    isa        => 'Bool',
    init_arg   => undef,
    lazy_build => 1
);

has is_complete => (
    is        => 'ro',
    isa       => 'Bool',
    init_arg  => undef,
    traits    => [ 'Bool' ],
    predicate => 'checked_is_complete',
    handles   => {
        _set_complete   => 'set',
        _set_incomplete => 'unset',
        is_incomplete   => 'not',
    }
);

around is_complete => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig( @_ )
        if $self->checked_is_complete;

    confess( "must call check_complete() before is_complete()" );
};

sub _build_is_valid_coding_transcript {
    my $self = shift;

    unless ( $self->biotype eq 'protein_coding' ) {
        $self->log->debug( "Transcript $self is not protein coding" );
        return 0;
    }

    unless ( $self->has_valid_start ) {
        $self->log->debug( "Transcript $self does not have valid start codon" );
        return 0;
    }
    
    unless ( $self->has_valid_intron_length ) {
        $self->log->debug( "Transcript $self has introns less than minimum length" );
        return 0;
    }

    unless ( $self->has_valid_splicing ) {
        $self->log->debug( "Transcript $self has invalid splicing" );
        return;
    }

    if ( $self->is_nmd ) {
        $self->log->debug( "Transcript $self is subject to NMD" );
        return;
    }

    return 1;
}

sub stringify {
    shift->stable_id;
}

=pod

=head1 METHODS

=over 4

=item has_valid_splicing

Returns true if transcript has valid splicing, otherwise false.

A transcript is condidered to have valid splicing if every
intron has a valid donor/acceptor pair.

=item is_valid_donor_acceptor( $donor, $acceptor )

Returns true if C<$donor>, C<$acceptor> are a valid donor/acceptor pair,
otherwise false. The following pairs are considered valid:

  GT / AG
  GC / AG
  AT / AC

=cut

sub _build_has_valid_splicing {
    my $self = shift;

    my $intron_num = 1;
    for my $intron ( @{ $self->get_all_Introns } ) {
        my $donor = substr( $intron->seq, 0, 2 );
        my $acceptor = substr( $intron->seq, -2, 2 );
        unless ( $self->_is_valid_donor_acceptor( $donor, $acceptor ) ) {
            $self->log->debug( "Intron $intron_num has invalid donor/acceptor: $donor/$acceptor" );
            return 0;
        }
        $intron_num++;
    }

    return 1;
}

sub _is_valid_donor_acceptor {
    my ( $self, $donor, $acceptor ) = @_;

    return ( ( $donor eq 'GT' or $donor eq 'GC' ) and $acceptor eq 'AG' )
        || ( $donor eq 'AT' and $acceptor eq 'AC' );
}

=pod

=item has_valid_intron_length

Returns true if every intron in trancript is at least
C<$MIN_VALID_INTRON_LENGTH> bp, where C<$MIN_VALID_INTRON_LENGTH> is
defined in L<HTGT::Utils::DesignFinder::Constants>.

=cut

sub _build_has_valid_intron_length {
    my $self = shift;
    
    my @introns = @{ $self->get_all_Introns }
        or return 1;

    all { $_->length >= $MIN_VALID_INTRON_LENGTH } @introns;
}

=pod

=item is_nmd

Returns true if transcript is subject to nonsense mediated decay (NMD).

We consider a transcript to be subject to NMD if a splicing event
occurs more that 55bp after the stop codon:

                     30     30      50
  --//--XXXX----XXXXOOO----OOO---OOOOO
                              ^
                              last splicing event

Here, there are 30+30 = 60bp UTR before the last splicing event, so this
transcript would be subject to NMD.

                    20    20       50
  --//--XXXX----XXXXOO----OO----OOOOO
                            ^
                            last splicing event

Here, there are only 20+20 = 40bp UTR before the last splicing event,
so this transcript would B<not> be subject to NMD.

If the last exon is a coding exon, there is no splicing after the stop
codon, hence no NMD:

  --//--XXXX---XXXXOOOOOOO

=cut

sub _build_is_nmd {
    my $self = shift;

    my @exons = @{ $self->get_all_Exons };
    
    my $last_exon = pop @exons;
    return if $last_exon->coding_region_start( $self );

    my $utr = 0;
    while ( @exons ) {
        my $exon_utr = exon_3p_utr_length( pop @exons, $self )
            or last;
        $utr += $exon_utr;
    }

    if ( $utr > $NMD_SPLICE_LIMIT ) {
        return 1;
    }
    
    return 0;
}

sub _build_has_valid_start {
    my $self = shift;

    if ( my $s = $self->cdna_coding_start ) {
        my $first_codon = $self->seq->subseq( $s, $s+2 );
        if ( $first_codon eq 'ATG' ) {
            return 1;
        }
        $self->log->debug( "Transcript $self does not start with ATG" );
    }

    return 0;
}

sub check_complete {
    my ( $self, $template_transcript ) = @_;

    my @exons          = @{ $self->get_all_Exons };
    my @template_exons = @{ $template_transcript->get_all_Exons };

    my $first_exon = $exons[0];
    my $last_exon  = $exons[-1];

    my $is_complete = 1;

    unless ( $self->has_valid_start ) {
        $self->log->debug( "Transcript $self does not have valid start codon" );
        $is_complete = 0;        
    }
    
    if ( $self->strand == 1 ) {
        my $first_template_exon = firstval { $first_exon->start >= $_->start and $first_exon->end == $_->end } butfirst( @template_exons );
        if ( $first_template_exon ) {
            $self->log->debug( "Transcript $self is incomplete at 5' end" );
            $is_complete = 0;
        }
        my $last_template_exon = firstval { $last_exon->start == $_->start and $last_exon->end <= $_->end } butlast( @template_exons );
        if ( $last_template_exon ) {
            $self->log->debug( "Transcript $self is incomplete at 3' end" );
            $is_complete = 0;
        }
    }
    else {
        my $first_template_exon = firstval { $first_exon->end <= $_->end and $first_exon->start == $_->start } butfirst( @template_exons );
        if ( $first_template_exon ) {
            $self->log->debug( "Transcript $self is incomplete at 5' end" );
            $is_complete = 0;
        }
        my $last_template_exon = firstval { $last_exon->start >= $_->start and $last_exon->end == $_->end } butlast( @template_exons );
        if ( $last_template_exon ) {
            $self->log->debug( "Transcript $self is incomplete at 3' end" );
            $is_complete = 0;
        }
    }

    if ( $is_complete ) {
        $self->_set_complete;
    }
    else {
        $self->_set_incomplete;
    }

    return $self->is_complete;
}

=pod

=back

=cut

__PACKAGE__->meta->make_immutable(inline_constructor => 0 );

1;

__END__
