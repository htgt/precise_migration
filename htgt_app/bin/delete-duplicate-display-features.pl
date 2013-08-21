#!/usr/bin/env perl
#
# $HeadURL$
# $LastChangedRevision$
# $LastChangedDate$
# $LastChangedBy$
#

use strict;
use warnings FATAL => 'all';

use Getopt::Long;
use Pod::Usage;
use HTGT::DBFactory::Lazy;
use Perl6::Slurp;
use Log::Log4perl qw( :easy );
use Const::Fast;

const my $NCBIM37_ASSEMBLY_ID => get_assembly_id( 'NCBIM37' );

{    
    my $log_level = $WARN;

    GetOptions(
        'help'       => sub { pod2usage( -verbose => 1 ) },
        'man'        => sub { pod2usage( -verbose => 2 ) },
        'debug'      => sub { $log_level = $DEBUG },
        'verbose'    => sub { $log_level = $INFO },
        'commit'     => \my $commit
    ) or pod2usage(2);

    Log::Log4perl->easy_init( {
        level  => $log_level,
        layout => '%p %x %m%n'
    } );    

    my @design_ids = @ARGV ? @ARGV : slurp \*STDIN, { chomp => 1 };

    htgt->txn_do(
        sub {
            for my $design_id ( @design_ids ) {
                Log::Log4perl::NDC->remove;
                Log::Log4perl::NDC->push( $design_id );                
                delete_duplicate_display_features( $design_id );
            }
            unless ( $commit ) {
                warn "Rollback\n";
                htgt->txn_rollback;
            }
        }
    );
}

sub delete_duplicate_display_features {
    my $design_id = shift;

    DEBUG( "Checking features for design $design_id" );
    my $design = htgt->resultset('Design')->find( { design_id=> $design_id } )
        or die "Failed to retrieve design $design_id";

    return unless defined $design->locus and defined $design->locus->assembly_id and
        $design->locus->assembly_id == $NCBIM37_ASSEMBLY_ID;
    my $validated_features = $design->features_rs->search(
        {
            'feature_data_type.description' => 'validated'
        },
        {
            join => { feature_data => 'feature_data_type' }
        }
    );

    while ( my $f = $validated_features->next ) {
        my @df_all_assemblies = $f->display_features;
        my @df = @{ get_display_features_on_current_assembly( \@df_all_assemblies, $f ) };
        if ( @df > 1 ) {
            WARN 'Feature ' . $f->feature_type->description . ' has ' . @df . ' display features';
            my $valid_ref = find_matching_or_out_by_one( \@df, $f->feature_start );
            delete_duplicate_dfs( $f, \@df, $valid_ref );
        }
    }
}

sub delete_duplicate_dfs{
    my ( $feature, $df_ref, $valid_ref ) = @_;

    if ( @$valid_ref == 1 ) {
        WARN 'Found one display_feature with matching start coordinate - deleting others';
        for my $df( @$df_ref ) {
            next if $df->feature_start == $feature->feature_start
                or $df->feature_start == $feature->feature_start + 1
                    or $df->feature_start == $feature->feature_start - 1;
            WARN 'Deleting display_feature ' . $df->display_feature_id;
            $df->delete;
        }
    }
    else {
        my $selected_df_id  = select_df_id_if_all_identical( $valid_ref );
        if ( defined $selected_df_id ){
            for my $df( @$df_ref ){
                next if $df->display_feature_id == $selected_df_id;
                WARN 'Deleting display_feature ' . $df->display_feature_id;
                $df->delete;
            }
        }
        else{
            ERROR 'Design has ' .@$valid_ref . ' display features with matching start coordinate';
        }
    }
}

sub select_df_id_if_all_identical{
    my ( $valid_ref ) = @_;

    my %identity_check;
    my $selected_df_id;
    for my $valid_df( @$valid_ref ){
        $identity_check{ $valid_df->feature_start . '-' . $valid_df->feature_end }++;
        $selected_df_id = $valid_df->display_feature_id;
    }

    return $selected_df_id if scalar keys %identity_check == 1;

    return;
}

sub find_matching_or_out_by_one{
    my ( $df_ref, $validated_feature_start ) = @_;

    my @matching;
    for my $df( @$df_ref ){
        push @matching, $df if $df->feature_start == $validated_feature_start
            or $df->feature_start == $validated_feature_start + 1
                or $df->feature_start == $validated_feature_start - 1;
    }

    return \@matching;
}

sub get_display_features_on_current_assembly{
    my ( $df_ref ) = @_;

    my @current_df;
    for my $df( @$df_ref ){
        my $df_ass_id = $df->assembly_id;
        next unless defined $df_ass_id;
        push @current_df, $df if $df->assembly_id == $NCBIM37_ASSEMBLY_ID;
    }

    return \@current_df;
}

sub get_assembly_id{
    my ( $assembly_name ) = @_;

    my $dbh = HTGT::DBFactory->dbi_connect( 'eucomm_vector' );

    my ( $assembly_id ) = $dbh->selectrow_array( "SELECT id from mig.gnm_assembly WHERE name = '$assembly_name'" );

    return $assembly_id;

}

__END__
