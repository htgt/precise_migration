package MooseX::Getopt::Meta::Attribute::NoGetopt;
BEGIN {
  $MooseX::Getopt::Meta::Attribute::NoGetopt::AUTHORITY = 'cpan:STEVAN';
}
{
  $MooseX::Getopt::Meta::Attribute::NoGetopt::VERSION = '0.56';
}
# ABSTRACT: Optional meta attribute for ignoring params

use Moose;

extends 'Moose::Meta::Attribute'; # << Moose extending Moose :)
   with 'MooseX::Getopt::Meta::Attribute::Trait::NoGetopt';

no Moose;

# register this as a metaclass alias ...
package # stop confusing PAUSE
    Moose::Meta::Attribute::Custom::NoGetopt;
sub register_implementation { 'MooseX::Getopt::Meta::Attribute::NoGetopt' }

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Getopt::Meta::Attribute::NoGetopt - Optional meta attribute for ignoring params

=head1 SYNOPSIS

  package App;
  use Moose;

  with 'MooseX::Getopt';

  has 'data' => (
      metaclass => 'NoGetopt',  # do not attempt to capture this param
      is        => 'ro',
      isa       => 'Str',
      default   => 'file.dat',
  );

=head1 DESCRIPTION

This is a custom attribute metaclass which can be used to specify
that a specific attribute should B<not> be processed by
C<MooseX::Getopt>. All you need to do is specify the C<NoGetopt>
metaclass.

  has 'foo' => (metaclass => 'MooseX::Getopt::Meta::Attribute::NoGetopt', ... );

=head2 Use 'traits' instead of 'metaclass'

You should rarely need to explicitly set the attribute metaclass. It is much
preferred to simply provide a trait (a role applied to the attribute
metaclass), which allows other code to futher modify the attribute by applying
additional roles.

Therefore, you should first try to do this:

  has 'foo' => (traits => ['NoGetopt', ...], ...);

=head2 Custom Metaclass alias

This now takes advantage of the Moose 0.19 feature to support
custom attribute metaclass. This means you can also
use this as the B<NoGetopt> alias, like so:

  has 'foo' => (metaclass => 'NoGetopt', cmd_flag => 'f');

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@iinteractive.com>

=item *

Brandon L. Black <blblack@gmail.com>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Ryan D Johnson <ryan@innerfence.com>

=item *

Drew Taylor <drew@drewtaylor.com>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Ævar Arnfjörð Bjarmason <avar@cpan.org>

=item *

Chris Prather <perigrin@cpan.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Jonathan Swartz <swartz@pobox.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
