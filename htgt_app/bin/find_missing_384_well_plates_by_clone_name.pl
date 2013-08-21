#!/usr/bin/env perl

use HTGT::DBFactory;
use Readonly;

sub parse_clone_name {
    my ( $clone_name ) = @_;
    my ( $plate, $well, $iter ) = $clone_name =~ m/^(.+?)_([^_]+)(?:_(\d+))?$/
        or warn "failed to parse clone name: $clone_name" and return;
    return ( $plate, $well, $iter );
}
                          
my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my $htgt_rs = $htgt->resultset( 'HTGTDB::Plate' )->search(
    {
        'plate_data.data_type'  => 'is_384',
        'plate_data.data_value' => 'yes', 
    },
    {
        join => 'plate_data',
        columns => [ 'name' ],
        distinct => 1
    }
);

my %htgt_plates;
while ( my $p = $htgt_rs->next ) {
    $htgt_plates{ $p->name } = 1; 
}

my $clone_name_rs = $htgt->resultset( 'HTGTDB::WellData' )->search(
    {
        data_type => 'clone_name'
    },
    {
        columns  => [ 'data_value' ],
        distinct => 1
    }
);

my %missing;

while ( my $c = $clone_name_rs->next ) {
    my ( $plate_name, $well_name, $iter ) = parse_clone_name( $c->data_value )
        or next; 
    $plate_name =~ /^PG\d+/
        or next;
    my $key = $plate_name;
    $key .= "_$iter" if $iter;
    $missing{ $plate_name } = 1
        unless exists $htgt_plates{ $key }; 
}

print for map "$_\n", sort keys %missing;
