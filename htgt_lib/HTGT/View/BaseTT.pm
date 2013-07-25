package HTGT::View::BaseTT;

use strict;
use warnings;
use base 'Catalyst::View::TT';

$Template::Directive::WHILE_MAX = 30000;

sub process {
    my ( $self, $c ) = @_;
    
    if ( defined $c->stash->{template} ) {
        $c->stash->{template} .= $self->config->{TEMPLATE_EXTENSION}
            unless $c->stash->{template} =~ /\.[^.]+$/;
    }
    
    $self->SUPER::process( $c );
}

1;

__END__
