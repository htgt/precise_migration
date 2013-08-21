#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;

my $tag = shift @ARGV
    or die "Usage: $0 TAG\n";

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

print "$_\n" for get_designs_for_tag( $tag );

sub get_designs_for_tag {
    my $tag = shift;

    my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

    my $design_rs = $htgt->resultset( 'Design' )->search(
        {
            'design_parameter.parameter_name'  => 'custom knockout',
            'design_parameter.parameter_value' => { like => '%' . $tag . '%' }
        },
        {
            join     => 'design_parameter',
            columns  => [ 'design_id' ],
            distinct => 1,
        }
    );

    die "Found no designs for tag: $tag"
        unless $design_rs->count;

    map $_->design_id, $design_rs->all;
}
