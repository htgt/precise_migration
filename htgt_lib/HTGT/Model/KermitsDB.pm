package HTGT::Model::KermitsDB;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

use HTGT::DBFactory;

__PACKAGE__->config(
    schema_class => 'KermitsDB',
    connect_info => HTGT::DBFactory->params_hash( 'kermits', {AutoCommit => 1} ),
);

=head1 NAME

HTGT::Model::KermitsDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<HTGT>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<ConstructQC>

=head1 AUTHOR

Darren Oakley <do2@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
