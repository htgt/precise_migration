#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/HTGT-QC/trunk/bin/compare-with-htgt.pl $
# $LastChangedRevision: 5732 $
# $LastChangedDate: 2011-08-24 13:16:59 +0100 (Wed, 24 Aug 2011) $
# $LastChangedBy: rm7 $
#

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory::Lazy;
use Const::Fast;
use CSV::Reader;

const my $TARGET_RX => qr/^(.+)([a-z]\d\d)\.(\d+)_/;

my $csv = CSV::Reader->new( use_header => 1 );

print join( "\t", qw( well my_design my_pass my_primers their_desgin their_pass ) ) . "\n";

while ( my $res = $csv->read ) {
    my ( $plate_name, $well_name, $design_id ) = $res->{TargetID} =~ $TARGET_RX
        or die "failed to parse target $res->{TargetID}";
    my $well = htgt->resultset( 'Well' )->find(
        {
            'plate.name'   => $plate_name,
            'me.well_name' => uc($well_name),
        },
        {
            join => 'plate',
            prefetch => [ 'design_instance', 'well_data' ]
        }
    ) or die "failed to retrieve $plate_name\[$well_name\]";

    my $expected_design_id  = $well->design_instance->design_id;
    my ( $expected_pass_level ) = map { $_->data_value } grep { $_->data_type eq 'pass_level' } $well->well_data;
    $expected_pass_level ||= 'unknown';
    my $expected_pass = $expected_pass_level =~ /^pass/;

    if ( $design_id ne $expected_design_id or ( $res->{pass} xor $expected_pass ) ) {
        print join( "\t", $plate_name.$well_name, $design_id, ( $res->{pass} ? 'pass' : 'fail' ),
                    join( ",", grep $res->{$_}, qw( L1 LR PNF R3 ) ),
                    $expected_design_id, $expected_pass_level ) . "\n";
    }
}




__END__

=head1 NAME

compare-with-htgt.pl - Describe the usage of script briefly

=head1 SYNOPSIS

compare-with-htgt.pl [options] args

      -opt --long      Option description

=head1 DESCRIPTION

Stub documentation for compare-with-htgt.pl, 

=head1 AUTHOR

Ray Miller, E<lt>rm7@sanger.ac.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Ray Miller

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
