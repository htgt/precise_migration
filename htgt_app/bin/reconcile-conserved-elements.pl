#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use List::MoreUtils 'any';
use Log::Log4perl ':easy';

Log::Log4perl->easy_init(
    {
        level  => $DEBUG,
        layout => '%p - %x %m%n'
    }
);

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $design_rs = $htgt->resultset( 'Design' )->search(
    {
        'design_user_comments.design_comment' => { like => '%conserved elements%' }
    },
    {
        join => 'design_user_comments',
        distinct => 1
    }
);

while ( my $design = $design_rs->next ) {
    Log::Log4perl::NDC->push( $design->design_id );
    DEBUG( "examining design" );
    eval {
        if ( any { @$_ > 0 } values %{ $design->info->constrained_elements } ) {
            INFO( "found constrained elements" );
        }
        else {
            WARN( "missing constrained elements" );
        }
    };
    ERROR( $@ ) if $@;
    Log::Log4perl::NDC->pop;
}
