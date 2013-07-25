package HTGT::Utils::RegeneronGeneStatus;

use strict;
use warnings FATAL => 'all';

use Moose;

has 'idcc_mart' => (
    is       => 'ro',
    isa      => 'HTGT::BioMart::QueryFactory',
    required => 1,
);

around BUILDARGS => sub {
      my $orig = shift;
      my $class = shift;

      if ( @_ == 1 && ref $_[0] ne 'HASH' ) {
          return $class->$orig( idcc_mart => $_[0] );
      }
      else {
          return $class->$orig( @_ );
      }
};

has '_cache' => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub _build__cache {
    my ( $self ) = @_;
    
    my $query = $self->idcc_mart->query(
        {
            dataset    => 'dcc',
            filter     => { project => 'KOMP-Regeneron' },
            attributes => [ qw( mgi_accession_id regeneron_current_status ) ], 
        }
    );
    
    my %cache;
    for my $r ( @{ $query->results } ) {
        $cache{ $r->{mgi_accession_id} } = $r->{regeneron_current_status};
    }

    return \%cache;    
}

sub BUILD {
    # Make sure the cache is populated on object instantiation 
    shift->_cache();
}

sub status_for {
    my ( $self, $mgi_accession_id ) = @_;
    $self->_cache->{ $mgi_accession_id };
}

sub status_for_all {
    my ( $self ) = @_;
    { %{ $self->_cache() } };
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HTGT::Utils::RegeneronGeneStatus

=head1 SYNOPSIS

  my $rgs = HTGT::Utils::RegeneronGeneStatus->new( $idcc_mart );
  my $status = $rgs->status_for( 'MGI:01759' );

=head1 DESCRIPTION

This module provides a helper that retrieves the KOMP-Regeneron status of a gene by MGI
accession id. When the helper is instantiated, the BioMart is queried and a cache of 
mgi_accession_id/status is populated. Subsequent lookups return the cached values.

The cache is valid only for the lifetime of the helper object; a second call to B<new()> will
create a fresh object with an empty cache.

=head1 METHODS

=over 4

=item B<new($idcc_mart)>

The constructor takes a single argument, a
I<HTGT::BioMart::QueryFactory> object, to query the I-DCC mart. This
method will throw an exception on error, so you might want to call it
inside an I<eval> block.

=item B<status_for($mgi_accession_id)>

Returns the current KOMP-Regeneron status for the specified
I<$mgi_accessiod_id>, or I<undef> if this is not a KOMP gene.

=item B<status_for_all()>

Returns a hash, keyed on MGI accession ID, of all known KOMP-Regeneron
gene statuses (a copy of this module's internal cache.)

=back

=head1 SEE ALSO

L<HTGT::Model::HTGTMart>.

=head1 AUTHOR

Ray Miller E<lt>rm7@sanger.ac.ukE<gt>.

=cut
