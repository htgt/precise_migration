package HTGT::Utils::Recovery::Report::FilterSponsor::KOMP;

use Moose::Role;
use Iterator::Util 'igrep';
use namespace::autoclean;

with 'HTGT::Utils::Recovery::Report::FilterSponsor';

=method _build_name

Prepend I<KOMP> to our superclass's name

=cut

override _build_name => sub {
    "KOMP " . super();
};

=method is_wanted_sponsor

Returns true if the sponsor matches I<KOMP>.

=cut

sub is_wanted_sponsor {
    my ( $self, $sponsor ) = @_;

    $sponsor =~ /KOMP/;
}

1;

__END__
