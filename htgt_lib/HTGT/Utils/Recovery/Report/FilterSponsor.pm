package HTGT::Utils::Recovery::Report::FilterSponsor;

use Moose::Role;
use Iterator::Util 'igrep';
use namespace::autoclean;

requires qw( is_wanted_sponsor );

=method _build_columns

Initialize the list of columns to be displayed in this report: take
the columns of our superclass and drop I<sponsor>.

=cut

override _build_columns => sub {
    [ grep { $_ ne 'sponsor' } @{ super() } ];
};

=method _build_iterator

Return just the genes from our superclass's iterator for which
B<is_wanted_sponsor()> returns true.

=cut

override _build_iterator => sub {
    my $self = shift;
    igrep { $self->is_wanted_sponsor( $_->{sponsor} ) } super;
};

1;

__END__
