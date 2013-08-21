#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use CSV::Writer;
use HTGT::DBFactory;
use HTGT::Utils::Design::Validate;
use List::Util qw( min max );
use Log::Log4perl ':levels';
use Readonly;
use Try::Tiny;

Readonly my @FEAT_REPEATS  => ( "G5", "U5", "U3", "D5", "D3", "G3" );
Readonly my @FLANK_REPEATS => ( "G5 5' flank", "G3 3' flank" );

Readonly my $DESIGN_STATUS_QUERY => <<'EOT';
select distinct p.design_id, ps.code, ps.order_by, ps.status_type
from project p
join project_status ps on ps.project_status_id = p.project_status_id
where ps.order_by = (
  select max(ps2.order_by)
  from project p2
  join project_status ps2 on ps2.project_status_id = p2.project_status_id
  where p2.design_id = p.design_id
)
and ps.order_by > 80
EOT

Log::Log4perl->easy_init( $WARN );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $csv = CSV::Writer->new;

$csv->write( "design_id", "status_code", "status_type", "status_order", @FEAT_REPEATS, @FLANK_REPEATS );

my $design_status = $htgt->storage->dbh_do( sub { shift; shift->selectall_arrayref( $DESIGN_STATUS_QUERY ) } );

for ( @{ $design_status } ) {
    my ( $design_id, $status, $order, $type ) = @$_;
    my $design = $htgt->resultset( 'Design' )->find( { design_id => $design_id } );
    next if $design->design_type and $design->design_type ne 'KO';
    try {
        my $v = HTGT::Utils::Design::Validate->new( design => $design );
        next if $v->has_fatal_error;
        $csv->write( $design_id, $status, $type, $order, format_repeats( $v->design_info->repeat_regions ) );
    }
    catch {
        warn $_;
    };
}

sub format_repeats {
    my $repeats = shift;

    my @repeats;

    for ( @FEAT_REPEATS ) {
        my $r = $repeats->{$_} || [];
        my $overlap = max( map { min( 50, $_->{end} )  - max( 0, $_->{start} ) + 1 } @{$r} ) || 0;
        push @repeats, $overlap;        
    }

    for ( @FLANK_REPEATS ) {
        my $r = $repeats->{$_} || [];
        my $length = max( map { $_->{end} - $_->{start} + 1 } @{$r} ) || 0;
        push @repeats, $length;        
    }

    return @repeats;
}

