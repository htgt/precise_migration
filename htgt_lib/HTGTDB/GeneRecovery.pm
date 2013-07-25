package HTGTDB::GeneRecovery;

use strict;
use warnings;

=head1 AUTHOR

Vivek Iyer

=cut

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/PK::Auto Core/);

__PACKAGE__->table('gene_recovery');

__PACKAGE__->sequence('S_GENE_RECOVERY');

__PACKAGE__->add_columns(
   qw/
    gene_recovery_id
    mgi_gene_id
    acr_attempts                          
    acr_plates                              
    gwr_attempts                            
    gwr_plates                              
    rdr_attempts                            
    rdr_plates                              
    acr_date                                
    gwr_date                                
    rdr_date                                
    edit_date                               
    edit_user                               
    gene_recovery_id
    acr_candidate_evidence
    gwr_candidate_evidence                  
    rdr_candidate_evidence                  
   /
);

__PACKAGE__->set_primary_key('gene_recovery_id');
__PACKAGE__->belongs_to(mgi_gene=>'HTGTDB::MGIGene',"mgi_gene_id");
__PACKAGE__->add_unique_constraint( mgi_gene_id => [qw/mgi_gene_id/] );

1;
