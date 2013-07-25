package HTGT::Controller::Well;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

use Tree::Simple;
use HTGT::Utils::Cache;

sub htmlify {
    my ( $well, $data ) = @_;

    my $well_ident = $well->well_name ? $well->well_name : 'well_id:' . $well->well_id;
    my $plate_ident = $well->plate->name ? $well->plate->name : 'plate_id:' . $well->plate->plate_id;
    my $plate_type = $well->plate->type ? $well->plate->type : '';

    my $html =  sprintf( '<strong>%s[%s]</strong> (%s)', $plate_ident, $well_ident, $plate_type );
    if ( $data and @{ $data } ) {
        my %well_data = map { $_->data_type => $_->data_value } $well->well_data;
        foreach my $key ( @{ $data } ) {
            if ( my $value = $well_data{ $key } ) {
                $html .= "<br />$key=$value\n";
            }
        }
    }
    return $html;
}

sub get_tree {
    my ( $self, $well, $data ) = @_;
    my $tree = Tree::Simple->new( htmlify( $well, $data ), Tree::Simple->ROOT );
    foreach my $child ( $well->child_wells ) {
        $tree->addChild( $self->get_tree( $child, $data ) );
    }
    return $tree;
}

sub get_well_by_name {
    my ( $self, $c, $plate_name, $well_name ) = @_;
    
    my $well = $c->model( 'HTGTDB::Well' )->find(
       {   'plate.name' => $plate_name,
            'well_name'  => $well_name
        },
        { join => 'plate' }
    );
    unless ( $well ) {
        $c->log->warn( "Cannot find well $plate_name\[$well_name\]" );
        return;
    }
    return $well;
}

sub get_root {
    my ( $self, $c, $plate_name, $well_name ) = @_;
    
    my $root_well = $self->get_well_by_name( $c, $plate_name, $well_name )
        or return;
        
    while ( $root_well->parent_well ) {
        $root_well = $root_well->parent_well;
    }
    
    return $root_well;
}

sub get_well_data_types {
    my ( $self, $c ) = @_;
    
    my @data_types = $c->model( 'HTGTDB::WellData' )->search(
        { data_value => { '!=', undef } },
        { columns => [ 'data_type' ], distinct => 1 }
    );
    
    [ sort { lc($a) cmp lc($b) } map $_->data_type, @data_types ];
}

sub tree_view : Local {
    my ( $self, $c ) = @_;
    
    $c->stash->{data_types} = get_or_update_cached( $c, 'well_data_types',
                                                    sub { $self->get_well_data_types( $c ) } );

    if ( $c->req->param( 'clear' ) ) {
        $c->req->param( plate_name => undef );
        $c->req->param( well_name => undef );
        $c->req->param( data => undef );
        return;
    }

    defined( my $plate_name = $c->req->param( 'plate_name' ) )
        or return;
        
    defined( my $well_name = $c->req->param( 'well_name' ) )
        or return;
    
    my $root = $self->get_root( $c, $plate_name, $well_name ); 
    unless ( $root ) {
        $c->stash->{error_msg} = "Well $plate_name\[$well_name\] not found";
        return; 
    } 
    
    $c->stash->{ tree } = $self->get_tree( $root, [ $c->req->param( 'data' ) ] );
}

1;
