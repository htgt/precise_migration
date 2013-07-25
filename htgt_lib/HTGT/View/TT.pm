package HTGT::View::TT;

use strict;
use warnings;
use base 'HTGT::View::BaseTT';
use HTGT::View::TT_utils;

=head1 NAME

HTGT::View::TT - TT View for HTGT

=head1 DESCRIPTION

TT View for HTGT. 

=head1 AUTHORS

Vivek Iyer
David K Jackson
Darren Oakley
Dan Klose

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH       => [
        HTGT->path_to( 'root', 'lib' ),    #standard TT lib location
        HTGT->path_to( 'root', 'src' ),    #standard TT template location?
        HTGT->path_to( 'root' ),           # we seem to be putting our template heirarchy above src....
    ],
    PRE_PROCESS => 'config.tt',
    WRAPPER     => 'wrapper.tt',
    FILTERS     => {
        'rot13'           => \&HTGT::View::TT_utils::rot13, #This is how you call a static FILTER e.g.  [% FILTER rot13 %] <target> [% END %]
        'link_ensembl'    => [ \&HTGT::View::TT_utils::link_ensembl,    1 ],    #This is how you call a dynamic FILTER
        'link_mgi'        => [ \&HTGT::View::TT_utils::link_mgi,        1 ],
        'link_plate_name' => [ \&HTGT::View::TT_utils::link_plate_name, 1 ],
        'link_design'     => [ \&HTGT::View::TT_utils::link_design,     1 ],
        'link_well'       => [ \&HTGT::View::TT_utils::link_well,       1 ],
        #needs qctest_result_id
    }
    #DEBUG=>'undef', #cannot get TT debug to work. Let dj3 know how when you do...
);

1;
