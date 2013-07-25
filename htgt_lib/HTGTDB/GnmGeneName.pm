package HTGTDB::GnmGeneName;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table('mig.gnm_gene_name');
__PACKAGE__->add_columns(qw/
        id
        gene_id
        name
        source
        name_uc
        check_number
        creator_id
        created_date
        edited_by
        edit_date
    /);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(gene => 'HTGTDB::GnmGene', 'gene_id');


=head1 AUTHOR

Darren Oakley <do2@sanger.ac.uk>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

