package HTGTDB::GnmLocus;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('mig.gnm_locus');
__PACKAGE__->add_columns(qw/
    id 
    chr_name 
    chr_start 
    chr_end 
    chr_strand 
    assembly_id 
    type 
/);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->sequence('mig.GNM_LOCUS_SEQ');

__PACKAGE__->has_many(designs => 'HTGTDB::Design', 'locus_id');

return 1;

