# This file is auto-generated by the Perl DateTime Suite time zone
# code generator (0.07) This code generator comes with the
# DateTime::TimeZone module distribution in the tools/ directory

#
# Generated from /tmp/6Pwc8w6J1M/southamerica.  Olson data version 2013d
#
# Do not edit this file directly.
#
package DateTime::TimeZone::America::Aruba;
{
  $DateTime::TimeZone::America::Aruba::VERSION = '1.60';
}
BEGIN {
  $DateTime::TimeZone::America::Aruba::AUTHORITY = 'cpan:DROLSKY';
}

use strict;

use Class::Singleton 1.03;
use DateTime::TimeZone;
use DateTime::TimeZone::OlsonDB;

@DateTime::TimeZone::America::Aruba::ISA = ( 'Class::Singleton', 'DateTime::TimeZone' );

my $spans =
[
    [
DateTime::TimeZone::NEG_INFINITY, #    utc_start
60308944824, #      utc_end 1912-02-12 04:40:24 (Mon)
DateTime::TimeZone::NEG_INFINITY, #  local_start
60308928000, #    local_end 1912-02-12 00:00:00 (Mon)
-16824,
0,
'LMT',
    ],
    [
60308944824, #    utc_start 1912-02-12 04:40:24 (Mon)
61977933000, #      utc_end 1965-01-01 04:30:00 (Fri)
60308928624, #  local_start 1912-02-12 00:10:24 (Mon)
61977916800, #    local_end 1965-01-01 00:00:00 (Fri)
-16200,
0,
'ANT',
    ],
    [
61977933000, #    utc_start 1965-01-01 04:30:00 (Fri)
DateTime::TimeZone::INFINITY, #      utc_end
61977918600, #  local_start 1965-01-01 00:30:00 (Fri)
DateTime::TimeZone::INFINITY, #    local_end
-14400,
0,
'AST',
    ],
];

sub olson_version { '2013d' }

sub has_dst_changes { 0 }

sub _max_year { 2023 }

sub _new_instance
{
    return shift->_init( @_, spans => $spans );
}



1;

