#!/usr/bin/env perl
#
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/htgt/projects/htgt-utils-recovery/trunk/bin/update-recovery-history.pl $
# $LastChangedRevision: 1635 $
# $LastChangedDate: 2010-05-07 14:21:27 +0100 (Fri, 07 May 2010) $
# $LastChangedBy: rm7 $
#
# Populate the gr_gene_status_history table with historical recovery attempts.
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use HTGT::DBFactory;
use Readonly;
use List::MoreUtils 'uniq';

GetOptions(
    commit => \my $commit,
) or die "Usage: $0 [--commit]\n";

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

Readonly my %STATE_FOR => (
    resynthesis_recovery     => 'rdr',
    redesign_recovery        => 'rdr',
    gateway_recovery         => 'gwr',
    alternate_clone_recovery => 'acr',
);

$htgt->txn_do(
    sub {

        my $recovery = $htgt->storage->dbh->selectall_arrayref( <<'EOT' );
select distinct project.mgi_gene_id, plate_data.data_type, plate.name, plate.created_date
from plate
join plate_data on plate_data.plate_id = plate.plate_id
join well on well.plate_id = plate.plate_id
join project on project.design_instance_id = well.design_instance_id
where plate_data.data_type like '%_recovery'
and plate_data.data_value = 'yes'    
EOT
    
        my %gene_recovery;

        for ( @{ $recovery } ) {
            my ( $mgi_gene_id, $recovery_type, $plate_name, $created_date ) = @{ $_ };
            push @{ $gene_recovery{ $mgi_gene_id }{ $recovery_type }{ $created_date } }, $plate_name;
        }

        for my $mgi_gene_id ( keys %gene_recovery ) {
            for my $recovery_type ( keys %{ $gene_recovery{ $mgi_gene_id } } ) {
                for my $date ( keys %{ $gene_recovery{ $mgi_gene_id }{ $recovery_type } } ) {
                    my $plates = join q{, }, @{ $gene_recovery{ $mgi_gene_id }{ $recovery_type }{ $date } };
                    print "Inserting $mgi_gene_id $STATE_FOR{$recovery_type} $date $plates\n";
                    $htgt->resultset( 'GRGeneStatusHistory' )->create(
                        {
                            mgi_gene_id => $mgi_gene_id,
                            state       => $STATE_FOR{ $recovery_type },
                            note        => $plates,
                            updated     => $date,
                        }
                    );            
                }
            }
        }

        unless ( $commit ) {
            warn "Rollback\n";
            $htgt->txn_rollback;
        }
    }
);

        
        
        




    
