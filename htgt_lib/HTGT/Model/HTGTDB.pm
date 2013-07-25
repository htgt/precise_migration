package HTGT::Model::HTGTDB;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

use HTGT::DBFactory;

__PACKAGE__->config(
    schema_class => 'HTGTDB',
    connect_info => HTGT::DBFactory->params_hash( 'eucomm_vector', {AutoCommit => 1} ), 
);

=head1 NAME

HTGT::Model::HTGTDB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<HTGT>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema such as L<dbi:Oracle:migp eucomm_vector>

=head1 AUTHOR

Vivek Iyer

David K Jackson

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
