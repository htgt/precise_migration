#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use HTGT::DBFactory;
use Perl6::Slurp;
use Const::Fast;

const my @KO_FEATURES  => qw( G5 U5 U3 D5 D3 G3 );
const my @INS_FEATURES => qw( G5 U5 D3 G3 );
const my @DEL_FEATURES => qw( G5 U5 U3 G3 );

const my %REQUIRED_FEATURES_FOR => (
    'KO'           => \@KO_FEATURES,
    'Del_Block'    => \@DEL_FEATURES,
    'Del_Location' => \@DEL_FEATURES,
    'Ins_Block'    => \@INS_FEATURES,
    'Ins_Location' => \@INS_FEATURES
);

my $htgt = HTGT::DBFactory->connect( 'eucomm_vector' );

my @todo = @ARGV ? @ARGV : slurp \*STDIN, { chomp => 1 };

for ( @todo ) {
    my $design;

    if ( /^\d+$/ ) {
        $design = $htgt->resultset( 'Design' )->find( { design_id => $_ } )
            or die "failed to retrieve design $_\n";
    }
    elsif ( my ( $plate_name, $well_name ) = $_ =~ m/^(\w+)\[(\w+)\]$/ ) {
        my $well = $htgt->resultset( 'Well' )->find(
            {
                'me.well_name' => $well_name,
                'plate.name'   => $plate_name
            },
            {
                join => 'plate'
            }
        ) or die "failed to retrieve well $_\n";
        my $di = $well->design_instance
            or die "well $_ has no design instance\n";
        $design = $di->design;        
    }

    check_features( $design );
}

sub check_features {
    my $design = shift;

    my $type = $design->design_type || 'KO';
    my $required_features = $REQUIRED_FEATURES_FOR{ $type }
        or die "invalid design type $type\n";    
    
    my $features = $design->validated_display_features;

    for my $feature_name ( @$required_features ) {
        my $feature = $features->{ $feature_name };
        unless ( $feature ) {
            warn $design->design_id . " missing feature $feature_name\n";
            return;
        }
        unless ( $feature->feature_start < $feature->feature_end ) {
            warn $design->design_id . " $feature_name feature_start >= feature_end\n";
            return;        
        }
    }
    
    my @order = $features->{G5}->feature_strand == 1 ? @{$required_features}
              :                                        reverse @{$required_features};

    while ( my $this = shift @order ) {
        my $next = $order[0] or last;
        unless ( $features->{$this}->feature_end <= $features->{$next}->feature_start ) {
            warn $design->design_id . " $this end > $next start\n";
            return;
        }
    }

    return 1;
}
