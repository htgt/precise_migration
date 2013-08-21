#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Getopt::Long;
use YAML::Syck;
use Const::Fast;

GetOptions(
    commit => \my $commit
) or die "Usage: $0 [--commit]\n";


my @designs = YAML::Syck::LoadFile( \*STDIN );

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

const my @REQUIRED_OLIGOS      => qw( G5 U5 U3 D5 D3 G3 );
const my $INCOMPLETE_STATUS_ID => $htgt->resultset( 'DesignStatusDict' )->find( { description => 'Incomplete' } )->design_status_id;
const my $READY_STATUS_ID      => $htgt->resultset( 'DesignStatusDict' )->find( { description => 'Ready to order' } )->design_status_id;

$htgt->txn_do(
    sub {

        for my $d ( @designs ) {

            my $design = $htgt->resultset( 'Design' )->find( { design_id => $d->{design_id} } )
                or die "failed to retrieve design $d->{design_id}";    

            my $df = $design->validated_display_features;

            my @missing;
            for ( @REQUIRED_OLIGOS ) {
                push @missing, $_ unless defined $df->{$_};
            }

            if ( @missing ) {
                $d->{status} = "Incomplete; missing oligos: " . join( q{, }, @missing );
                set_status_incomplete( $design )
                    unless $design->statuses_rs->find( { is_current => 1 } )->design_status_id == $INCOMPLETE_STATUS_ID;
            }
            else {
                $d->{status} = $design->statuses_rs->search_rs( { is_current => 1 } )->first->design_status_dict->description;
            }
        }

        YAML::Syck::DumpFile( \*STDOUT, @designs );

        unless ( $commit ) {
            warn "Rollback\n";
            $htgt->txn_rollback;
        }        
    }
);

sub set_status_incomplete {
    my $design = shift;

    warn "Setting status for " . $design->design_id . " to 'Incomplete'\n";
    $htgt->txn_do(
        sub {
            $design->statuses_rs->search_rs( { is_current => 1 } )->update( { is_current => 0 } );
            $design->statuses_rs->create( { design_status_id => $INCOMPLETE_STATUS_ID, is_current => 1 } );
        }
    );
}
