package ConstructQC;
# $Header: /repos/cvs/gene_trap/src/HTGT/lib/ConstructQC.pm,v 1.1 2007-10-11 16:45:43 dj3 Exp $
# Created by DBIx::Class::Schema::Loader v0.03009 @ 2007-10-10 15:45:51
# And then seriously hacked as no relationships are pulled out of Oracle! 

=head1 NAME

ConstructQC - access and manipulate sequencing QC for Sanger Team87 H.T. Gene Targetting 

=head1 DESCRIPTION

DBIx::Class based access and manipulation of the Sanger team87 gene trapping sequencing QC database (vector_qc@trap)

=cut

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;

=head1 AUTHOR

David K Jackson <david.jackson@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

