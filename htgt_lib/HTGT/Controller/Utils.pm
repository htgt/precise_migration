package HTGT::Controller::Utils;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

HTGT::Controller::Utils - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut

sub index : Private {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/') );
}

=head2 _suggest_gene_names

Ajax autocompleter helper method to suggest a gene name - does its lookup 
via the mig.gnmgene table.

=cut

sub _suggest_gene_names : Local {
    my ( $self, $c ) = @_;
    
    my @rs = $c->model('HTGTDB::GnmGene')->search( 
        { primary_name => { 'like', '%' . $c->req->params->{gene_name} . '%' } },
        { order_by => { -asc => 'primary_name' }, rows => 15 } 
    );
    
    my $html_set = "<ul>";
    foreach ( @rs ) { $html_set .= '<li id=' . $_->id . '>' . $_->primary_name . '</li>'; }
    $html_set .= "</ul>";
    
    $c->res->body($html_set);
}

=head2 _suggest_plate_names

Ajax autocompleter helper method to suggest a plate name - looks up the names 
in the plate table.

=cut

sub _suggest_plate_names : Local {
    my ( $self, $c ) = @_;

    my $search_string = $c->req->params->{plate_name} || '';
    $search_string = $c->req->params->{new_plate_name}    if $search_string =~ /^$/;
    $search_string = $c->req->params->{parent_plate_name} if $search_string =~ /^$/;
    $search_string = $c->req->params->{parent_plate} if $search_string =~ /^$/;

    my $rs = $c->model('HTGTDB::Plate')->search( 
        { name => { 'like', '%' . $search_string . '%' } },
        { order_by => { -asc => 'name' }, rows => 25, columns => [qw/plate_id name type/] }
    );

    if ( $c->req->params->{plate_type} ) {
        $rs = $rs->search({ type => $c->req->params->{plate_type} });
    }

    my $html_set = "<ul>";
    while ( my $plate = $rs->next ) {
        $html_set .= '<li id=' . $plate->plate_id . '><span class="plate_type informal">' . $plate->type . '</span>' . $plate->name . '</li>';
    }
    $html_set .= "</ul>";

    $c->res->body($html_set);
}

=head1 AUTHORS

Dan Klose <dk3@sanger.ac.uk>
Darren Oakley <do2@sanger.ac.uk>
David K Jackson <david.jackson@sanger.ac.uk>


=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
