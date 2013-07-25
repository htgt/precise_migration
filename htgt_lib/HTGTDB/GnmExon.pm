package HTGTDB::GnmExon;
use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut



use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);


__PACKAGE__->table('mig.gnm_exon');

__PACKAGE__->add_columns(qw/ id locus_id transcript_id primary_name phase /);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(locus => 'HTGTDB::GnmLocus', 'locus_id');

__PACKAGE__->belongs_to(transcript => 'HTGTDB::GnmTranscript', 'transcript_id');
__PACKAGE__->has_many(start_designs => 'HTGTDB::Design', 'start_exon_id');
__PACKAGE__->has_many(end_designs => 'HTGTDB::Design', 'end_exon_id');

return 1;

