package HTGT::Model::ConstructQC;

use strict;
use warnings;
use base 'Catalyst::Model::DBIC::Schema';

use HTGT::DBFactory;

__PACKAGE__->config(
    schema_class => 'ConstructQC',
    connect_info => HTGT::DBFactory->params_hash( 'vector_qc', {AutoCommit => 1} ),
);

=head1 NAME

HTGT::Model::ConstructQC - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<HTGT>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<ConstructQC>

=head1 AUTHOR

David Keith Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
