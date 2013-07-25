package HTGT::Utils::Recovery::Report::FilterSponsor::EUCOMM;

use Moose::Role;
use Iterator::Util 'igrep';
use namespace::autoclean;

with 'HTGT::Utils::Recovery::Report::FilterSponsor';

=method _build_name

Prepend I<EUCOMM> to our superclass's name

=cut

override _build_name => sub {
    "EUCOMM " . super();
};

=method is_wanted_sponsor

Returns true if the sponsor matches I<EUCOMM>.

=cut

sub is_wanted_sponsor {
    my ( $self, $sponsor ) = @_;

    $sponsor =~ /EUCOMM/;
}

1;

__END__
