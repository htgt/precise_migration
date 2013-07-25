package TargetedTrap::IVSA::Constants;

use strict;
use warnings FATAL => 'all';
use Readonly;

=head2 $PLATE_REGEXP

A regexp to match our plates and retrieve different elements from

=cut

Readonly our $PLATE_REGEXP => qr{
    ^
    ([A-Z][A-Za-z\d]+(?:_\d+)?) # plate name
    (?:_\d+)?
    (?:_([A-Za-z]))?     # plate iteration
    (?:_[A-Za-z0-9]+)??
    [_-]?
    (\d+)                # clone name
    ([A-Za-z]\d+)        # well name
    \.p1k
    ([a-z])?             # iteration
    (\w*)                # primer
    $
  }x;

1;
